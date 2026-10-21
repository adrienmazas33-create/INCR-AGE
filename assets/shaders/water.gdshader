shader_type canvas_item;
// Scintillement discret de l'eau, calé sur la grille de pixels du monde et
// cadencé à faible fréquence pour rester dans l'esprit pixel art.
// Ne touche que les pixels bleus (les berges restent fixes).

uniform float fps = 6.0;
uniform float strength = 0.5;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.b > c.r + 0.15 && c.b >= c.g) {
		vec2 p = floor(world_pos);
		float t = floor(TIME * fps) / fps;
		float w = sin(p.x * 0.31 + p.y * 0.83 + t * 1.6) + sin(p.x * 0.13 - p.y * 0.47 - t * 1.1);
		float glint = step(1.62, w + 0.25 * sin(p.y * 2.1));
		float dark = step(w, -1.7);
		c.rgb = mix(c.rgb, vec3(0.80, 0.93, 0.98), glint * strength);
		c.rgb *= 1.0 - dark * 0.08;
	}
	COLOR = c;
}
