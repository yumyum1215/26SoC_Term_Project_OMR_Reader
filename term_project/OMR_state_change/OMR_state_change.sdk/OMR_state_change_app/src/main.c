#include "omr_grading.h"
#include "omr_storage.h"
#include "xgpio_l.h"
#include "xil_exception.h"
#include "xil_io.h"
#include "xiicps.h"
#include "xparameters.h"
#include "xscugic.h"
#include "xtime_l.h"
#include "xuartps.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUTTONS XPAR_AXI_GPIO_0_BASEADDR
#define VIDEO XPAR_AXI_VIDEO_GPIO_BASEADDR
#define SERVO XPAR_AXI_SERVO_GPIO_BASEADDR
#define FND XPAR_AXI_PANEL_GPIO_BASEADDR
#define LCD XPAR_TEXTLCD_0_S00_AXI_BASEADDR

#define CMD_HOLD (1U << 31)
#define CMD_READ (1U << 30)
#define CMD_REQUIRE_ALIGNED (1U << 29)
#define VIDEO_VIEW_SHIFT 24U
#define STAT_CAMERA_NACK (1U << 20)
#define STAT_ALIGNED (1U << 19)
#define STAT_READ (1U << 18)
#define STAT_CAMERA (1U << 17)
#define STAT_HELD (1U << 16)
#define BUTTON_IRQ 1U
#define BUTTON_FRONT (1U << 0)
#define BUTTON_BACK (1U << 1)
#define BUTTON_SUMMARY (1U << 2)
#define BUTTON_CLEAR_CANCEL (1U << 3)
#define FRONT_PULSE_US 1400U
#define BACK_PULSE_US 1600U
#define SETTLE_MS 800U

typedef enum { FRONT_IDLE, BACK_ALIGN, RESULT, SUMMARY, CLEARED, ERROR } State;

static uint16_t front[OMR_WIDTH * OMR_HEIGHT], back[OMR_WIDTH * OMR_HEIGHT];
static int answers[12];
static OmrExam exam;
static OmrLayout subject_layout;
static unsigned active_subject;
static const char *const subject_names[OMR_LAST_SUBJECT] = {
    "KOREAN", "MATH", "ENGLISH", "KOREAN HISTORY",
    "INTEGRATED SCIENCE", "INTEGRATED SOCIAL STUDIES"
};
static OmrRound round_info;
static XScuGic gic;
static XIicPs rtc;
static XUartPs uart;
static u32 video_command;
static volatile u32 pending_buttons, previous_buttons;
static unsigned expected_count;
static char student_id[9], student_name[33];
static int sd_ready, rtc_ready;

static void serial(const char *text)
{
    while (*text)
        XUartPs_SendByte(uart.Config.BaseAddress, *text++);
}

static XTime after_ms(unsigned ms)
{
    XTime t;
    XTime_GetTime(&t);
    return t + (XTime)ms * COUNTS_PER_SECOND / 1000;
}

static int passed(XTime deadline)
{
    XTime t;
    XTime_GetTime(&t);
    return t >= deadline;
}

static void lcd_line(unsigned row, const char *message)
{
    for (unsigned word = 0; word < 4; ++word) {
        u32 packed = 0;
        for (unsigned byte = 0; byte < 4; ++byte) {
            const unsigned char c = *message ? (unsigned char)*message++ : ' ';
            packed |= (u32)c << (24U - 8U * byte);
        }
        Xil_Out32(LCD + 16U * row + 4U * word, packed);
    }
}

static void screen(const char *line1, const char *line2)
{
    lcd_line(0, line1);
    lcd_line(1, line2);
}

static u32 bcd4(unsigned value)
{
    u32 bcd = 0;
    for (unsigned i = 0; i < 4; ++i) {
        bcd |= (u32)(value % 10U) << (i * 4U);
        value /= 10U;
    }
    return bcd;
}

static void summary_digits(void)
{
    Xil_Out32(FND, (bcd4(expected_count) << 16) | bcd4(round_info.graded));
}

static void video_write(u32 command)
{
    video_command = command;
    Xil_Out32(VIDEO, command);
}

static void tft_view(unsigned view)
{
    video_write((video_command & CMD_READ) | ((u32)view << VIDEO_VIEW_SHIFT));
}

static u32 video_status(void)
{
    return Xil_In32(VIDEO + 8U);
}

