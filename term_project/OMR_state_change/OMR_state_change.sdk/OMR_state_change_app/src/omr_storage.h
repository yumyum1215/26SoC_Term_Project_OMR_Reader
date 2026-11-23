#ifndef OMR_STORAGE_H
#define OMR_STORAGE_H

#include "omr_grading.h"

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

int omr_storage_open(OmrExam *exam, OmrRound *round);
int omr_storage_clear(OmrRound *round);
int omr_storage_duplicate(const OmrRound *round, const char *id);
int omr_storage_save(OmrRound *round, const char *id, const char *name,
                     const char *timestamp, unsigned score, int review,
                     const int answers[12], const uint16_t *front,
                     const uint16_t *back);

#endif

