shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 highlight_color : source_color = vec3(1.0, 0.0, 0.0); // Default red
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.01;
uniform float highlight_intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    // Base glowing color
    vec3 color = highlight_color * highlight_intensity;

    // Subtle outline
    vec3 normal = normalize(NORMAL);
    float edge = max(0.0, dot(normal, VIEW));
    float outline = smoothstep(0.0, outline_thickness, edge);

    // Strong emission for glow effect
    ALBEDO = mix(color * 0.5, vec3(0.0), outline); // Dimmer albedo for contrast
    EMISSION = color * highlight_intensity * 2.0; // Bright emission
}
