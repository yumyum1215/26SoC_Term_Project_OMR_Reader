#include "omr_grading.h"
#include "omr_digit_model.h"
#include <limits.h>

typedef struct { int x, y; } Point;

static int dark(const uint16_t *frame, int x, int y)
{
    const unsigned pixel = frame[y * OMR_WIDTH + x];
    const unsigned red = (pixel >> 11) & 31U;
    const unsigned green = (pixel >> 5) & 63U;
    const unsigned blue = pixel & 31U;
    return red * 2U + green + blue * 2U < 100U;
}

static int black_ink(const uint16_t *frame, int x, int y)
{
    /* Suppress the stock form's cyan/blue printed lines and numbers. */
    const unsigned pixel = frame[y * OMR_WIDTH + x];
    return ((pixel >> 11) & 31U) < 14U &&
           ((pixel >> 5) & 63U) < 30U && (pixel & 31U) < 16U;
}

static int paper(const uint16_t *frame, int x, int y)
{
    const unsigned pixel = frame[y * OMR_WIDTH + x];
    return ((pixel >> 11) & 31U) >= 22U &&
           ((pixel >> 5) & 63U) >= 44U && (pixel & 31U) >= 22U;
}

static int timing_row(const uint16_t *frame, Point bars[27], int *pitch1000)
{
    int top;
    for (top = 16; top < 92; ++top) {
        int white = 0;
        for (int x = 48; x < 320; x += 4)
            white += paper(frame, x, top);
        if (white >= 42)
            break;
    }
    if (top == 92)
        return 0;

    int count = 0, weight = 0, sum_x = 0, sum_y = 0, columns = 0;
    const int band_start = top > 23 ? top - 7 : 16;
    const int band_end = top + 22;
    for (int x = 65; x <= 455; ++x) {
        int length = 0, best = 0, center = 0;
        if (x < 455) {
            for (int y = band_start; y < band_end; ++y) {
                if (black_ink(frame, x, y) && paper(frame, x - 4, y) &&
                    paper(frame, x + 4, y)) {
                    ++length;
                    if (length > best) {
                        best = length;
                        center = y - (length - 1) / 2;
                    }
                } else
                    length = 0;
            }
        }
        if (best >= 4 && best <= 13) {
            weight += best;
            sum_x += x * best;
            sum_y += center * best;
            ++columns;
        } else if (columns) {
            if (columns > 5 || count == 27)
                return 0;
            bars[count++] = (Point){(sum_x + weight / 2) / weight,
                                    (sum_y + weight / 2) / weight};
            weight = sum_x = sum_y = columns = 0;
        }
    }
    if (count != 27)
        return 0;

    /* Seven identification columns, then four groups of five answer columns. */
    const int pitch = (bars[26].x - bars[0].x) * 1000 / 30;
    if (pitch < 7000 || pitch > 14000)
        return 0;
    for (int i = 1; i < 27; ++i) {
        const int spacing = (bars[i].x - bars[i - 1].x) * 1000;
        const int group_start = i == 7 || i == 12 || i == 17 || i == 22;
        const int expected = group_start ? pitch * 2 : pitch;
        if (spacing < expected * 69 / 100 || spacing > expected * 133 / 100)
            return 0;
    }
    *pitch1000 = pitch;
    return 1;
}

static Point row_direction(const Point bars[27])
{
    Point direction = {0, 0};
    for (int col = 0; col < 5; ++col) {
        direction.x += bars[22 + col].x - bars[col].x;
        direction.y += bars[22 + col].y - bars[col].y;
    }
    return direction;
}

static int cell_ink(const uint16_t *frame, Point mark, Point direction,
                    const OmrLayout *layout, int pitch, int row)
{
    const int distance = (pitch * (layout->first_row_pitch +
                                     row * layout->row_step_pitch) + 500000) / 1000000;
    const int tilt = direction.y * distance;
    const int x = mark.x - (tilt + (tilt < 0 ? -direction.x : direction.x) / 2) / direction.x;
    const int y = mark.y + distance;
    if (x < 28 || x >= 452 || y < 20 || y >= 251)
        return -1;

    int ink = 0;
    for (int dy = -3; dy <= 3; ++dy)
        for (int dx = -1; dx <= 1; ++dx)
            ink += black_ink(frame, x + dx, y + dy);
    return ink;
}

static int choose_mark(int best, int second, int selected)
{
    return best < 6 ? OMR_BLANK :
           (best < 9 || second >= 6 || best - second < 5) ? OMR_REVIEW : selected;
}

static int metadata_digit(const uint16_t *frame, Point bar, Point direction,
                          const OmrLayout *layout, int pitch, int first, int last)
{
    int best = 0, second = 0, selected = OMR_BLANK;
    for (int digit = first; digit <= last; ++digit) {
        const int ink = cell_ink(frame, bar, direction, layout, pitch, digit);
        if (ink < 0)
            return OMR_REVIEW;
        if (ink > best) {
            second = best;
            best = ink;
            selected = digit;
        } else if (ink > second)
            second = ink;
    }
    return choose_mark(best, second, selected);
}

