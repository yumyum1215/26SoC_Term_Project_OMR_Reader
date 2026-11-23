#ifndef OMR_GRADING_H
#define OMR_GRADING_H

#include <stdint.h>

enum { OMR_WIDTH = 480, OMR_HEIGHT = 272, OMR_QUESTIONS = 10 };
enum { OMR_BLANK = -1, OMR_REVIEW = -2 };

/* Vertical distances in thousandths of the printed timing-bar pitch. */
typedef struct {
    int first_row_pitch, row_step_pitch;
} OmrLayout;

typedef struct {
    int left, top, right, bottom;
} OmrBox;

int omr_front(const uint16_t *frame, const OmrLayout *layout,
              int answers[OMR_QUESTIONS]);
void omr_back(const uint16_t *frame, const OmrBox boxes[2], int answers[2]);

#endif

