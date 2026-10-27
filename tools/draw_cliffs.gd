extends SceneTree
## Voie C, étape 6 (docs/TILESET_SPEC.md, section 7) : falaises, escalier et rebords du plateau témoin.
## Comme aux étapes précédentes, tout est placé à la main : tracé ondulé de chaque strate et de chaque
## lèvre (points de passage), joints entre les blocs, silhouettes des coins, marches, petits motifs
## (mousse, lierre, racine, éboulis) écrits pixel par pixel. Le calcul se limite à l'éclairage (en haut
## à gauche) : arête claire sous chaque fissure, bas de bloc plus sombre, bord gauche éclairé.
## Usage : godot --headless --path . --script res://tools/draw_cliffs.gd, puis --import.
##
## Sortie : assets/art/tiles/cliffs.png, planche de 8 x 4 tuiles de 32 px (positions dans ZoneTemoin.CLIFF_*).
## - rangée 0 : face haute (sous le plateau, avec la lèvre d'herbe) 3 variantes, coin saillant gauche et
##   droit, coin rentrant gauche et droit (calques posés sur une face) ;
## - rangée 1 : la même chose pour la face basse (pied, éboulis) ;
## - rangée 2 : escalier haut et bas, joues gauche et droite (haut, bas), ombre au pied de la face ;
## - rangée 3 : rebords vus de dessus, ouest, est et nord, 2 variantes chacun.
## Raccords : chaque strate coupe les bords gauche et droit d'une tuile à la même hauteur, quelle que soit
## la variante ; aucun joint ne touche ces bords. Les variantes se posent donc dans n'importe quel ordre.

const OUT := "res://assets/art/tiles/"
const T := 32

## Couleurs de la palette : roche 1 (sombre) à 6 (claire), herbe k a g b c d, feuillage e F f, bois T U V.
const INK := {
	"1": Color8(58, 53, 64), "2": Color8(82, 74, 82), "3": Color8(109, 100, 102),
	"4": Color8(139, 130, 124), "5": Color8(173, 162, 150), "6": Color8(207, 196, 178),
	"k": Color8(47, 79, 44), "a": Color8(62, 106, 53), "g": Color8(82, 127, 61),
	"b": Color8(107, 150, 72), "c": Color8(143, 174, 88), "d": Color8(184, 196, 110),
	"e": Color8(63, 109, 60), "F": Color8(45, 82, 54), "f": Color8(94, 138, 68),
	"T": Color8(59, 42, 34), "U": Color8(90, 63, 44),
}
const ROCK := ["1", "2", "3", "4", "5", "6"]
const SHADOW := Color(26 / 255.0, 26 / 255.0, 46 / 255.0, 0.35)

