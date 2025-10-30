shader_type canvas_item;

uniform float outline_width = 2.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.5, 1.0, 1.0);

void fragment() 
{
	vec4 color = texture(TEXTURE, UV);
	vec2 outline_offset = vec2(outline_width) * TEXTURE_PIXEL_SIZE;

	float max_a = 0.0;

	// haut
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, -outline_offset.y)).a);

	// bas
	max_a = max(max_a, texture(TEXTURE, UV + vec2(0.0, outline_offset.y)).a);

	// gauche
	max_a = max(max_a, texture(TEXTURE, UV + vec2(-outline_offset.x, 0.0)).a);

	// droite
	max_a = max(max_a, texture(TEXTURE, UV + vec2(outline_offset.x, 0.0)).a);

	COLOR = mix(color, outline_color, max_a - color.a);
}