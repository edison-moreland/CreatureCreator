//
//  Uniforms.h
//  CreatureCreator
//
//  Created by Edison Moreland on 11/25/23.
//

#ifndef Uniforms_h
#define Uniforms_h

#include <simd/simd.h>

struct Uniforms {
    simd_float4x4 camera;
    simd_float3 cameraPosition;
};

#endif /* Uniforms_h */
