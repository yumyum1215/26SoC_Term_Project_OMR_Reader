#include "omr_storage.h"
#include "ff.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static FATFS sd;

#define DATA_DIR "0:/DATA"

static int student_record(const char *id)
{
    return strlen(id) == 8 && (id[0] == 'G' || id[0] == 'B' || id[0] == 'T') &&
           id[1] >= '1' && id[1] <= '3' && id[2] == 'C' && id[5] == 'N' &&
           isdigit((unsigned char)id[3]) && isdigit((unsigned char)id[4]) &&
           isdigit((unsigned char)id[6]) && isdigit((unsigned char)id[7]);
}

static void record_path(char path[48], const char *id, const char *file)
{
    if (file)
        snprintf(path, 48, DATA_DIR "/%s/%s", id, file);
    else
        snprintf(path, 48, DATA_DIR "/%s", id);
}

static int is_missing(FRESULT status)
{
    return status == FR_NO_FILE || status == FR_NO_PATH;
}

/* Remove only files owned by the application. */
static int remove_record(const char *id)
{
    static const char *const files[] = {"FRONT.BMP", "BACK.BMP", "RESULT.TXT", "REVIEW.TXT"};
    char path[48];
    for (unsigned i = 0; i < sizeof files / sizeof files[0]; ++i) {
        record_path(path, id, files[i]);
        const FRESULT status = f_unlink(path);
        if (status != FR_OK && !is_missing(status))
            return 0;
    }
    record_path(path, id, NULL);
    const FRESULT status = f_unlink(path);
    return status == FR_OK || is_missing(status);
}

static int recover_record(const char *backup_id)
{
    char id[9], live[48], backup[48];
    FILINFO info;
    strcpy(id, backup_id);
    id[0] = 'G';
    record_path(live, id, NULL);
    record_path(backup, backup_id, NULL);
    const FRESULT status = f_stat(live, &info);
    if (is_missing(status))
        return f_rename(backup, live) == FR_OK;
    return status == FR_OK && (info.fattrib & AM_DIR) && remove_record(backup_id);
}
static int read_text(const char *path, char *text, UINT capacity)
{
    FIL file;
    UINT size = 0;
    if (f_open(&file, path, FA_READ) != FR_OK)
        return 0;
    const FRESULT read_status = f_read(&file, text, capacity - 1U, &size);
    const FRESULT close_status = f_close(&file);
    text[size] = 0;
    return read_status == FR_OK && close_status == FR_OK && size < capacity - 1U;
}

static int layout_valid(long first, long step)
{
    return first >= 2500 && first <= 5500 && step >= 800 && step <= 1700;
}

static int parse_layout(char *text, OmrLayout *layout)
{
    char *end;
    const long first = strtol(text, &end, 10);
    if (end == text)
        return 0;
    char *second = end;
    const long step = strtol(second, &end, 10);
    if (end == second || !layout_valid(first, step))
        return 0;
    *layout = (OmrLayout){(int)first, (int)step};
    return 1;
}
static int parse_exam(char *text, OmrExam *exam)
{
    char *cursor = text;
    char *end;
    int values[34];
    for (unsigned i = 0; i < 34; ++i) {
        const long value = strtol(cursor, &end, 10);
        if (end == cursor || value < 0 || value > 9999)
            return 0;
        values[i] = (int)value;
        cursor = end;
    }
    while (isspace((unsigned char)*cursor))
        ++cursor;
    if (*cursor)
        return 0;
    exam->layout = (OmrLayout){values[0], values[1]};
    if (!layout_valid(values[0], values[1]))
        return 0;
    for (unsigned i = 0; i < 2; ++i) {
        const unsigned offset = 2 + i * 4;
        const OmrBox box = {values[offset], values[offset + 1],
                            values[offset + 2], values[offset + 3]};
        if (box.left < 24 || box.right > 456 || box.top < 16 || box.bottom > 256 ||
            box.right - box.left < 16 || box.bottom - box.top < 16)
            return 0;
        exam->back_boxes[i] = box;
    }

    unsigned max_score = 0;
    for (unsigned i = 0; i < 12; ++i) {
        exam->key[i] = values[i + 10];
        exam->points[i] = (unsigned)values[i + 22];
        max_score += exam->points[i];
        if (exam->key[i] < 1 || exam->key[i] > (i < 10 ? 5 : 999))
            return 0;
    }
    return max_score <= 9999U;
}

