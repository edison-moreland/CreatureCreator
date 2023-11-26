#ifndef LINES_H
#define LINES_H

#include <stdint.h>

#include "transform.h"

struct Line {
    uint8_t style;
    float color[3];
    float size;
    float thickness;
    float dash_size;
};

void* line_pipeline_make(void*); // (MTLDevice)
void line_pipeline_free(void*);  // (LinePipeline)
void line_pipeline_begin(void*); // (LinePipeline)
void line_pipeline_end(void*);   // (LinePipeline)
void line_pipeline_draw(void*, struct Transform transform, struct Line line); // (LinePipeline, ...)
void line_pipeline_encode(void*, void*); // (LinePipeline, MTLRenderCommandEncoder)

#endif
