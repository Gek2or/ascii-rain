shader_type canvas_item;
render_mode unshaded;

uniform float impact : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 p = (UV - vec2(0.5)) * 2.0;
    // An elliptical border. The aim/character region stays completely untinted.
    float edge = smoothstep(0.46, 1.10, length(p * vec2(0.90, 1.0)));
    COLOR = vec4(0.94, 0.12, 0.055, impact * edge);
}
