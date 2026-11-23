#include "omr_storage.h"
#include "ff.h"
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static FATFS sd;

static void round_path(char path[16], unsigned round)
{
    snprintf(path, 16, "0:/R%07u", round);
}

static void result_path(char path[48], unsigned round, const char *id, const char *file)
{
    snprintf(path, 48, "0:/R%07u/%s/%s", round, id, file);
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

int omr_storage_clear(OmrRound *round)
{
    char path[16];
    if (round->round >= 9999999U)
        return 0;
    const unsigned next = round->round + 1;
    round_path(path, next);
    if (f_mkdir(path) != FR_OK)
        return 0;
    *round = (OmrRound){next, 0, 0};
    return 1;
}

int omr_storage_open(OmrLayout *subject_layout, OmrRound *round)
{
    DIR dir;
    FILINFO item;
    char settings[320], path[48], record[400];
    *round = (OmrRound){0, 0, 0};
    if (f_mount(&sd, "0:", 1) != FR_OK ||
        !read_text("0:/KEY.TXT", settings, sizeof settings) ||
        !parse_layout(settings, subject_layout) ||
        f_opendir(&dir, "0:/") != FR_OK)
        return 0;

    FRESULT scan;
    while ((scan = f_readdir(&dir, &item)) == FR_OK && item.fname[0]) {
        if (!(item.fattrib & AM_DIR) || item.fname[0] != 'R' || strlen(item.fname) != 8)
            continue;
        char *end;
        const unsigned number = (unsigned)strtoul(item.fname + 1, &end, 10);
        if (*end == '\0' && number > round->round)
            round->round = number;
    }
    f_closedir(&dir);
    if (scan != FR_OK)
        return 0;
    if (round->round == 0)
        return omr_storage_clear(round);

    round_path(path, round->round);
    if (f_opendir(&dir, path) != FR_OK)
        return 0;
    while ((scan = f_readdir(&dir, &item)) == FR_OK && item.fname[0]) {
        if (!(item.fattrib & AM_DIR) || item.fname[0] == '.')
            continue;
        result_path(path, round->round, item.fname, "RESULT.TXT");
        if (read_text(path, record, sizeof record)) {
            ++round->graded;
            round->total_points += (unsigned)strtoul(record, NULL, 10);
        }
    }
    f_closedir(&dir);
    return scan == FR_OK;
}

int omr_storage_load_subject(unsigned subject, OmrExam *exam)
{
    char path[16], settings[320];
    OmrExam loaded;
    if (subject > 99U)
        return 0;
    snprintf(path, sizeof path, "0:/KEY%02u.TXT", subject);
    if (!read_text(path, settings, sizeof settings) || !parse_exam(settings, &loaded))
        return 0;
    *exam = loaded;
    return 1;
}
int omr_storage_duplicate(const OmrRound *round, const char *id)
{
    char path[48];
    FILINFO item;
    result_path(path, round->round, id, "RESULT.TXT");
    return f_stat(path, &item) == FR_OK;
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

int omr_storage_save(OmrRound *round, const char *id, const char *name,
                     const char *timestamp, unsigned subject, unsigned score, int review,
                     const int answers[12], const uint16_t *front,
                     const uint16_t *back)
{
    char path[48], temp[48], record[370];
    FIL file;
    if (omr_storage_duplicate(round, id))
        return 0;
    snprintf(path, sizeof path, "0:/R%07u/%s", round->round, id);
    const FRESULT dir_status = f_mkdir(path);
    if (dir_status != FR_OK && dir_status != FR_EXIST)
        return 0;

    result_path(path, round->round, id, "FRONT.BMP");
    if (!save_bmp(path, front))
        return 0;
    result_path(path, round->round, id, "BACK.BMP");
    if (!save_bmp(path, back))
        return 0;

    const int size = snprintf(record, sizeof record,
        "%u\r\nID=%s\r\nNAME=%s\r\nSUBJECT=%02u\r\nRTC=%s\r\n"
        "STATUS=%s\r\nANSWER=%d %d %d %d %d %d %d %d %d %d / %d %d\r\n",
        score, id, name, subject, timestamp, review ? "REVIEW" : "GRADED", answers[0], answers[1], answers[2], answers[3],
        answers[4], answers[5], answers[6], answers[7], answers[8], answers[9],
        answers[10], answers[11]);
    result_path(temp, round->round, id, "RESULT.TMP");
    result_path(path, round->round, id, review ? "REVIEW.TXT" : "RESULT.TXT");
    if (review)
        (void)f_unlink(path);
    if (size < 0 || size >= (int)sizeof record ||
        f_open(&file, temp, FA_CREATE_ALWAYS | FA_WRITE) != FR_OK)
        return 0;
    const int wrote = write_bytes(&file, record, (UINT)size);
    const FRESULT closed = f_close(&file);
    if (!wrote || closed != FR_OK || f_rename(temp, path) != FR_OK)
        return 0;
    if (!review) {
        ++round->graded;
        round->total_points += score;
    }
    return 1;
}





