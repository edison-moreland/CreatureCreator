#ifndef COUNTER_H
#define COUNTER_H

#include <stdint.h>

void* counter_make();
uint64_t counter_next(void*);
void counter_free(void*);

#endif