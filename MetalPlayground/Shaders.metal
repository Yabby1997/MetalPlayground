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
                              constant float2& textureInset [[ buffer(3) ]],
                              constant bool& flipEncoding [[ buffer(4) ]],
                              uint vertexIndex [[ vertex_id ]]) {
    VertexOut out;
    out.position = translation * scale * verticies[vertexIndex];
    out.texturePosition = float2(((vertexIndex + (flipEncoding ? 1 : 0)) % 2) + ((vertexIndex + (flipEncoding ? 1 : 0)) % 2 == 0 ? textureInset[0] : -textureInset[0]),
                                 (vertexIndex / 2 + (vertexIndex / 2 == 0 ? textureInset[1] : -textureInset[1])));
    return out;
}

fragment half4 basic_fragment(VertexOut vertexOut [[ stage_in ]],
                              texture2d<half> texture [[ texture(0) ]]) {
    sampler texture_sampler(mip_filter::linear, mag_filter::linear, min_filter::linear);

    if (vertexOut.texturePosition.x < 0.0 || vertexOut.texturePosition.x > 1.0 ||
        vertexOut.texturePosition.y < 0.0 || vertexOut.texturePosition.y > 1.0) {
        return half4(0.0);
    }

    return texture.sample(texture_sampler, vertexOut.texturePosition);
}