int omr_storage_clear(void)
{
    DIR dir;
    FILINFO item;
    if (f_opendir(&dir, DATA_DIR) != FR_OK)
        return 0;

    FRESULT scan;
    int ok = 1;
    while ((scan = f_readdir(&dir, &item)) == FR_OK && item.fname[0]) {
        if ((item.fattrib & AM_DIR) && student_record(item.fname) && !remove_record(item.fname))
            ok = 0;
    }
    return f_closedir(&dir) == FR_OK && scan == FR_OK && ok;
}

int omr_storage_summary(OmrSummary *summary)
{
    DIR dir;
    FILINFO item;
    FRESULT scan;
    int ok = 1;
    char path[48], record[400];
    OmrSummary result = {0, 0};
    if (f_opendir(&dir, DATA_DIR) != FR_OK)
        return 0;

    /* Restore the previous complete record if an overwrite was interrupted. */
    while ((scan = f_readdir(&dir, &item)) == FR_OK && item.fname[0]) {
        if ((item.fattrib & AM_DIR) && student_record(item.fname) &&
            item.fname[0] == 'B' && !recover_record(item.fname))
            ok = 0;
    }
    if (f_closedir(&dir) != FR_OK || scan != FR_OK || !ok ||
        f_opendir(&dir, DATA_DIR) != FR_OK)
        return 0;

    while ((scan = f_readdir(&dir, &item)) == FR_OK && item.fname[0]) {
        if (!(item.fattrib & AM_DIR) || !student_record(item.fname) || item.fname[0] != 'G')
            continue;
        record_path(path, item.fname, "RESULT.TXT");
        FILINFO file_info;
        const FRESULT status = f_stat(path, &file_info);
        if (is_missing(status))
            continue; /* A review-only submission does not enter the total. */
        if (status != FR_OK || !read_text(path, record, sizeof record)) {
            ok = 0;
            continue;
        }
        char *end;
        const unsigned long score = strtoul(record, &end, 10);
        if (score > 9999U || end == record || (*end != '\r' && *end != '\n')) {
            ok = 0;
            continue;
        }
        ++result.graded;
        result.total_points += (unsigned)score;
    }
    if (f_closedir(&dir) != FR_OK || scan != FR_OK || !ok)
        return 0;

    *summary = result;
    return 1;
}

int omr_storage_open(OmrLayout *subject_layout, OmrSummary *summary)
{
    char settings[320];
    if (f_mount(&sd, "0:", 1) != FR_OK ||
        !read_text("0:/KEY.TXT", settings, sizeof settings) ||
        !parse_layout(settings, subject_layout))
        return 0;

    const FRESULT status = f_mkdir(DATA_DIR);
    return (status == FR_OK || status == FR_EXIST) && omr_storage_summary(summary);
}
int omr_storage_load_subject(unsigned subject, OmrExam *exam)
{
    char path[16], settings[320];
    OmrExam loaded;
    if (subject < OMR_FIRST_SUBJECT || subject > OMR_LAST_SUBJECT)
        return 0;
    snprintf(path, sizeof path, "0:/KEY%02u.TXT", subject);
    if (!read_text(path, settings, sizeof settings) || !parse_exam(settings, &loaded))
        return 0;
    *exam = loaded;
    return 1;
}
static int write_bytes(FIL *file, const void *data, UINT length)
{
    UINT written = 0;
    return f_write(file, data, length, &written) == FR_OK && written == length;
}

static void little32(unsigned char *header, unsigned offset, uint32_t value)
{
    for (unsigned i = 0; i < 4; ++i)
        header[offset + i] = (unsigned char)(value >> (i * 8));
}

