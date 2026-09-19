shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

// Same-viewport depth only: no Forward+-only normal buffer dependency.
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform bool compatibility_ndc = true;
uniform float contour_strength : hint_range(0.0, 1.0) = 0.45;
uniform float pixel_radius = 2.0;
uniform vec3 contour_color : source_color = vec3(0.28, 0.38, 0.49);

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
    float depth = texture(depth_texture, clamp(uv, vec2(0.001), vec2(0.999))).r;
    vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
    if (compatibility_ndc) {
        ndc.z = depth * 2.0 - 1.0;
    }
    vec4 view = inv_projection * vec4(ndc, 1.0);
    return clamp(-view.z / max(abs(view.w), 0.000001), 0.0, 10000.0);
}

void fragment() {
    vec2 offset = vec2(pixel_radius) / VIEWPORT_SIZE;
    float center = linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
    float left = linear_depth(SCREEN_UV - vec2(offset.x, 0.0), INV_PROJECTION_MATRIX);
    float right = linear_depth(SCREEN_UV + vec2(offset.x, 0.0), INV_PROJECTION_MATRIX);
    float top = linear_depth(SCREEN_UV - vec2(0.0, offset.y), INV_PROJECTION_MATRIX);
    float bottom = linear_depth(SCREEN_UV + vec2(0.0, offset.y), INV_PROJECTION_MATRIX);
    // Second derivative suppresses contour bands on a smooth, sloping road.
    float jump = max(abs(left + right - 2.0 * center), abs(top + bottom - 2.0 * center));
    float edge = smoothstep(0.045, 0.18, jump / max(1.0, center));
    float near_weight = 1.0 - smoothstep(32.0, 95.0, center);
    float sky_reject = 1.0 - step(250.0, center);
    ALBEDO = contour_color * edge * near_weight * sky_reject * contour_strength;
    ALPHA = 1.0;
}
