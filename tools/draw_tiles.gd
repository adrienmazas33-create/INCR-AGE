extends SceneTree
## Jeu de tuiles original d'INCR-AGE (voie C, docs/TILESET_SPEC.md) : tuiles dessinées pixel par
## pixel. Chaque motif est écrit ci-dessous point par point, et sa place dans chaque tuile est choisie
## à la main ; aucun bruit aléatoire. Toutes les couleurs viennent de assets/art/tiles/palette.gpl.
## Usage : godot --headless --path . --script res://tools/draw_tiles.gd, puis --import.
##
## Étape 1 : six remplissages d'herbe (grass_fill.png, 6 tuiles de 32 px côte à côte).
## Les bords de chaque tuile restent du vert de fond : les six variantes se raccordent entre elles.

const OUT := "res://assets/art/tiles/"
const T := 32

## Couleurs de la palette utilisées par les motifs (une lettre par couleur).
const INK := {
	"k": Color8(47, 79, 44), "a": Color8(62, 106, 53), "g": Color8(82, 127, 61),
	"b": Color8(107, 150, 72), "c": Color8(143, 174, 88), "d": Color8(184, 196, 110),
	"y": Color8(232, 211, 106), "o": Color8(227, 154, 91), "w": Color8(242, 239, 226),
}
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
}

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
	quit()


func _draw_tile(img: Image, ox: int, tile: Dictionary) -> void:
	img.fill_rect(Rect2i(ox, 0, T, T), INK[BASE])
	for s: Array in tile["stamps"]:
		var rows: Array = STAMPS[s[0]]
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] != ".":
					_put(img, ox, s[1] + x, s[2] + y, INK[row[x]])
	for p: Array in tile["dark"]:
		_put(img, ox, p[0], p[1], INK["a"])
	for p: Array in tile["light"]:
		_put(img, ox, p[0], p[1], INK["b"])


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
