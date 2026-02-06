// Kingdom shape mask shader
// Uses alpha channel from texture to clip the color overlay into kingdom shape
shader_type canvas_item;

uniform vec4 overlay_color : source_color = vec4(1.0, 0.95, 0.7, 0.5);
uniform sampler2D shape_mask : hint_default_white;

void fragment() {
	// Sample the mask texture at current UV
	vec4 mask = texture(shape_mask, UV);
	
	// Use mask's alpha to control visibility
	COLOR = overlay_color;
	COLOR.a *= mask.a;
}
