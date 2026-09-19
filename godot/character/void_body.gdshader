shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;

uniform vec4 void_color : source_color = vec4(0.012, 0.020, 0.032, 1.0);
uniform vec4 rim_color : source_color = vec4(0.08, 0.34, 0.40, 1.0);
uniform float human_echo : hint_range(0.0, 1.0) = 0.0;
uniform float disperse : hint_range(0.0, 1.0) = 0.0;
uniform float fragmentation : hint_range(0.0, 1.0) = 0.28;
varying vec3 object_position;

float hash13(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void vertex() { object_position = VERTEX; }

void fragment() {
    vec3 cell = floor(object_position * vec3(62.0, 86.0, 62.0));
    float noise_value = hash13(cell);
    float holes = fragmentation * (1.0 - human_echo);
    if (noise_value < holes) { discard; }
    if (noise_value < disperse * 0.999) { discard; }
    float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.5);
    ALBEDO = void_color.rgb;
    EMISSION = rim_color.rgb * rim * (0.34 + human_echo * 0.18);
    ROUGHNESS = 1.0;
    METALLIC = 0.0;
}