static int wait_video(u32 mask, u32 want, unsigned timeout_ms)
{
    const XTime deadline = after_ms(timeout_ms);
    do {
        if ((video_status() & mask) == want)
            return 1;
    } while (!passed(deadline));
    return 0;
}

static int capture_aligned(uint16_t *destination)
{
    if ((video_status() & (STAT_CAMERA | STAT_ALIGNED)) !=
        (STAT_CAMERA | STAT_ALIGNED))
        return 0;

    /* The camera domain checks alignment again on the frame it freezes. */
    video_write((video_command & CMD_READ) | CMD_REQUIRE_ALIGNED);
    video_write(video_command | CMD_HOLD);
    int ok = wait_video(STAT_HELD, STAT_HELD, 450);
    for (u32 address = 0; ok && address < OMR_WIDTH * OMR_HEIGHT; ++address) {
        const u32 toggle = (video_command ^ CMD_READ) & CMD_READ;
        video_write(CMD_HOLD | CMD_REQUIRE_ALIGNED | toggle | address);
        ok = wait_video(STAT_READ, toggle ? STAT_READ : 0U, 5);
        if (ok)
            destination[address] = (uint16_t)video_status();
    }
    video_write(video_command & CMD_READ);
    return wait_video(STAT_HELD, 0, 450) && ok;
}

static void gpio_interrupt(void *unused)
{
    (void)unused;
    const u32 asserted = Xil_In32(BUTTONS + XGPIO_ISR_OFFSET) & BUTTON_IRQ;
    if (asserted) {
        Xil_Out32(BUTTONS + XGPIO_ISR_OFFSET, asserted);
        const u32 now = Xil_In32(BUTTONS) & 15U;
        pending_buttons |= previous_buttons & ~now;
        previous_buttons = now;
    }
}

static int init_interrupt(void)
{
    XScuGic_Config *config = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
    if (!config || XScuGic_CfgInitialize(&gic, config, config->CpuBaseAddress) != XST_SUCCESS)
        return 0;
    const u32 irq = XPAR_FABRIC_AXI_GPIO_0_IP2INTC_IRPT_INTR;
    if (XScuGic_Connect(&gic, irq, gpio_interrupt, NULL) != XST_SUCCESS)
        return 0;
    previous_buttons = Xil_In32(BUTTONS) & 15U;
    gpio_interrupt(NULL);
    pending_buttons = 0;
    XScuGic_SetPriorityTriggerType(&gic, irq, 0xa0, 1);
    XScuGic_Enable(&gic, irq);
    Xil_Out32(BUTTONS + XGPIO_IER_OFFSET, BUTTON_IRQ);
    Xil_Out32(BUTTONS + XGPIO_GIE_OFFSET, XGPIO_GIE_GINTR_ENABLE_MASK);
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                 (Xil_ExceptionHandler)XScuGic_InterruptHandler, &gic);
    Xil_ExceptionEnable();
    return 1;
}

static u32 take_buttons(void)
{
    Xil_ExceptionDisable();
    const u32 events = pending_buttons;
    pending_buttons = 0;
    Xil_ExceptionEnable();
    return events;
}

static void rtc_timestamp(char timestamp[32])
{
    u8 address = 2, data[7];
    strcpy(timestamp, "UNAVAILABLE");
    if (!rtc_ready ||
        XIicPs_MasterSendPolled(&rtc, &address, 1, 0x51) != XST_SUCCESS ||
        XIicPs_MasterRecvPolled(&rtc, data, 7, 0x51) != XST_SUCCESS ||
        (data[0] & 0x80))
        return;

    /* RTC-8564JE registers use packed BCD. */
    snprintf(timestamp, 32, "%s%02X-%02X-%02X %02X:%02X:%02X",
             data[5] & 0x80 ? "19" : "20", data[6], data[5] & 0x1f, data[3] & 0x3f,
             data[2] & 0x3f, data[1] & 0x7f, data[0] & 0x7f);
}

