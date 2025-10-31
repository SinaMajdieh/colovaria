// flow_field_particle.glsl
#[compute]
#version 450

layout(local_size_x = 256, local_size_y = 1, local_size_z = 1) in;

// Input buffers
layout(set = 0, binding = 0, std430) restrict readonly buffer SourcePositions {
    vec2 source_positions[];
};

layout(set = 0, binding = 1, std430) restrict readonly buffer TargetPositions {
    vec2 target_positions[];
};

layout(set = 0, binding = 2, std430) restrict readonly buffer Colors {
    vec4 colors[];
};

// Output texture
layout(set = 0, binding = 3, rgba8) uniform restrict writeonly image2D output_image;

// Uniforms
layout(push_constant, std430) uniform Params {
    float progress;
    float time;
    float flow_strength;
    float curl_intensity;
    float target_pull;
    int particle_count;
    ivec2 image_size;
} params;

// Simplex noise function (GPU-optimized)
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439,
                       -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0))
                   + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m;
    m = m*m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

void main() {
    uint idx = gl_GlobalInvocationID.x;
    
    if (idx >= params.particle_count) return;
    
    // Get particle data
    vec2 start = source_positions[idx];
    vec2 end = target_positions[idx];
    vec4 color = colors[idx];
    
    // Eased progress
    float t = params.progress;
    float eased = t < 0.5 ? 4.0 * t * t * t : 0.5 * pow(2.0 * t - 2.0, 3.0) + 1.0;
    
    // Base interpolation
    vec2 pos = mix(start, end, eased);
    
    // Flow field influence
    float noise_scale = 0.008;
    float angle = snoise(pos * noise_scale) * 6.283185;
    float time_offset = snoise(vec2(pos * 0.002 + params.time * 0.3));
    angle += time_offset * 1.57079;
    
    vec2 flow = vec2(cos(angle), sin(angle));
    float flow_intensity = sin(eased * 3.14159) * params.flow_strength;
    
    // Apply flow + curl
    pos += flow * flow_intensity;
    pos += vec2(-flow.y, flow.x) * params.curl_intensity * flow_intensity;
    
    // Target pull
    pos += (end - pos) * pow(eased, 1.5) * params.target_pull;
    
    // Clamp to bounds
    ivec2 pixel_pos = ivec2(clamp(pos, vec2(0.0), vec2(params.image_size - 1)));
    
    // Write to output texture
    imageStore(output_image, pixel_pos, color);
}
