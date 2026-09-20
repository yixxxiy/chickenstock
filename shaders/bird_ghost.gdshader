shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.96, 0.88, 0.52, 0.52);

void fragment() {
	float a = texture(TEXTURE, UV).a;
	if (a < 0.12) {
		discard;
	}
	COLOR = vec4(fill_color.rgb, fill_color.a);
}
