shader_type canvas_item;
// Flash blanc d'impact : la silhouette devient blanche pendant quelques images.

uniform float flash = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(c.rgb, vec3(1.0), flash), c.a);
}
