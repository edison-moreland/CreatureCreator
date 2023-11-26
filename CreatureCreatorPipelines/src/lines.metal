#include <metal_stdlib>

using namespace metal;

struct Instance {
    float3 a          [[attribute(0)]];
    float3 b          [[attribute(1)]];
    float3 color      [[attribute(2)]];
    float thickness   [[attribute(3)]];
    uint shape        [[attribute(4)]];
    float dash_size   [[attribute(5)]];
    float dash_offset [[attribute(6)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float dash_offset;
    float dash_size;
};

struct Uniform {
    float4x4 camera;
    float3 camera_position;
};

vertex VertexOut
vertex_main(Instance inst [[stage_in]],
            uint vid [[vertex_id]],
            const device float2 *geometry [[buffer(1)]],
            constant Uniform &uniform [[buffer(0)]])
{
    float3 origin = (inst.a + inst.b) / 2.0;
    float size = length(inst.a - inst.b);
    float2 vert = geometry[vid + (4 * inst.shape)] * (float2(size, inst.thickness) / 2.0);

    float dash_offset = inst.dash_offset;
    if (vert.x > 0) {
        dash_offset += size;
    }

    // Construct a plane facing the camera
    float3 to_camera = uniform.camera_position - origin;
    float3 u = normalize(inst.a - origin);
    float3 v = normalize(cross(u, to_camera));
    float3 pos = (u * vert.x) + (v * vert.y);

    VertexOut out;
    out.position = uniform.camera * float4(origin + pos, 1.0);
    out.color = float4(inst.color, 1.0);
    out.dash_offset = dash_offset;
    out.dash_size = inst.dash_size;
    return
    out;
}

fragment float4
fragment_main(VertexOut inst [[stage_in]])
{
    if (inst.dash_size == 0.0) {
        return inst.color;
    }

    float y = (sin((inst.dash_offset * M_PI_F) / inst.dash_size) / 2.0) + 0.5;

    if (y > 0.5) {
        return
        float4(inst.color.xyz, 1.0);
    } else {
        return
        float4(inst.color.xyz, 0.0);
    }
}