## Face de falaise : une colonne de 64 px (face haute 0-31, face basse 32-63). Hauteur, aux bords de la
## tuile, du bas de la lèvre, des quatre fissures et du pied de la roche.
const FACE_LINES := [4, 13, 24, 37, 49, 60]
## Teinte de base de chaque strate (indice dans ROCK) : plus sombre vers le pied.
const STRATA_BASE := [3, 3, 2, 2, 2]
## Tracé de chaque ligne, par variante : points de passage [x, décalage], reliés en ligne droite.
const FACE_WAVES := [
	[
		[[0, 0], [3, 1], [6, 0], [9, 2], [11, 3], [13, 1], [17, 0], [21, 1], [24, 3], [26, 1], [31, 0]],
		[[0, 0], [7, 1], [15, 1], [22, -1], [31, 0]],
		[[0, 0], [5, -1], [12, 0], [19, 2], [26, 1], [31, 0]],
		[[0, 0], [10, -2], [18, -1], [25, 1], [31, 0]],
		[[0, 0], [6, 1], [14, 2], [23, 0], [31, 0]],
		[[0, 0], [4, -1], [9, 1], [15, 0], [20, -2], [26, 0], [31, 0]],
	],
	[
		[[0, 0], [4, 2], [7, 1], [12, 0], [15, 2], [16, 4], [18, 1], [23, 0], [28, 2], [31, 0]],
		[[0, 0], [6, -1], [13, 0], [20, 2], [27, 1], [31, 0]],
		[[0, 0], [8, 2], [16, 1], [24, -1], [31, 0]],
		[[0, 0], [5, 1], [13, 2], [21, 0], [27, -1], [31, 0]],
		[[0, 0], [9, -1], [17, -2], [24, 0], [31, 0]],
		[[0, 0], [6, 1], [11, -1], [17, 1], [23, 2], [28, 0], [31, 0]],
	],
	[
		[[0, 0], [2, 1], [5, 3], [7, 1], [12, 1], [19, 0], [22, 2], [24, 4], [26, 2], [31, 0]],
		[[0, 0], [9, 2], [17, 0], [25, -1], [31, 0]],
		[[0, 0], [7, 1], [14, -1], [22, 0], [28, 1], [31, 0]],
		[[0, 0], [6, -1], [15, 1], [23, 2], [31, 0]],
		[[0, 0], [5, 0], [12, -1], [20, 1], [27, 1], [31, 0]],
		[[0, 0], [5, -2], [10, 0], [16, 1], [22, -1], [27, 1], [31, 0]],
	],
]
## Fractures, par variante et par strate : [x en haut, x en bas, début, fin] (début et fin en fraction de
## la hauteur de la strate). Une fracture complète (0 à 1) sépare deux blocs ; une fracture partielle
## n'est qu'une fente. Dans la strate 2, qui traverse la limite entre face haute et face basse (choisies
## séparément), les fentes s'arrêtent avant cette limite.
const FACE_JOINTS := [
	[[[11, 8, 0.0, 1.0]], [[7, 9, 0.0, 1.0], [20, 18, 0.0, 0.6]], [[16, 15, 0.0, 0.45]], [[9, 12, 0.0, 1.0], [24, 22, 0.3, 1.0]], [[5, 7, 0.0, 1.0], [18, 16, 0.0, 0.7]]],
	[[[18, 20, 0.0, 1.0]], [[9, 8, 0.0, 1.0], [24, 25, 0.4, 1.0]], [[22, 23, 0.0, 0.5], [8, 9, 0.7, 1.0]], [[15, 13, 0.0, 1.0]], [[10, 12, 0.0, 1.0], [25, 24, 0.3, 1.0]]],
	[[[8, 7, 0.0, 1.0], [25, 24, 0.0, 0.6]], [[16, 18, 0.0, 1.0]], [[6, 7, 0.7, 1.0]], [[6, 5, 0.0, 0.6], [20, 22, 0.0, 1.0]], [[13, 12, 0.0, 1.0]]],
]
## Passages où une fissure entre strates s'estompe ([x début, x fin], jamais aux bords), par variante et
## par fissure (1 à 4) : les strates ne sont pas tirées au cordeau.
const FACE_GAPS := [
	[[[13, 17]], [[3, 6], [22, 25]], [[15, 19]], [[26, 29]]],
	[[[2, 5], [20, 23]], [[12, 15]], [[24, 27]], [[5, 8]]],
	[[[10, 13]], [[18, 22]], [[2, 5]], [[20, 24]]],
]
## Blocs en retrait, plus sombres et sans arête éclairée (strate, numéro du bloc depuis la gauche) ;
## jamais le premier ni le dernier, qui touchent les bords de la tuile.
const FACE_DARK := [[[1, 1], [3, 1]], [[0, 1], [4, 1]], [[1, 1], [3, 1]]]