static void uart_input(int allow_student_change)
{
    static char line[64];
    static unsigned length;
    static int overflow;
    const u32 base = uart.Config.BaseAddress;

    while (XUartPs_IsReceiveData(base)) {
        const unsigned char c = (unsigned char)XUartPs_RecvByte(base);
        if (c == '\r' || c == '\n') {
            if (!length && !overflow)
                continue;
            line[length] = 0;
            char *end;
            if (!overflow && strncmp(line, "TOTAL ", 6) == 0) {
                const unsigned long value = strtoul(line + 6, &end, 10);
                if (!*end && value > 0 && value <= 9999) {
                    expected_count = (unsigned)value;
                    summary_digits();
                    serial("Total saved.\r\n");
                } else
                    serial("Use TOTAL 1..9999.\r\n");
            } else if (!overflow && allow_student_change && strncmp(line, "ID ", 3) == 0) {
                const char *digits = line + 3;
                const char *name = digits;
                while (isdigit((unsigned char)*name))
                    ++name;
                const size_t id_length = (size_t)(name - digits);
                if (id_length >= 1 && id_length <= 8 && *name == ' ' &&
                    name[1] && strlen(name + 1) < sizeof student_name) {
                    memcpy(student_id, digits, id_length);
                    student_id[id_length] = '\0';
                    strcpy(student_name, name + 1);
                    serial("Student selected.\r\n");
                } else
                    serial("Use ID <1-8 digits> <name>.\r\n");
            } else
                serial("Use TOTAL <count> or ID <digits> <name> while idle.\r\n");
            length = 0;
            overflow = 0;
        } else if (c == 8 || c == 127) {
            if (length && !overflow)
                --length;
        } else if (c >= 32 && c <= 126) {
            if (length + 1 < sizeof line)
                line[length++] = (char)c;
            else
                overflow = 1;
        }
    }
}

static int save_score(unsigned *score)
{
    char stamp[32];
    *score = 0;
    int review = 0;
    for (unsigned i = 0; i < 12; ++i) {
        if (answers[i] == OMR_REVIEW)
            review = 1;
        if (answers[i] == exam.key[i])
            *score += exam.points[i];
    }
    rtc_timestamp(stamp);
    if (!omr_storage_save(&round_info, student_id, student_name, stamp,
                          active_subject, *score, review, answers, front, back))
        return 0;
    return review ? -1 : 1;
}

