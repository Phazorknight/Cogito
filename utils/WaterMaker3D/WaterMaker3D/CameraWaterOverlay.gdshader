shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
    vec2 uv = SCREEN_UV;

    // Ripple effect
    float rippleSpeed = 1.5;
    float rippleDensity = 10.0;
    float rippleStrength = 0.02;

    // Calculate angle and distance from the center of the screen
    vec2 center = vec2(0.5, 0.5);
    vec2 delta = uv - center;
    float distance = length(delta);
    float angle = atan(delta.y, delta.x);

    // Apply the ripple effect
    uv.x += cos(angle * rippleDensity + TIME * rippleSpeed) * rippleStrength * distance;
    uv.y += sin(angle * rippleDensity + TIME * rippleSpeed) * rippleStrength * distance;

    // Simple blur effect
    vec4 color = vec4(0.0);
    float total = 0.0;
    for (float x = -2.0; x <= 2.0; x++) {
        for (float y = -2.0; y <= 2.0; y++) {
            vec2 samplePos = uv + vec2(x, y) * 0.001; // Blur radius
            color += texture(screen_texture, samplePos);
            total += 1.0;
        }
    }
    color /= total;

    // Output the final color
    COLOR = color;
}
