#ifndef TRANSFORM_H
#define TRANSFORM_H

#include <simd/simd.h>

struct FFITransform {
    simd_float4x4 matrix;
    simd_float4x4 matrix_inverse;
};

#endif