## Petits motifs, posés à la main (« . » : rien).
const STAMPS := {
	"moss": [".ag.", "agga", ".a.."],
	"crack": ["2..", "12.", ".1.", ".12", "..1"],
	"ivy": ["..e..", ".eFe.", "..F..", "..Fe.", ".eF..", "..F..", "..Ff.", ".fF..", "..F..", "..e..", ".eF..", "..F..", "..e.."],
	"root": ["TU...", ".TU..", "..TT.", "...TU", "....T"],
	"tuft": ["c.b.c", ".bgb.", "agaga"],
	"boulder": [".3443.", "345543", "344443", "233332", ".2222."],
	"pebbles": ["45...", "33...", "....4", "...43"],
	"scree": ["...45...", "..3443..", ".33.234.", "2332.333"],
}
## Motifs de chaque variante : [motif, x, y], pour la face haute puis la face basse.
const FACE_STAMPS_TOP := [[["crack", 8, 16], ["moss", 19, 21]], [["ivy", 14, 3], ["crack", 24, 15]], [["tuft", 6, 10], ["root", 18, 22]]]
const FACE_STAMPS_BOTTOM := [[["crack", 9, 10], ["scree", 20, 25]], [["moss", 22, 8], ["boulder", 6, 25]], [["tuft", 14, 26], ["pebbles", 25, 26]]]

## Coins saillants : première colonne de roche à chaque rangée (face haute, face basse), côté gauche ;
## le côté droit est son miroir. La lèvre s'arrondit en haut, le pied rentre en bas.
const EDGE_TOP := [9, 6, 5, 4, 3, 3, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 2, 2, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2]
const EDGE_BOTTOM := [2, 2, 2, 2, 2, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 5, 6, 7, 9, 11, 14]
## Coin rentrant gauche : largeur de l'ombre portée par le relief voisin (face haute, face basse).
const NOOK_TOP := [[0, 6], [8, 7], [16, 6], [24, 8], [31, 8]]
const NOOK_BOTTOM := [[0, 8], [9, 9], [18, 8], [26, 10], [31, 9]]
## Ombre au pied de la face : profondeur (px) le long de la tuile, 7 aux deux bords.
const FOOT_SHADOW := [[0, 7], [5, 8], [10, 6], [16, 7], [22, 9], [27, 7], [31, 7]]

## Escalier : une colonne de 64 px. Haut de chaque marche (palier de 3 px, puis contremarche), puis le sol.
const STEPS := [3, 11, 18, 26, 34, 41, 49]
const STEP_FLOOR := 57
## Tracé du nez de chaque marche (décalage), le même aux deux bords pour que l'escalier de deux cases raccorde.
const STEP_WAVES := [
	[[0, 0], [9, 1], [20, 0], [26, -1], [31, 0]],
	[[0, 0], [6, -1], [15, 0], [24, 1], [31, 0]],
	[[0, 0], [11, 1], [19, 1], [31, 0]],
	[[0, 0], [5, 0], [13, -1], [22, 0], [31, 0]],
	[[0, 0], [8, 1], [17, 0], [25, 1], [31, 0]],
	[[0, 0], [12, -1], [21, 0], [31, 0]],
	[[0, 0], [7, 1], [16, 1], [27, 0], [31, 0]],
]
const STAIR_STAMPS := [["crack", 21, 13], ["crack", 7, 37], ["pebbles", 9, 58], ["pebbles", 22, 59]]

## Rebords vus de dessus : largeur de l'arête rocheuse le long du bord, et joints entre pierres
## (position le long du bord), par variante. Aux deux extrémités, 5 px : les rebords se raccordent.
const RIM_WIDTH := [
	[[0, 5], [6, 6], [13, 4], [19, 5], [25, 6], [31, 5]],
	[[0, 5], [8, 4], [14, 6], [22, 5], [27, 4], [31, 5]],
]
const RIM_JOINTS := [[7, 15, 24], [4, 12, 21, 28]]


