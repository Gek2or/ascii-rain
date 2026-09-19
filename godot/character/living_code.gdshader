shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

uniform sampler2D glyph_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform float emission_energy : hint_range(0.0, 8.0) = 2.0;
uniform vec4 code_tint : source_color = vec4(0.12, 0.50, 0.58, 1.0);
uniform float color_bleed : hint_range(0.0, 1.0) = 0.10;
uniform float symbol_change_speed : hint_range(0.0, 8.0) = 2.1;
uniform float human_echo : hint_range(0.0, 1.0) = 0.0;
uniform float disperse : hint_range(0.0, 1.0) = 0.0;
uniform bool animate_symbols = true;
varying vec3 object_position;

float hash12(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
    object_position = VERTEX;
}

void fragment() {
    vec2 grid = vec2(16.0, 8.0);
    vec2 tile = floor(UV * grid);
    vec2 within_tile = fract(UV * grid);
    float seed = hash12(tile + vec2(7.0, 13.0));
    float index = tile.x + tile.y * 16.0;
    if (animate_symbols) {
        float tick = floor(TIME * symbol_change_speed + seed * 13.0);
        // Only some glyphs flicker at each tick; no expensive screen-space effect.
        if (fract(seed * 7.3) < 0.42) {
            index = mod(index + tick * (1.0 + floor(seed * 4.0)), 91.0);
        }
    }
    vec2 new_tile = vec2(mod(index, 16.0), floor(index / 16.0));
    vec4 sample_color = texture(glyph_atlas, (new_tile + within_tile) / grid);
    if (sample_color.a < 0.56) { discard; }
    if (disperse > 0.72 && seed < (disperse - 0.72) / 0.28) { discard; }
    float pulse = 0.90 + 0.10 * sin(TIME * 2.0 - object_position.y * 6.0 + seed * 6.283);
    vec3 tint = mix(code_tint.rgb, COLOR.rgb, color_bleed);
    vec3 code_value = mix(vec3(dot(sample_color.rgb, vec3(0.2126, 0.7152, 0.0722))), sample_color.rgb, 0.18);
    ALBEDO = code_value * tint * 0.16;
    EMISSION = code_value * tint * emission_energy * pulse * (1.0 + 0.18 * human_echo);
    METALLIC = 0.0;
    ROUGHNESS = 1.0;
}