int omr_identity(const uint16_t *frame, const OmrLayout *layout, OmrIdentity *identity)
{
    Point bars[27];
    int pitch;
    if (!timing_row(frame, bars, &pitch))
        return 0;
    const Point direction = row_direction(bars);
    const int grade = metadata_digit(frame, bars[0], direction, layout, pitch, 1, 3);
    int digits[4];
    if (grade < 1)
        return 0;
    for (int column = 0; column < 4; ++column) {
        digits[column] = metadata_digit(frame, bars[1 + column], direction, layout, pitch, 0, 9);
        if (digits[column] < 0)
            return 0;
    }
    const int class_number = 10 * digits[0] + digits[1];
    const int student_number = 10 * digits[2] + digits[3];
    if (class_number == 0 || student_number == 0)
        return 0;

    *identity = (OmrIdentity){(unsigned)grade, (unsigned)class_number, (unsigned)student_number};
    return 1;
}

int omr_subject(const uint16_t *frame, const OmrLayout *layout)
{
    Point bars[27];
    int pitch, code = 0;
    if (!timing_row(frame, bars, &pitch))
        return OMR_REVIEW;
    const Point direction = row_direction(bars);

    for (int column = 5; column <= 6; ++column) {
        const int digit = metadata_digit(frame, bars[column], direction, layout, pitch, 0, 9);
        if (digit < 0)
            return digit;
        code = code * 10 + digit;
    }
    return code;
}
int omr_front(const uint16_t *frame, const OmrLayout *layout,
              int answers[OMR_QUESTIONS])
{
    Point bars[27];
    int pitch;
    if (!timing_row(frame, bars, &pitch))
        return 0;
    const Point direction = row_direction(bars);

    for (int row = 0; row < OMR_QUESTIONS; ++row) {
        int best = 0, second = 0, selected = OMR_BLANK;
        for (int col = 0; col < 5; ++col) {
            const int ink = cell_ink(frame, bars[7 + col], direction, layout, pitch, row);
            if (ink < 0)
                return 0;
            if (ink > best) {
                second = best;
                best = ink;
                selected = col + 1;
            } else if (ink > second)
                second = ink;
        }
        answers[row] = choose_mark(best, second, selected);
    }
    return 1;
}
static int classify_digit(const uint8_t input[64])
{
    int32_t scores[10];
    for (int digit = 0; digit < 10; ++digit)
        scores[digit] = dense_bias[digit];

    for (int y = 0; y < 6; ++y) {
        for (int x = 0; x < 6; ++x) {
            for (int filter = 0; filter < 8; ++filter) {
                int32_t value = conv_bias[filter];
                for (int ky = 0; ky < 3; ++ky)
                    for (int kx = 0; kx < 3; ++kx)
                        value += input[(y + ky) * 8 + x + kx] *
                                 conv_weight[(ky * 3 + kx) * 8 + filter];
                if (value <= 0)
                    continue;
                const int feature = (y * 6 + x) * 8 + filter;
                for (int digit = 0; digit < 10; ++digit)
                    scores[digit] += value * dense_weight[feature * 10 + digit];
            }
        }
    }

    int32_t best = INT32_MIN, second = INT32_MIN;
    int result = OMR_REVIEW;
    for (int digit = 0; digit < 10; ++digit) {
        if (scores[digit] > best) {
            second = best;
            best = scores[digit];
            result = digit;
        } else if (scores[digit] > second)
            second = scores[digit];
    }
    /* Logit difference of 1.0 at the model's integer scale. */
    return best - second >= 131072 ? result : OMR_REVIEW;
}

static int match_digit(const uint16_t *frame, int left, int right, int top, int bottom)
{
    uint8_t normalized[64];
    const int w = right - left, h = bottom - top;
    if (w < 2 || h < 8 || w > h * 2)
        return OMR_REVIEW;

    for (int row = 0; row < 8; ++row) {
        for (int col = 0; col < 8; ++col) {
            int ink = 0, area = 0;
            for (int y = top + row * h / 8; y < top + ((row + 1) * h + 7) / 8; ++y)
                for (int x = left + col * w / 8; x < left + ((col + 1) * w + 7) / 8; ++x) {
                    ink += dark(frame, x, y);
                    ++area;
                }
            normalized[row * 8 + col] = (uint8_t)((ink * 16 + area / 2) / area);
        }
    }
    return classify_digit(normalized);
}
static int read_number(const uint16_t *frame, OmrBox box)
{
    const int top = box.top, bottom = box.bottom;
    int value = 0, digits = 0, start = -1;
    for (int x = box.left; x <= box.right; ++x) {
        int ink = 0;
        if (x < box.right)
            for (int y = top; y < bottom; ++y)
                ink += dark(frame, x, y);
        if (ink > 1 && start < 0)
            start = x;
        if (ink > 1 || start < 0)
            continue;

        int first = bottom, last = top;
        for (int xx = start; xx < x; ++xx)
            for (int y = top; y < bottom; ++y)
                if (dark(frame, xx, y)) {
                    if (y < first) first = y;
                    if (y + 1 > last) last = y + 1;
                }
        const int digit = match_digit(frame, start, x, first, last);
        if (digit < 0 || ++digits > 3)
            return OMR_REVIEW;
        value = value * 10 + digit;
        start = -1;
    }
    return digits == 0 ? OMR_BLANK : value == 0 ? OMR_REVIEW : value;
}

void omr_back(const uint16_t *frame, const OmrBox boxes[2], int answers[2])
{
    answers[0] = read_number(frame, boxes[0]);
    answers[1] = read_number(frame, boxes[1]);
}