func _init() -> void:
	for rows: Array in STAMPS.values():
		for row: String in rows:
			assert(row.length() == rows[0].length(), "draw_cliffs : lignes de longueurs différentes")
	var sheet := Image.create(8 * T, 4 * T, false, Image.FORMAT_RGBA8)
	for v in 3:
		var column := _face(v)
		_stamps(column, FACE_STAMPS_TOP[v], 0)
		_stamps(column, FACE_STAMPS_BOTTOM[v], T)
		sheet.blit_rect(column, Rect2i(0, 0, T, T), Vector2i(v * T, 0))
		sheet.blit_rect(column, Rect2i(0, T, T, T), Vector2i(v * T, T))
	# Coins saillants : variante 0 découpée selon la silhouette du coin, avec son arête.
	var plain := _face(0)
	_stamps(plain, FACE_STAMPS_TOP[0], 0)
	_stamps(plain, FACE_STAMPS_BOTTOM[0], T)
	for half in 2:
		var src := plain.get_region(Rect2i(0, half * T, T, T))
		sheet.blit_rect(_corner(src, half == 0, false), Rect2i(0, 0, T, T), Vector2i(3 * T, half * T))
		sheet.blit_rect(_corner(src, half == 0, true), Rect2i(0, 0, T, T), Vector2i(4 * T, half * T))
		sheet.blit_rect(_nook(half == 0, false), Rect2i(0, 0, T, T), Vector2i(5 * T, half * T))
		sheet.blit_rect(_nook(half == 0, true), Rect2i(0, 0, T, T), Vector2i(6 * T, half * T))
	var stairs := _stairs()
	sheet.blit_rect(stairs, Rect2i(0, 0, T, 2 * T), Vector2i(0, 2 * T))
	sheet.blit_rect(stairs.get_region(Rect2i(0, T, T, T)), Rect2i(0, 0, T, T), Vector2i(T, 2 * T))
	for half in 2:
		sheet.blit_rect(_cheek(half == 0, false), Rect2i(0, 0, T, T), Vector2i((2 + half * 2) * T, 2 * T))
		sheet.blit_rect(_cheek(half == 0, true), Rect2i(0, 0, T, T), Vector2i((3 + half * 2) * T, 2 * T))
	sheet.blit_rect(_foot_shadow(), Rect2i(0, 0, T, T), Vector2i(6 * T, 2 * T))
	for side in 3:
		for v in 2:
			sheet.blit_rect(_rim(side, v), Rect2i(0, 0, T, T), Vector2i((side * 2 + v) * T, 3 * T))
	_check_palette(sheet)
	sheet.save_png(OUT + "cliffs.png")
	print("draw_cliffs : cliffs.png (%d x %d)" % [sheet.get_width(), sheet.get_height()])
	quit()


## Colonne de face (32 x 64) d'une variante : lèvre d'herbe, strates et blocs éclairés, pied et ombre.
func _face(v: int) -> Image:
	var img := Image.create(T, 2 * T, false, Image.FORMAT_RGBA8)
	for x in T:
		var lines: Array[int] = []
		for i in FACE_LINES.size():
			lines.append(FACE_LINES[i] + _wave(FACE_WAVES[v][i], x))
		for y in 2 * T:
			var col: Variant = null
			if y < lines[0]:
				# Lèvre : bord du plateau qui déborde ; dessus éclairé, dessous sombre.
				col = INK["b"] if y < 2 else (INK["a"] if y == lines[0] - 1 else INK["g"])
				if y == lines[0] - 1 and lines[0] - FACE_LINES[0] >= 2:
					col = INK["k"]
			elif y > lines[5]:
				col = SHADOW
			elif y == lines[5]:
				col = INK["1"]
			else:
				col = _rock(v, x, y, lines)
			if col != null:
				img.set_pixel(x, y, col)
	return img


