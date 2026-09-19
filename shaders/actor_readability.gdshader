shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 surface_color : source_color = vec4(0.32, 0.39, 0.44, 1.0);
uniform vec4 edge_color : source_color = vec4(0.36, 0.62, 0.72, 1.0);
uniform float edge_strength : hint_range(0.0, 1.0) = 0.65;
uniform float actor_fill : hint_range(0.0, 0.5) = 0.12;
void fragment() {
    float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
    float rim = pow(1.0 - facing, 2.0);
    ALBEDO = surface_color.rgb;
    ROUGHNESS = 0.74;
    METALLIC = 0.04;
    // Geometry remains depth-tested; no x-ray, no extra mesh pass per limb.
    EMISSION = surface_color.rgb * actor_fill + edge_color.rgb * rim * edge_strength * 0.62;
}
