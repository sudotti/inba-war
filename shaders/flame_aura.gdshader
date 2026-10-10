shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float time;
uniform float intensity;
uniform float burst_progress;
uniform float layer_speed;
uniform float layer_scale;

void fragment() {
	vec2 uv = UV;
	
	float height = 1.0 - uv.y;
	
	float base_width = mix(0.0, 1.0, 1.0 - height);
	base_width = pow(base_width, 0.6);
	
	vec2 p = uv;
	p.y -= time * layer_speed;
	p.x *= 1.0 + sin(p.y * 12.0 + time * 2.0) * 0.12;
	p.x *= 1.0 + sin(p.y * 24.0 - time * 1.5) * 0.06;
	
	float n = texture(TEXTURE, p * vec2(8.0, 6.0)).r;
	n = smoothstep(0.25, 0.75, n);
	
	float mask = 1.0 - abs(uv.x - 0.5) * 2.0 / base_width;
	mask = smoothstep(0.0, 0.15, mask);
	mask *= smoothstep(0.0, 0.08, uv.x);
	mask *= smoothstep(1.0, 0.92, uv.x);
	mask *= smoothstep(0.0, 0.12, uv.y);
	mask *= smoothstep(1.0, 0.85, uv.y);
	
	float burst = 1.0 + burst_progress * 2.5 * (1.0 - burst_progress);
	
	float alpha = n * mask * intensity * burst;
	
	vec3 core = vec3(1.0, 0.95, 0.6);
	vec3 mid = vec3(1.0, 0.55, 0.12);
	vec3 outer = vec3(0.9, 0.2, 0.05);
	vec3 tip = vec3(0.45, 0.08, 0.03);
	
	vec3 col = mix(tip, outer, smoothstep(0.75, 0.55, height));
	col = mix(col, mid, smoothstep(0.55, 0.3, height));
	col = mix(col, core, smoothstep(0.3, 0.0, height));
	
	COLOR = vec4(col * alpha, alpha);
}