int main(void)
{
    XUartPs_Config *uart_config = XUartPs_LookupConfig(XPAR_PS7_UART_1_DEVICE_ID);
    XIicPs_Config *rtc_config = XIicPs_LookupConfig(XPAR_PS7_I2C_0_DEVICE_ID);
    if (!uart_config || XUartPs_CfgInitialize(&uart, uart_config, uart_config->BaseAddress) != XST_SUCCESS ||
        XUartPs_SetBaudRate(&uart, 115200) != XST_SUCCESS)
        return 1;
    if (rtc_config && XIicPs_CfgInitialize(&rtc, rtc_config, rtc_config->BaseAddress) == XST_SUCCESS)
        rtc_ready = XIicPs_SetSClk(&rtc, 100000) == XST_SUCCESS;

    screen("OMR STARTUP", "INIT SD/CAMERA");
    sd_ready = omr_storage_open(&subject_layout, &round_info);
    Xil_Out32(SERVO, FRONT_PULSE_US);
    video_write(0);
    summary_digits();
    if (!init_interrupt()) {
        screen("IRQ INIT ERROR", "CHECK HARDWARE");
        return 1;
    }
    serial("OMR: TOTAL <count>, ID <student number> <name>\r\n");

    State state = FRONT_IDLE;
    XTime until = after_ms(SETTLE_MS);
    int old_ready = -1;
    int old_camera_failed = -1;
    for (;;) {
        uart_input(state == FRONT_IDLE);
        const u32 events = take_buttons();
        const u32 status = video_status();
        const int camera_failed = (status & (STAT_CAMERA_NACK | STAT_CAMERA)) == STAT_CAMERA_NACK;
        const int aligned = (status & (STAT_CAMERA | STAT_ALIGNED)) ==
                             (STAT_CAMERA | STAT_ALIGNED);

        if (state == FRONT_IDLE || state == BACK_ALIGN) {
            const int ready = aligned && passed(until);
            const u32 capture_button = state == FRONT_IDLE ? BUTTON_FRONT : BUTTON_BACK;
            if (ready != old_ready || camera_failed != old_camera_failed) {
                if (camera_failed)
                    screen("CAMERA NO FRAME", "CHECK CAMERA1");
                else if (state == BACK_ALIGN)
                    screen("BACK SIDE", ready ? "READY - PRESS 2" : "ALIGN IN BOX");
                else if (!sd_ready)
                    screen("SD / KEY ERROR", "CHECK KEY.TXT");
                else if (!student_id[0])
                    screen("FRONT SIDE", "ENTER ID VIA UART");
                else
                    screen("FRONT SIDE", ready ? "READY - PRESS 1" : "ALIGN IN BOX");
                old_ready = ready;
                old_camera_failed = camera_failed;
            }

            if (state == FRONT_IDLE && (events & BUTTON_SUMMARY)) {
                char count[17];
                snprintf(count, sizeof count, "COUNT %u", round_info.graded);
                screen("ROUND SUMMARY", count);
                summary_digits();
                tft_view(2);
                snprintf(count, sizeof count, "POINTS %u", round_info.total_points);
                serial(count);
                serial("\r\n");
                state = SUMMARY;
                until = after_ms(2500);
            } else if (state == FRONT_IDLE && (events & BUTTON_CLEAR_CANCEL)) {
                if (sd_ready && omr_storage_clear(&round_info)) {
                    screen("NEW ROUND", "SUMMARY CLEARED");
                    summary_digits();
                    tft_view(3);
                    state = CLEARED;
                } else {
                    screen("CLEAR FAILED", "CHECK SD CARD");
                    state = ERROR;
                }
                until = after_ms(2200);
            } else if (state == BACK_ALIGN && (events & BUTTON_CLEAR_CANCEL)) {
                screen("CANCELLED", "RETURNING FRONT");
                state = ERROR;
                until = after_ms(1500);
            } else if ((events & capture_button) && ready && sd_ready && student_id[0]) {
                if (state == FRONT_IDLE && omr_storage_duplicate(&round_info, student_id)) {
                    screen("ALREADY GRADED", "SELECT OTHER ID");
                    state = ERROR;
                    until = after_ms(2200);
                } else if (state == FRONT_IDLE && capture_aligned(front)) {
                    const int subject = omr_subject(front, &subject_layout);
                    char key_name[17];
                    if (subject < OMR_FIRST_SUBJECT || subject > OMR_LAST_SUBJECT) {
                        screen("SUBJECT CODE ERR", "USE CODES 01-06");
                    } else if (!omr_storage_load_subject((unsigned)subject, &exam)) {
                        snprintf(key_name, sizeof key_name, "KEY%02u.TXT", (unsigned)subject);
                        screen("CHECK ANSWER KEY", key_name);
                    } else if (!omr_front(front, &exam.layout, answers)) {
                        screen("FRONT MARK ERROR", "REALIGN AND TRY");
                    } else {
                        active_subject = (unsigned)subject;
                        snprintf(key_name, sizeof key_name, "SUBJECT %02u", active_subject);
                        serial(key_name);
                        serial(" ");
                        serial(subject_names[active_subject - OMR_FIRST_SUBJECT]);
                        serial("\r\n");
                        Xil_Out32(SERVO, BACK_PULSE_US);
                        state = BACK_ALIGN;
                        until = after_ms(SETTLE_MS);
                        old_ready = -1;
                    }
                    if (state == FRONT_IDLE) {
                        state = ERROR;
                        until = after_ms(2200);
                    }
                } else if (state == BACK_ALIGN && capture_aligned(back)) {
                    unsigned score;
                    omr_back(back, exam.back_boxes, answers + 10);
                    const int saved = save_score(&score);
                    if (saved == 1) {
                        char score_line[17];
                        snprintf(score_line, sizeof score_line, "SCORE %u", score);
                        screen("RESULT SAVED", score_line);
                        Xil_Out32(FND, bcd4(score));
                        tft_view(1);
                        student_id[0] = 0;
                        state = RESULT;
                    } else {
                        screen(saved < 0 ? "REVIEW ANSWERS" : "SAVE FAILED",
                               saved < 0 ? "CHECK MARKS" : "CHECK SD CARD");
                        state = ERROR;
                    }
                    until = after_ms(2600);
                }
                (void)take_buttons();
            }
        } else if (passed(until)) {
            tft_view(0);
            Xil_Out32(SERVO, FRONT_PULSE_US);
            until = after_ms(SETTLE_MS);
            state = FRONT_IDLE;
            old_ready = -1;
            summary_digits();
        }
        if (state == ERROR && (video_command >> VIDEO_VIEW_SHIFT) != 4U)
            tft_view(4);
        /* Refresh the ID prompt after a UART command even if alignment is stable. */
        if (state == FRONT_IDLE) {
            static int previous_id_set;
            if (!!student_id[0] != previous_id_set) {
                previous_id_set = !!student_id[0];
                old_ready = -1;
            }
        }
    }
}


