extends SceneTree
## Voie C, étape 4 (docs/TILESET_SPEC.md, section 8) : arbres, buissons et souche, avec leurs ombres,
## à l'échelle de nos personnages (26 px). Tout est placé à la main : lobes du feuillage (centre et
## rayon de chaque touffe), étages du sapin, écorce et souche écrites pixel par pixel, taches de lumière
## et baies posées une à une. Le calcul se limite à l'éclairage (en haut à gauche) et au contour.
## Usage : godot --headless --path . --script res://tools/draw_nature.gd, puis --import.
## Sortie : assets/art/tiles/nature.png (planche) et nature.json (rectangle et point d'ancrage
## aux pieds de chaque objet, sur le modèle de l'atlas des décors actuel).

const OUT := "res://assets/art/tiles/"
## Feuillage (sombre à clair), conifères, écorce, ombre portée (35 % d'opacité).
const LEAF := [Color8(31, 58, 46), Color8(45, 82, 54), Color8(63, 109, 60), Color8(94, 138, 68), Color8(134, 166, 80)]
const NEEDLE := [Color8(27, 51, 48), Color8(39, 74, 61), Color8(55, 97, 71), Color8(79, 122, 82)]
const INK := {
	"T": Color8(59, 42, 34), "U": Color8(90, 63, 44), "V": Color8(122, 86, 56),
	"4": Color8(171, 132, 86), "5": Color8(199, 162, 110),
	"Z": Color8(196, 87, 63), "o": Color8(227, 154, 91),
}
const SHADOW := Color(26 / 255.0, 26 / 255.0, 46 / 255.0, 0.35)

## Écorces, de gauche (éclairée) à droite (dans l'ombre), racines évasées en bas.
const TRUNK := [
	"..TVVUT.",
	"..TVUUT.",
	"..TVUTT.",
	"..TVUUT.",
	".TVVUUT.",
	"..TVUUT.",
	"..TUVUT.",
	"..TVUUT.",
	"..TVUTT.",
	"..TVUUT.",
	"..TVVUT.",
	"..TVUUT.",
	".TVVUUTT",
	".TVUUUTT",
	"TTVVUUUT",
	"TVVUUTTT",
]
const TRUNK_THIN := [
	".TVUT.",
	".TVUT.",
	".TVTT.",
	".TVUT.",
	".TVUT.",
	"TVVUTT",
	"TVUUTT",
]
## Souche : coupe claire à cernes, flanc d'écorce.
const STUMP := [
	"...TUUUUUT....",
	"..TU5544UUT...",
	".TU54UU45UT...",
	".TU5U44U5UT...",
	".TUU5445UUT...",
	".TTUUUUUUTT...",
	".TVVUUUUUTT...",
	".TVVUUUUTTT...",
	"TVVUUUUUTTT...",
	"TVUUUUTTTTT.T.",
	"TTTTTTTTTTTTT.",
]

## Objets : taille du cadre, point d'ancrage (aux pieds), tronc [motif, x, y], lobes [x, y, rayon]
## (de l'arrière vers l'avant), taches claires et creux sombres [x, y], ombre [x, y, demi-largeur, demi-hauteur].
const OBJECTS := {
	"oak": {"size": [64, 80], "pivot": [32, 73], "trunk": ["TRUNK", 28, 57],
		"lobes": [[20, 30, 15], [44, 28, 16], [32, 18, 16], [16, 44, 12], [46, 44, 13], [31, 40, 15]],
		"light": [[22, 12], [30, 9], [14, 24], [38, 20], [26, 32]], "dark": [[40, 50], [24, 52], [50, 38]],
		"shadow": [36, 72, 24, 5]},
	"birch": {"size": [56, 88], "pivot": [28, 84], "trunk": ["TRUNK", 24, 68],
		"lobes": [[28, 14, 12], [20, 28, 12], [37, 27, 12], [27, 40, 14], [18, 52, 10], [38, 52, 10], [28, 56, 11]],
		"light": [[24, 6], [18, 20], [31, 22], [22, 36]], "dark": [[34, 60], [22, 62], [40, 44]],
		"shadow": [32, 83, 20, 5]},
	"wide": {"size": [72, 72], "pivot": [36, 68], "trunk": ["TRUNK", 32, 52],
		"lobes": [[18, 30, 14], [54, 30, 14], [36, 22, 16], [26, 40, 13], [48, 40, 13], [36, 38, 12]],
		"light": [[16, 20], [30, 12], [44, 16], [24, 30]], "dark": [[58, 42], [38, 48], [16, 44]],
		"shadow": [40, 67, 28, 5]},
	"bush": {"size": [30, 22], "pivot": [15, 20],
		"lobes": [[9, 13, 7], [21, 12, 7], [15, 9, 7], [15, 15, 7]],
		"light": [[11, 5], [7, 9]], "dark": [[20, 18]], "shadow": [17, 20, 13, 3]},
	"bush_berry": {"size": [26, 20], "pivot": [13, 18],
		"lobes": [[8, 12, 6], [18, 11, 6], [13, 8, 6], [13, 13, 6]],
		"light": [[10, 4]], "dark": [[17, 16]], "shadow": [15, 18, 11, 3],
		"berries": [[7, 10, "Z"], [12, 13, "Z"], [17, 9, "o"], [19, 14, "Z"], [10, 6, "Z"]]},
	"stump": {"size": [18, 16], "pivot": [7, 13], "trunk": ["STUMP", 0, 3], "shadow": [9, 14, 9, 2]},
}
## Sapin : étages [haut, hauteur, demi-largeur à la base], du haut vers le bas.
## Texture de feuilles, dessinée à la main et répétée dans les couronnes : petites feuilles éclairées
## en haut (+), ombrées en dessous (-) ; elle casse les dégradés lisses.
const LEAF_PATTERN := [
	"+.....+.",
	"++-..++-",
	"--...--.",
	"...+....",
	"..++-...",
	"..--....",
]
## Aiguilles du sapin : traits obliques, plus clairs du côté éclairé, plus sombres de l'autre.
const NEEDLE_PATTERN := [
	"+..-",
	".+..",
	"-.+.",
	"..-+",
]
const PINE := {"size": [44, 96], "pivot": [22, 92], "trunk": ["TRUNK_THIN", 19, 84],
	"tiers": [[2, 20, 7], [14, 24, 11], [28, 26, 14], [44, 26, 17], [60, 26, 20]], "shadow": [26, 91, 15, 4]}


