shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.5, 6.0, 0.5) = 1.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = fwidth(UV) * outline_width;
	float a = tex.a;
	a = max(a, texture(TEXTURE, clamp(UV + vec2(-px.x, 0.0), vec2(0.0), vec2(1.0))).a);
	a = max(a, texture(TEXTURE, clamp(UV + vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).a);
	a = max(a, texture(TEXTURE, clamp(UV + vec2(0.0, -px.y), vec2(0.0), vec2(1.0))).a);
	a = max(a, texture(TEXTURE, clamp(UV + vec2(0.0, px.y), vec2(0.0), vec2(1.0))).a);
	vec4 ring = vec4(outline_color.rgb, a * outline_color.a);
	COLOR = mix(ring, tex, tex.a);
}
