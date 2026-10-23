extends SceneTree
## Jeu de tuiles original d'INCR-AGE (voie C, docs/TILESET_SPEC.md) : tuiles dessinées pixel par
## pixel. Chaque motif est écrit ci-dessous point par point, et sa place dans chaque tuile est choisie
## à la main ; aucun bruit aléatoire. Toutes les couleurs viennent de assets/art/tiles/palette.gpl.
## Usage : godot --headless --path . --script res://tools/draw_tiles.gd, puis --import.
##
## Étape 1 : six remplissages d'herbe (grass_fill.png, 6 tuiles de 32 px côte à côte).
## Étape 2 : trois remplissages de terre (dirt_fill.png) et les 16 tuiles « terre sur herbe » en
## grille double (dirt_on_grass.png, planche 4 x 4).
## Les bords de chaque tuile restent du vert de fond : les six variantes se raccordent entre elles.

const OUT := "res://assets/art/tiles/"
const T := 32

## Couleurs de la palette utilisées par les motifs (une lettre par couleur).
const INK := {
	"k": Color8(47, 79, 44), "a": Color8(62, 106, 53), "g": Color8(82, 127, 61),
	"b": Color8(107, 150, 72), "c": Color8(143, 174, 88), "d": Color8(184, 196, 110),
	"y": Color8(232, 211, 106), "o": Color8(227, 154, 91), "w": Color8(242, 239, 226),
	# Terre (1 foncée à 5 claire) et roche (cailloux).
	"1": Color8(74, 50, 38), "2": Color8(107, 74, 51), "3": Color8(140, 101, 66),
	"4": Color8(171, 132, 86), "5": Color8(199, 162, 110),
	"Q": Color8(82, 74, 82), "q": Color8(109, 100, 102), "r": Color8(139, 130, 124), "R": Color8(173, 162, 150),
}
const DIRT_BASE := "4"
const BASE := "g"

## Motifs dessinés à la main (« . » : transparent).
const STAMPS := {
	# Grande touffe en éventail : brins clairs dehors, plus sombres dedans, ombre au pied.
	"tuft": [
		".c...c.",
		".cb.bc.",
		"..bcb..",
		".abcba.",
		"..aka..",
	],
	"tuft_small": [
		"c...c",
		".bcb.",
		".aba.",
		"..k..",
	],
	# Brin isolé, pointe éclairée.
	"sprig": [
		".d.",
		"cb.",
		".bc",
		".a.",
	],
	# Plaque d'herbe plus claire, bords irréguliers.
	"light": [
		".bbbb..",
		"bbbbbbb",
		"..bbbb.",
	],
	# Creux d'ombre très léger.
	"shade": [
		".aaa.",
		"aaaaa",
	],
	# Motte : bombement éclairé en haut, ombre au pied.
	"mound": [
		"..ccc..",
		".cbbbc.",
		"bbgbgbb",
		"abbbbba",
		".aakaa.",
	],
	"flower_yellow": [
		".y.",
		"yoy",
		".y.",
		".a.",
	],
	"flower_white": [
		".w.",
		"wyw",
		".w.",
		".a.",
	],
	# Terre : caillou éclairé en haut à gauche, ombré en bas à droite.
	"stone": [
		".RR.",
		"Rrrq",
		".qQ.",
	],
	"pebble": [
		"Rr",
		"qQ",
	],
	# Terre tassée plus sombre, terre sèche plus claire, petite fissure.
	"worn": [
		".333.",
		"33333",
		"..33.",
	],
	"dry": [
		".55",
		"555",
		"55.",
	],
	"crack": [
		"2..",
		".2.",
		".22",
	],
}

## Trois remplissages de terre (chemins, sol du camp).
const DIRT_TILES := [
	{"stamps": [["stone", 6, 8], ["pebble", 22, 21], ["worn", 16, 3], ["dry", 4, 24], ["crack", 25, 10]],
		"dark": [[12, 17], [28, 29], [3, 3]], "light": [[19, 13], [9, 28]]},
	{"stamps": [["pebble", 10, 22], ["worn", 20, 15], ["dry", 5, 6], ["crack", 14, 27]],
		"dark": [[26, 4], [4, 15], [30, 24]], "light": [[16, 9], [24, 28], [2, 29]]},
	{"stamps": [["stone", 19, 5], ["pebble", 4, 14], ["worn", 8, 25], ["dry", 24, 24]],
		"dark": [[14, 12], [28, 15], [2, 6]], "light": [[11, 3], [17, 20], [29, 9]]},
]