## Roche à (x, y) : strate, bloc (entre deux joints), puis éclairage de la lumière en haut à gauche.
func _rock(v: int, x: int, y: int, lines: Array[int]) -> Color:
	var s := 0
	while s < 4 and y >= lines[s + 1]:
		s += 1
	var top: int = lines[s]
	var bottom: int = lines[s + 1]
	# Fissure entre deux strates, estompée par endroits.
	if s > 0 and y == top:
		for g: Array in FACE_GAPS[v][s - 1]:
			if x >= g[0] and x <= g[1]:
				return INK[ROCK[STRATA_BASE[s] - 1]]
		return INK[ROCK[STRATA_BASE[s] - 2]]
	var t := float(y - top) / maxf(bottom - top, 1)
	# Fractures : celles qui traversent la strate délimitent les blocs ; les autres ne sont que des fentes.
	var block := 0
	var last_joint := -100
	var next_joint := 100
	for j: Array in FACE_JOINTS[v][s]:
		var jx := roundi(lerpf(j[0], j[1], t))
		var full: bool = j[2] == 0.0 and j[3] == 1.0
		if x == jx and t >= j[2] and t <= j[3]:
			return INK[ROCK[STRATA_BASE[s] - 2]]
		if x == jx + 1 and t >= j[2] and t <= j[3]:
			return INK[ROCK[mini(STRATA_BASE[s] + 1, 5)]]
		if full and x > jx:
			block += 1
			last_joint = maxi(last_joint, jx)
		elif full and x < jx:
			next_joint = mini(next_joint, jx)
	var base: int = STRATA_BASE[s]
	var recessed := false
	for d: Array in FACE_DARK[v]:
		if d[0] == s and d[1] == block:
			base -= 1
			recessed = true
	if s == 0 and y <= top + 1:
		# Sous la lèvre : ombre du débord d'herbe.
		return INK[ROCK[base - 1]] if y == top else INK[ROCK[base]]
	if y == top + 1 and not recessed:
		# Arête du bloc, éclairée sur sa partie gauche (lumière venue de la gauche), plus vive au coin.
		var width := next_joint - last_joint
		if x - last_joint <= maxi(4, roundi(width * 0.6)):
			return INK[ROCK[mini(base + (2 if x - last_joint <= 3 and base >= 3 else 1), 5)]]
	if y >= bottom - 1 or (s == 4 and y >= bottom - 3):
		return INK[ROCK[base - 1]]
	if x == next_joint - 1:
		return INK[ROCK[base - 1]]
	return INK[ROCK[base]]


## Coin saillant (silhouette EDGE_*) : arête claire à gauche, sombre à droite ; au-delà, transparent.
func _corner(src: Image, top: bool, right: bool) -> Image:
	var img := src.duplicate() as Image
	var edge: Array = EDGE_TOP if top else EDGE_BOTTOM
	for y in T:
		var e: int = edge[y]
		for x in T:
			var d := (T - 1 - x) if right else x
			if d < e:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif d == e:
				var c := img.get_pixel(x, y)
				if c.a < 1.0:
					continue
				var grass := c in [INK["k"], INK["a"], INK["g"], INK["b"]]
				img.set_pixel(x, y, (INK["a"] if right else INK["b"]) if grass else (INK["2"] if right else INK["5"]))
			elif d == e + 1 and right:
				var c := img.get_pixel(x, y)
				if c in [INK["4"], INK["5"], INK["6"]]:
					img.set_pixel(x, y, INK["3"])
	# Ombre portée au sol sous un coin, et éboulis au pied du coin.
	if not top:
		for y in range(28, T):
			for x in T:
				var d := (T - 1 - x) if right else x
				if d < edge[y] and d >= edge[y] - 3 and img.get_pixel(x, y).a == 0.0:
					img.set_pixel(x, y, SHADOW)
		var stone: Array = STAMPS["pebbles"]
		_stamp(img, stone, 23 if right else 2, 27)
	return img


## Coin rentrant : à gauche, ombre portée par le relief voisin, plus avancé ; à droite, simple joint sombre.
func _nook(top: bool, right: bool) -> Image:
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for y in T:
		if right:
			img.set_pixel(T - 1, y, INK["1"])
			img.set_pixel(T - 2, y, INK["2"])
			continue
		img.set_pixel(0, y, INK["1"])
		for x in range(1, _wave(NOOK_TOP if top else NOOK_BOTTOM, y)):
			img.set_pixel(x, y, SHADOW)
	return img


