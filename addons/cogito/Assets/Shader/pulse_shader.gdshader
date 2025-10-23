shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 highlight_color : source_color = vec3(1.0, 0.0, 0.0); // Default red
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.01;
uniform float highlight_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    // Pulsing effect based on time and pulse_speed
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5; // Oscillates between 0 and 1
    vec3 color = highlight_color * highlight_intensity * pulse;

    // Simple outline based on normal and view direction
    vec3 normal = normalize(NORMAL);
    float edge = max(0.0, dot(normal, VIEW));
    float outline = smoothstep(0.0, outline_thickness, edge);

    // Combine color and outline
    ALBEDO = mix(color, vec3(0.0), outline);
    EMISSION = color;
}
