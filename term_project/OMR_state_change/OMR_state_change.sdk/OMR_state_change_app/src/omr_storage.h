#ifndef OMR_STORAGE_H
#define OMR_STORAGE_H

#include "omr_grading.h"

enum { OMR_FIRST_SUBJECT = 1, OMR_LAST_SUBJECT = 6, OMR_TEST_SUBJECT = 10 };

static inline int omr_subject_supported(int subject)
{
    return (subject >= OMR_FIRST_SUBJECT && subject <= OMR_LAST_SUBJECT) ||
           subject == OMR_TEST_SUBJECT;
}

typedef struct {
    OmrLayout layout;
    OmrBox back_boxes[2];
    int key[12];
    unsigned points[12];
} OmrExam;

typedef struct {
    unsigned graded;
    unsigned total_points;
} OmrSummary;

typedef struct {
    unsigned student;
    unsigned scale;
    int score[OMR_LAST_SUBJECT];
} OmrGraph;

int omr_storage_next_graph(unsigned previous_student, OmrGraph *graph);
int omr_storage_open(OmrLayout *subject_layout, OmrSummary *summary);
int omr_storage_load_subject(unsigned subject, OmrExam *exam);
int omr_storage_summary(OmrSummary *summary);
int omr_storage_clear(void);
int omr_storage_save(const char *id, const char *name,
                     const char *timestamp, const OmrIdentity *identity,
                     unsigned subject, unsigned score, int review,
                     const int answers[12], const uint16_t *front,
                     const uint16_t *back);

#endif
