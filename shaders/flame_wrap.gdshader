shader_type canvas_item;
render_mode blend_add, unshaded;

uniform sampler2D noise_texture;
uniform float time;
uniform float intensity;
uniform float edge_width;
uniform float pulse;
uniform bool is_front;

void fragment() {
	vec4 tex_col = texture(TEXTURE, UV);
	if (tex_col.a == 0.0) discard;
	
	vec2 p = UV;
	p.y -= time * 0.4;
	p.x += sin(p.y * 10.0 + time * 1.5) * 0.02;
	p.x += sin(p.y * 22.0 - time * 2.0) * 0.01;
	
	float n = texture(noise_texture, p * vec2(6.0, 5.0)).r;
	n = smoothstep(0.3, 0.7, n);
	
	float edge = 1.0 - tex_col.a;
	edge = smoothstep(0.0, edge_width, edge);
	
	float glow = n * edge * intensity * pulse;
	
	vec3 inner = vec3(1.0, 0.6, 0.1);
	vec3 outer = vec3(0.9, 0.15, 0.03);
	
	vec3 col = mix(inner, outer, n);
	
	if (is_front) {
		glow *= 0.35;
		col = mix(col, vec3(1.0, 0.8, 0.4), 0.4);
	}
	
	COLOR = vec4(col * glow, glow);
}