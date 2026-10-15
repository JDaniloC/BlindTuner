shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 character_screen_uv = vec2(0.5, 0.5);
uniform float aspect_ratio = 0.5625; // Largura / Altura (ex.: 720 / 1280)
uniform float vignette_radius : hint_range(0.0, 2.0) = 1.0;
uniform float vignette_softness : hint_range(0.01, 1.0) = 0.45;
uniform float blur_amount : hint_range(0.0, 5.0) = 0.0;
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.0;
uniform bool is_effect_enabled = true;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	if (!is_effect_enabled) {
		COLOR = texture(screen_texture, uv);
	} else {
		// Corrige o aspecto para manter o círculo de foco perfeitamente simétrico
		vec2 dist_uv = uv - character_screen_uv;
		dist_uv.x *= aspect_ratio;
		float dist_from_center = length(dist_uv);

		// O blur aumenta em direção às bordas, simulando a perda progressiva de campo visual
		float peripheral_factor = clamp((dist_from_center - (vignette_radius * 0.25)) / (vignette_radius * 0.75 + 0.001), 0.0, 1.0);
		float effective_blur = blur_amount * (0.35 + 0.65 * peripheral_factor);

		vec4 col = vec4(0.0);
		if (effective_blur > 0.04) {
			vec2 texel = SCREEN_PIXEL_SIZE * effective_blur * 1.5;
			col += texture(screen_texture, uv + vec2(-texel.x, -texel.y)) * 0.12;
			col += texture(screen_texture, uv + vec2( texel.x, -texel.y)) * 0.12;
			col += texture(screen_texture, uv + vec2(-texel.x,  texel.y)) * 0.12;
			col += texture(screen_texture, uv + vec2( texel.x,  texel.y)) * 0.12;
			col += texture(screen_texture, uv + vec2(0.0, -texel.y * 1.4)) * 0.13;
			col += texture(screen_texture, uv + vec2(0.0,  texel.y * 1.4)) * 0.13;
			col += texture(screen_texture, uv + vec2(-texel.x * 1.4, 0.0)) * 0.13;
			col += texture(screen_texture, uv + vec2( texel.x * 1.4, 0.0)) * 0.13;
		} else {
			col = texture(screen_texture, uv);
		}

		// Perda de cor / dessaturação
		if (desaturation > 0.0) {
			float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
			col.rgb = mix(col.rgb, vec3(gray), desaturation);
		}

		// Vinheta de túnel de visão / escuridão progressiva
		float v_start = vignette_radius * 0.45;
		float v_end = vignette_radius + vignette_softness;
		float vignette = smoothstep(v_start, v_end, dist_from_center);
		col.rgb = mix(col.rgb, vec3(0.0), clamp(vignette * darkness, 0.0, 1.0));

		COLOR = col;
	}
}