func _init() -> void:
	var shapes := {"TRUNK": TRUNK, "TRUNK_THIN": TRUNK_THIN, "STUMP": STUMP}
	for rows: Array in shapes.values():
		for row: String in rows:
			assert(row.length() == rows[0].length(), "draw_nature : lignes de longueurs différentes")
	var sprites := {}
	for key: String in OBJECTS:
		sprites[key] = _draw_object(OBJECTS[key], shapes)
	sprites["pine"] = _draw_pine(PINE, shapes)
	# Planche : objets côte à côte, et leurs ombres sur une seconde rangée (ajustables à part).
	var width := 0
	var height := 0
	for key: String in sprites:
		width += sprites[key][0].get_width() + 2
		height = maxi(height, sprites[key][0].get_height())
	var sheet := Image.create(width, height + 32, false, Image.FORMAT_RGBA8)
	var atlas := {}
	var x := 0
	for key: String in sprites:
		var img: Image = sprites[key][0]
		var shadow: Image = sprites[key][1]
		var def: Dictionary = PINE if key == "pine" else OBJECTS[key]
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, 0))
		atlas[key] = {"rect": [x, 0, img.get_width(), img.get_height()], "pivot": def["pivot"]}
		sheet.blit_rect(shadow, Rect2i(Vector2i.ZERO, shadow.get_size()), Vector2i(x, height))
		atlas[key + "_shadow"] = {"rect": [x, height, shadow.get_width(), shadow.get_height()], "pivot": [def["pivot"][0], 16]}
		x += img.get_width() + 2
	_check_palette(sheet)
	sheet.save_png(OUT + "nature.png")
	var f := FileAccess.open(OUT + "nature.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(atlas, "\t"))
	print("draw_nature : %d objets et leurs ombres -> nature.png (%d x %d), nature.json" % [sprites.size(), sheet.get_width(), sheet.get_height()])
	quit()


## Objet à lobes (feuillus, buissons) ou souche seule : tronc, feuillage éclairé, contour sélectif,
## taches de lumière, baies ; ombre sur une image à part (32 px de haut, ancrée à y = 16).
func _draw_object(def: Dictionary, shapes: Dictionary) -> Array:
	var size := Vector2i(def["size"][0], def["size"][1])
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	if def.has("trunk"):
		_stamp(img, shapes[def["trunk"][0]], def["trunk"][1], def["trunk"][2])
	if def.has("lobes"):
		_draw_lobes(img, def["lobes"])
		for p: Array in def.get("light", []):
			_leaf_mark(img, p[0], p[1], LEAF[4], LEAF[3])
		for p: Array in def.get("dark", []):
			_leaf_mark(img, p[0], p[1], LEAF[1], LEAF[0])
	for b: Array in def.get("berries", []):
		if img.get_pixel(b[0], b[1]).a > 0.0:
			img.set_pixel(b[0], b[1], INK[b[2]])
	return [img, _shadow(def, size.x)]


## Feuillage : chaque pixel prend l'éclairage du lobe le plus en avant qui le contient (lumière en haut
## à gauche), plus sombre juste sous le bord d'un lobe placé devant (relief des touffes), contour
## foncé en bas et à droite, moins foncé en haut et à gauche.
func _draw_lobes(img: Image, lobes: Array) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var front := []
	front.resize(w * h)
	front.fill(-1)
	for y in h:
		for x in w:
			for i in lobes.size():
				var l: Array = lobes[i]
				if Vector2(x - l[0], y - l[1]).length() <= l[2]:
					front[y * w + x] = i
	for y in h:
		for x in w:
			var i: int = front[y * w + x]
			if i < 0:
				continue
			var l: Array = lobes[i]
			var n := Vector2(x - l[0], y - l[1]) / float(l[2])
			var t := 0.5 + 0.5 * (-0.55 * n.x - 0.75 * n.y)
			var level := clampi(int(t * 4.99) + _leaf(x, y), 0, 4)
			if y > 0 and front[(y - 1) * w + x] > i:
				level = maxi(level - 2, 0)
			var edge: bool = x == 0 or y == 0 or x == w - 1 or y == h - 1 \
				or front[y * w + x - 1] < 0 or front[y * w + x + 1] < 0 or front[(y - 1) * w + x] < 0 or front[(y + 1) * w + x] < 0
			if edge:
				level = 0 if (n.x > -0.2 or n.y > -0.2) else 1
			img.set_pixel(x, y, LEAF[level])


## Sapin : étages dessinés du bas vers le haut (chaque étage recouvre le haut du suivant), bord
## inférieur dentelé d'aiguilles, moitié gauche éclairée, ombre sous chaque étage.
func _draw_pine(def: Dictionary, shapes: Dictionary) -> Array:
	var size := Vector2i(def["size"][0], def["size"][1])
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	_stamp(img, shapes[def["trunk"][0]], def["trunk"][1], def["trunk"][2])
	var cx := size.x / 2
	var tiers: Array = def["tiers"]
	for k in range(tiers.size() - 1, -1, -1):
		var top: int = tiers[k][0]
		var height: int = tiers[k][1]
		var half: int = tiers[k][2]
		for r in height:
			var y := top + r
			var hw := int(round(half * pow(float(r + 1) / height, 0.85))) + (1 if r % 3 == 1 and r > 2 else 0)
			# Bord du bas : une pointe d'aiguilles tous les 3 px.
			for x in range(cx - hw, cx + hw + 1):
				if r == height - 1 and (x - cx) % 3 != 0:
					continue
				var side := float(x - cx) / maxf(hw, 1.0)
				var level := clampi((3 if side < -0.35 else (2 if side < 0.25 else 1)) + _needle(x, y, side), 0, 3)
				if r >= height - 3:
					level = maxi(level - 1, 0)
				if absi(x - cx) == hw or r == height - 1:
					level = 0
				img.set_pixel(x, y, NEEDLE[level])
	return [img, _shadow(def, size.x)]


## Ombre portée : ellipse vers le bas à droite, une seule couleur à 35 % d'opacité.
func _shadow(def: Dictionary, width: int) -> Image:
	var img := Image.create(width, 32, false, Image.FORMAT_RGBA8)
	var s: Array = def["shadow"]
	var oy: int = 16 - (int(def["pivot"][1]) - int(s[1]))
	for y in 32:
		for x in width:
			if pow((x - s[0]) / float(s[2]), 2) + pow((y - oy) / float(s[3]), 2) <= 1.0:
				img.set_pixel(x, y, SHADOW)
	return img


## Petite touffe de feuilles (une couleur, un point plus marqué au centre).
func _leaf_mark(img: Image, x: int, y: int, main: Color, center: Color) -> void:
	for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
		var p := Vector2i(x, y) + d
		if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and img.get_pixel(p.x, p.y).a > 0.0:
			img.set_pixel(p.x, p.y, center if d == Vector2i.ZERO else main)


func _stamp(img: Image, rows: Array, ox: int, oy: int) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != ".":
				img.set_pixel(ox + x, oy + y, INK[row[x]])


func _leaf(x: int, y: int) -> int:
	var c: String = LEAF_PATTERN[y % LEAF_PATTERN.size()][x % 8]
	return 1 if c == "+" else (-1 if c == "-" else 0)


func _needle(x: int, y: int, side: float) -> int:
	var c: String = NEEDLE_PATTERN[y % 4][x % 4]
	if c == "+" and side < 0.25:
		return 1
	if c == "-":
		return -1
	return 0


## Contrôle : toute couleur (opacité mise à part) doit appartenir à la palette du projet.
func _check_palette(img: Image) -> void:
	var allowed := {}
	for line in FileAccess.get_file_as_string(OUT + "palette.gpl").split("\n"):
		var parts := line.strip_edges().split_floats(" ", false)
		if parts.size() >= 3 and not line.begins_with("#") and line.strip_edges()[0].is_valid_int():
			allowed[Color8(int(parts[0]), int(parts[1]), int(parts[2])).to_html(false)] = true
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and not allowed.has(c.to_html(false)):
				push_error("draw_nature : couleur hors palette en (%d, %d) : %s" % [x, y, c.to_html(false)])
				return
	print("draw_nature : toutes les couleurs appartiennent à la palette")