## Grille double (docs/TILESET_SPEC.md, section 5) : lignes de partage ondulées, tracées à la main
## (décalage en pixels, ligne par ligne), qui coupent les bords de la tuile à 16 px pile pour se
## raccorder d'une tuile à l'autre. WAVE_V : ligne verticale, décalage en x pour chaque y ;
## WAVE_H : ligne horizontale, décalage en y pour chaque x.
const WAVE_V := [0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 0, -1, -1, -2, -2, -2, -1, -1, 0, 0, 1, 2, 2, 3, 3, 2, 2, 1, 1, 0, 0, 0]
const WAVE_H := [0, 1, 1, 2, 2, 1, 1, 0, 0, -1, -2, -2, -3, -3, -2, -1, -1, 0, 0, 1, 1, 1, 2, 2, 1, 1, 0, 0, -1, -1, 0, 0]

## Les six tuiles : motifs [nom, x, y] et points isolés sombres « a » et clairs « b ».
## 0 à 3 : remplissages courants ; 4 (motte) et 5 (fleurs) : variantes « à détail », plus rares.
const TILES := [
	{"stamps": [["tuft", 5, 7], ["tuft_small", 21, 20], ["light", 17, 4]],
		"dark": [[12, 24], [27, 11], [3, 18], [24, 29]], "light": [[9, 15], [29, 26], [15, 29], [2, 2]]},
	{"stamps": [["tuft_small", 8, 22], ["sprig", 25, 6], ["shade", 15, 13]],
		"dark": [[4, 8], [20, 27], [28, 17]], "light": [[11, 4], [23, 14], [3, 28], [17, 20]]},
	{"stamps": [["tuft", 19, 21], ["sprig", 6, 11], ["sprig", 27, 3], ["light", 3, 26]],
		"dark": [[14, 6], [25, 14], [10, 19]], "light": [[20, 9], [5, 4], [29, 28]]},
	{"stamps": [["light", 20, 15], ["tuft_small", 4, 5], ["sprig", 13, 24], ["shade", 24, 26]],
		"dark": [[9, 14], [29, 6], [18, 4]], "light": [[2, 20], [14, 10], [26, 22]]},
	{"stamps": [["mound", 12, 12], ["sprig", 25, 24], ["tuft_small", 3, 3]],
		"dark": [[6, 25], [27, 9]], "light": [[20, 4], [9, 29]]},
	{"stamps": [["flower_yellow", 8, 9], ["flower_white", 22, 19], ["flower_yellow", 26, 6], ["tuft_small", 11, 23]],
		"dark": [[18, 12], [4, 27]], "light": [[15, 4], [28, 28]]},
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var img := Image.create(T * TILES.size(), T, false, Image.FORMAT_RGBA8)
	for i in TILES.size():
		_draw_tile(img, i * T, TILES[i])
	_check_palette(img)
	img.save_png(OUT + "grass_fill.png")
	print("draw_tiles : grass_fill.png (%d tuiles)" % TILES.size())
	# Étape 2 : trois remplissages de terre, puis les 16 tuiles « terre sur herbe ».
	var dirt := Image.create(T * DIRT_TILES.size(), T, false, Image.FORMAT_RGBA8)
	for i in DIRT_TILES.size():
		_draw_tile(dirt, i * T, DIRT_TILES[i], DIRT_BASE, "2", "5")
	_check_palette(dirt)
	dirt.save_png(OUT + "dirt_fill.png")
	var pair := _dual_pair(img, dirt)
	_check_palette(pair)
	pair.save_png(OUT + "dirt_on_grass.png")
	print("draw_tiles : dirt_fill.png (%d tuiles), dirt_on_grass.png (16 tuiles)" % DIRT_TILES.size())
	quit()


## Planche 4 x 4 d'une paire en grille double : la tuile n (n = coins couverts par la terre :
## haut-gauche 1, haut-droite 2, bas-gauche 4, bas-droite 8) est en colonne n % 4, rangée n / 4.
## Tuiles opaques : l'herbe y reprend le remplissage 1 (le plus sobre), la terre le remplissage 0.
## Bordure : la terre fonce d'un ton contre l'herbe, et de deux sous un bord d'herbe situé au-dessus
## (ombre de l'herbe qui surplombe) ; l'herbe s'assombrit le long du bord, avec quelques pointes claires.
func _dual_pair(grass: Image, dirt: Image) -> Image:
	var out := Image.create(T * 4, T * 4, false, Image.FORMAT_RGBA8)
	for n in 16:
		var ox := (n % 4) * T
		var oy := (n / 4) * T
		for y in T:
			for x in T:
				var is_dirt := _dirt_at(n, x, y)
				var col: Color
				if is_dirt:
					col = dirt.get_pixel(x, y)
					if not _dirt_at(n, x, y - 1):
						col = INK["2"]
					elif not (_dirt_at(n, x - 1, y) and _dirt_at(n, x + 1, y) and _dirt_at(n, x, y + 1)):
						col = INK["3"]
				else:
					col = grass.get_pixel(T + x, y)
					var touches := _dirt_at(n, x - 1, y) or _dirt_at(n, x + 1, y) or _dirt_at(n, x, y - 1) or _dirt_at(n, x, y + 1)
					if touches:
						col = INK["b"] if (x * 7 + y * 13) % 5 < 2 else INK["a"]
				out.set_pixel(ox + x, oy + y, col)
	return out


## Vrai si le pixel (x, y) de la tuile n est de la terre. Les 4 coins de la tuile valent 1 (terre) ou 0
## (herbe) ; leur moyenne pondérée selon la position (interpolation bilinéaire), seuillée à 0,5, donne des
## bords droits entre deux coins pareils et des coins arrondis ailleurs. Les lignes ondulées décalent la
## position : le bord coupe toujours les côtés de la tuile à 16 px, pour se raccorder aux voisines.
## Un pixel juste hors de la tuile est rabattu sur son bord (le voisin y a les mêmes coins).
func _dirt_at(n: int, x: int, y: int) -> bool:
	var cx := clampi(x, 0, T - 1)
	var cy := clampi(y, 0, T - 1)
	var u := clampf((cx + 0.5 - int(WAVE_V[cy])) / T, 0.0, 1.0)
	var v := clampf((cy + 0.5 - int(WAVE_H[cx])) / T, 0.0, 1.0)
	var top := (1.0 - u) * float(n & 1 != 0) + u * float(n & 2 != 0)
	var bottom := (1.0 - u) * float(n & 4 != 0) + u * float(n & 8 != 0)
	return (1.0 - v) * top + v * bottom >= 0.5


## Fond uni, motifs placés à la main, puis points isolés sombres et clairs.
func _draw_tile(img: Image, ox: int, tile: Dictionary, base := BASE, dark := "a", light := "b") -> void:
	img.fill_rect(Rect2i(ox, 0, T, T), INK[base])
	for s: Array in tile["stamps"]:
		var rows: Array = STAMPS[s[0]]
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] != ".":
					_put(img, ox, s[1] + x, s[2] + y, INK[row[x]])
	for p: Array in tile["dark"]:
		_put(img, ox, p[0], p[1], INK[dark])
	for p: Array in tile["light"]:
		_put(img, ox, p[0], p[1], INK[light])


## Un motif ne déborde jamais de sa tuile : les raccords restent invisibles.
func _put(img: Image, ox: int, x: int, y: int, col: Color) -> void:
	if x < 0 or y < 0 or x >= T or y >= T:
		push_error("draw_tiles : point (%d, %d) hors de la tuile" % [x, y])
		return
	img.set_pixel(ox + x, y, col)


## Contrôle : toute couleur doit appartenir à la palette du projet.
func _check_palette(img: Image) -> void:
	var allowed := {}
	var gpl := FileAccess.get_file_as_string(OUT + "palette.gpl")
	for line in gpl.split("\n"):
		var parts := line.strip_edges().split_floats(" ", false)
		if parts.size() >= 3 and not line.begins_with("#") and line.strip_edges()[0].is_valid_int():
			allowed[Color8(int(parts[0]), int(parts[1]), int(parts[2])).to_html(false)] = true
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and not allowed.has(c.to_html(false)):
				push_error("draw_tiles : couleur hors palette en (%d, %d) : %s" % [x, y, c.to_html(false)])
				return
	print("draw_tiles : toutes les couleurs appartiennent à la palette (%d couleurs autorisées)" % allowed.size())
