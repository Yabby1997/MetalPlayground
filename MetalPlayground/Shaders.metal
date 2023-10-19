//
//  Shaders.metal
//  MetalPlayground
//
//  Created by user on 2023/10/18.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[ position ]];
    float2 texturePosition;
};

vertex VertexOut basic_vertex(const device float4* verticies [[ buffer(0) ]],
                              constant float4x4& translation [[ buffer(1) ]],
                              constant float4x4& scale [[ buffer(2) ]],
                              uint vertexIndex [[ vertex_id ]]) {
    VertexOut out;
    out.position = scale * translation * verticies[vertexIndex];
    out.texturePosition = float2((vertexIndex % 2), (vertexIndex / 2));
    return out;
}

fragment half4 basic_fragment(VertexOut vertexOut [[ stage_in ]],
                              texture2d<half> texture [[ texture(0) ]]) {
    sampler texture_sampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
    return texture.sample(texture_sampler, vertexOut.texturePosition);
}