## Escalier taillé dans la roche (32 x 64) : herbe en haut, marches (palier clair, nez plus clair au
## centre usé, contremarche sombre ; sans blanc, pour rester moins vif que les personnages), puis le sol (transparent : la terre du chemin est dessous).
func _stairs() -> Image:
	var img := Image.create(T, 2 * T, false, Image.FORMAT_RGBA8)
	for x in T:
		for y in 2 * T:
			var col: Variant = null
			if y < 3:
				col = [INK["b"], INK["g"], INK["a"]][y]
			elif y < STEP_FLOOR:
				var k := STEPS.size() - 1
				while k > 0 and y < STEPS[k] + _wave(STEP_WAVES[k], x):
					k -= 1
				var d: int = y - STEPS[k] - _wave(STEP_WAVES[k], x)
				if d < 0:
					col = INK["3"]
				elif d <= 1:
					col = INK["4"]
				elif d == 2:
					col = INK["5"] if x >= 8 and x <= 23 else INK["4"]
				elif d == 3:
					col = INK["2"]
				else:
					col = INK["3"]
			elif y == STEP_FLOOR:
				col = INK["2"]
			elif y == STEP_FLOOR + 1:
				col = SHADOW
			if col != null:
				img.set_pixel(x, y, col)
	for s: Array in STAIR_STAMPS:
		_stamp(img, STAMPS[s[0]], s[1], s[2])
	return img


## Joue de l'escalier (bord de roche le long des marches) : à gauche, côté ombre, elle porte son ombre
## sur les marches ; à droite, côté lumière. Mêmes fissures que les faces voisines.
func _cheek(top: bool, right: bool) -> Image:
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	var cracks := [13, 24] if top else [5, 17]
	for y in T:
		var width := 6 if top or y < 24 else 6 - (y - 23) / 2
		if width <= 0:
			continue
		for d in width:
			var col: Color
			if top and y < 3:
				col = [INK["b"], INK["g"], INK["a"]][y]
			elif y in cracks:
				col = INK["2"]
			elif d == width - 1:
				col = INK["5"] if right else INK["1"]
			elif d == width - 2:
				col = INK["4"] if right else INK["2"]
			elif d == 0:
				col = INK["2"] if right else INK["4"]
			else:
				col = INK["3"]
			img.set_pixel((T - 1 - d) if right else d, y, col)
		if not right and (not top or y >= 3):
			for x in range(width, width + 3):
				img.set_pixel(x, y, SHADOW)
	return img


func _foot_shadow() -> Image:
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for x in T:
		for y in _wave(FOOT_SHADOW, x):
			img.set_pixel(x, y, SHADOW)
	return img


## Rebord vu de dessus (0 : ouest, 1 : est, 2 : nord) : arête de pierres le long du bord, dessus éclairé
## côté lumière, sombre côté ombre ; joints entre pierres ; herbe plus sombre là où elle touche la roche.
func _rim(side: int, v: int) -> Image:
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for along in T:
		var width := _wave(RIM_WIDTH[v], along)
		for d in width + 1:
			var col: Color
			if d == width:
				col = INK["a"]
			elif along in RIM_JOINTS[v] and d > 0:
				col = INK["2"]
			elif side == 1:
				col = [INK["2"], INK["3"], INK["4"], INK["3"], INK["3"], INK["2"]][mini(d, 5)]
			else:
				col = [INK["4"], INK["5"], INK["4"], INK["4"], INK["3"], INK["2"]][mini(d, 5)]
			if d == width - 1 and d > 1:
				col = INK["2"]
			match side:
				0: img.set_pixel(d, along, col)
				1: img.set_pixel(T - 1 - d, along, col)
				2: img.set_pixel(along, d, col)
	return img


func _stamps(img: Image, list: Array, oy: int) -> void:
	for s: Array in list:
		_stamp(img, STAMPS[s[0]], s[1], s[2] + oy)


func _stamp(img: Image, rows: Array, ox: int, oy: int) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch != "." and ox + x < img.get_width() and oy + y < img.get_height():
				img.set_pixel(ox + x, oy + y, INK[ch])


## Valeur du tracé à `x` : points de passage reliés en ligne droite.
func _wave(points: Array, x: int) -> int:
	for i in points.size() - 1:
		var a: Array = points[i]
		var b: Array = points[i + 1]
		if x <= b[0]:
			return roundi(lerpf(a[1], b[1], float(x - a[0]) / maxf(b[0] - a[0], 1)))
	return points[points.size() - 1][1]


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
				push_error("draw_cliffs : couleur hors palette en (%d, %d) : %s" % [x, y, c.to_html(false)])
				return
	print("draw_cliffs : toutes les couleurs appartiennent à la palette")