static int save_bmp(const char *path, const uint16_t *frame)
{
    FIL file;
    unsigned char header[66] = {'B', 'M'};
    little32(header, 2, sizeof header + OMR_WIDTH * OMR_HEIGHT * 2);
    little32(header, 10, sizeof header);
    little32(header, 14, 40);
    little32(header, 18, OMR_WIDTH);
    little32(header, 22, OMR_HEIGHT);
    header[26] = 1;
    header[28] = 16;
    header[30] = 3;
    little32(header, 34, OMR_WIDTH * OMR_HEIGHT * 2);
    little32(header, 54, 0xf800);
    little32(header, 58, 0x07e0);
    little32(header, 62, 0x001f);

    if (f_open(&file, path, FA_CREATE_ALWAYS | FA_WRITE) != FR_OK)
        return 0;
    int ok = write_bytes(&file, header, sizeof header);
    for (int y = OMR_HEIGHT - 1; y >= 0 && ok; --y)
        ok = write_bytes(&file, frame + y * OMR_WIDTH, OMR_WIDTH * 2);
    return f_close(&file) == FR_OK && ok;
}

int omr_storage_save(const char *id, const char *name,
                     const char *timestamp, const OmrIdentity *identity,
                     unsigned subject, unsigned score, int review,
                     const int answers[12], const uint16_t *front,
                     const uint16_t *back)
{
    char path[48], live[48], staging[48], backup[48], record[370];
    char stage_id[9], backup_id[9];
    FIL file;
    FILINFO info;
    if (!student_record(id) || id[0] != 'G')
        return 0;
    strcpy(stage_id, id);
    strcpy(backup_id, id);
    stage_id[0] = 'T';
    backup_id[0] = 'B';
    record_path(live, id, NULL);
    record_path(staging, stage_id, NULL);
    record_path(backup, backup_id, NULL);

    const FRESULT backup_status = f_stat(backup, &info);
    if (!is_missing(backup_status) &&
        (backup_status != FR_OK || !(info.fattrib & AM_DIR) || !recover_record(backup_id)))
        return 0;
    if (!remove_record(stage_id) || f_mkdir(staging) != FR_OK)
        return 0;

    record_path(path, stage_id, "FRONT.BMP");
    if (!save_bmp(path, front))
        return 0;
    record_path(path, stage_id, "BACK.BMP");
    if (!save_bmp(path, back))
        return 0;

    const int size = snprintf(record, sizeof record,
        "%u\r\nID=%s\r\nNAME=%s\r\nGRADE=%u\r\nCLASS=%02u\r\nNUMBER=%02u\r\nSUBJECT=%02u\r\nRTC=%s\r\n"
        "STATUS=%s\r\nANSWER=%d %d %d %d %d %d %d %d %d %d / %d %d\r\n",
        score, id, name, identity->grade, identity->class_number, identity->student_number,
        subject, timestamp, review ? "REVIEW" : "GRADED", answers[0], answers[1], answers[2], answers[3],
        answers[4], answers[5], answers[6], answers[7], answers[8], answers[9], answers[10], answers[11]);
    record_path(path, stage_id, review ? "REVIEW.TXT" : "RESULT.TXT");
    if (size < 0 || size >= (int)sizeof record ||
        f_open(&file, path, FA_CREATE_NEW | FA_WRITE) != FR_OK)
        return 0;
    const int wrote = write_bytes(&file, record, (UINT)size);
    const FRESULT closed = f_close(&file);
    if (!wrote || closed != FR_OK)
        return 0;

    const FRESULT live_status = f_stat(live, &info);
    const int replacing = live_status == FR_OK;
    if ((!replacing && !is_missing(live_status)) ||
        (replacing && (!(info.fattrib & AM_DIR) || f_rename(live, backup) != FR_OK)))
        return 0;
    if (f_rename(staging, live) != FR_OK) {
        if (replacing)
            (void)f_rename(backup, live);
        return 0;
    }
    if (replacing)
        (void)remove_record(backup_id);
    return 1;
}
