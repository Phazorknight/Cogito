shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec3 highlight_color : source_color = vec3(1.0, 0.0, 0.0); // Default red
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.01;
uniform float highlight_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture; // Noise texture for dissolve effect

void fragment() {
    // Get noise value for dissolve
    float noise_value = texture(noise_texture, UV).r;
    if (noise_value < dissolve_amount) {
        discard; // Discard fragments for dissolve effect
    }

    // Base highlight color
    vec3 color = highlight_color * highlight_intensity;

    // Outline effect
    vec3 normal = normalize(NORMAL);
    float edge = max(0.0, dot(normal, VIEW));
    float outline = smoothstep(0.0, outline_thickness, edge);

    // Combine color and outline
    ALBEDO = mix(color, vec3(0.0), outline);
    EMISSION = color;
}
