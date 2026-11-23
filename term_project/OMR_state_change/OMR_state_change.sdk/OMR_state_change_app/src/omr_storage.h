#ifndef OMR_STORAGE_H
#define OMR_STORAGE_H

#include "omr_grading.h"

enum { OMR_FIRST_SUBJECT = 1, OMR_LAST_SUBJECT = 6 };

typedef struct {
    OmrLayout layout;
    OmrBox back_boxes[2];
    int key[12];
    unsigned points[12];
} OmrExam;

typedef struct {
    unsigned round;
    unsigned graded;
    unsigned total_points;
} OmrRound;

int omr_storage_open(OmrLayout *subject_layout, OmrRound *round);
int omr_storage_load_subject(unsigned subject, OmrExam *exam);
int omr_storage_clear(OmrRound *round);
int omr_storage_duplicate(const OmrRound *round, const char *id);
int omr_storage_save(OmrRound *round, const char *id, const char *name,
                     const char *timestamp, unsigned subject, unsigned score, int review,
                     const int answers[12], const uint16_t *front,
                     const uint16_t *back);

#endif

