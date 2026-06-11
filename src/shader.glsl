//------------------------------------------------------------------------------
// Single shader source for all platforms. sokol-shdc cross-compiles this at
// build time to MSL (macOS/iOS), HLSL (Windows), GLSL (Linux),
// GLSL-ES (Android / WebGL2) and WGSL (WebGPU).
//------------------------------------------------------------------------------
@vs vs
out vec2 uv;
void main() {
    // fullscreen triangle from the vertex index alone, no vertex buffers
    vec2 pos = vec2(float((gl_VertexIndex << 1) & 2), float(gl_VertexIndex & 2));
    gl_Position = vec4(pos * 2.0 - 1.0, 0.0, 1.0);
    uv = pos;
}
@end

@fs fs
layout(binding = 0) uniform fs_params {
    vec2 resolution;
    float time;
};

in vec2 uv;
out vec4 frag_color;

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    vec2 p = uv * 2.0 - 1.0;
    p.x *= resolution.x / resolution.y;

    vec2 q = p;
    float glow = 0.0;
    for (int i = 0; i < 5; i++) {
        // complex-square fold, then distance to a pulsing ring
        q = vec2(q.x * q.x - q.y * q.y, 2.0 * q.x * q.y) * 0.6 + p;
        float d = abs(length(q) - 0.5 - 0.3 * sin(time * 0.7 + float(i)));
        glow += exp(-4.0 * d);
    }
    vec3 col = palette(glow * 0.2 + time * 0.03) * glow * 0.5;
    col = col / (1.0 + col);         // tone map
    col = pow(col, vec3(1.0 / 2.2)); // gamma
    frag_color = vec4(col, 1.0);
}
@end

@program demo vs fs
