shader_type canvas_item;
// Flash d'impact (blanc) ou lueur colorée (amélioration) : la silhouette tend vers flash_color.

uniform float flash = 0.0;
uniform vec3 flash_color = vec3(1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, flash_color, flash), c.a);
}
