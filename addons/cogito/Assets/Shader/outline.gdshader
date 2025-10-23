shader_type spatial;
render_mode unshaded, cull_front;

uniform vec3 outline_color : source_color = vec3(1.0, 0.0, 0.0); // Default red outline
uniform float outline_scale = 0.02; // Amount to scale vertices outward

void vertex() {
    // Scale vertices outward along normals
    VERTEX += NORMAL * outline_scale;
}

void fragment() {
    // Set the outline color
    ALBEDO = outline_color;
}
