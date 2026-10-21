shader_type canvas_item;
// Flash d'impact (blanc) ou lueur colorée (amélioration) : la silhouette tend vers flash_color.

uniform float flash = 0.0;
uniform vec3 flash_color = vec3(1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	// Les pixels sombres (contours) restent sombres : la silhouette reste lisible sous le flash.
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(c.rgb, flash_color, flash * smoothstep(0.12, 0.32, lum)), c.a);
}
