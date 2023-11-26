#ifndef SURFACES_H
#define SURFACES_H

#include "transform.h"

struct Ellipsoid {
    float size[3];
};

void* surface_pipeline_make(void*); // (MTLDevice)
void surface_pipeline_free(void*);  // (SurfacePipeline)
void surface_pipeline_begin(void*); // (SurfacePipeline)
void surface_pipeline_end(void*);   // (SurfacePipeline)
void surface_pipeline_draw_ellipsoid(void*, struct Transform transform, struct Ellipsoid ellipsoid); // (SurfacePipeline, ...)
void surface_pipeline_encode(void*, void*); // (SurfacePipeline, MTLRenderCommandEncoder)

#endif
