extends SceneTree
## Génère toutes les textures pixel art provisoires du prototype (dessin procédural original).
## Usage : godot --headless --path . --script res://tools/generate_art.gd
## Le résultat est déterministe : relancer reproduit exactement les mêmes images.

const Ids := preload("res://scripts/world/tile_ids.gd")
const T := 32
const OUT := "res://assets/art/"

# --- Palette -------------------------------------------------------------
const G_DARK := Color8(62, 122, 52)
const G_MID := Color8(92, 156, 64)
const G_MID2 := Color8(88, 151, 62)
const G_LIGHT := Color8(122, 184, 76)
const G_HI := Color8(162, 208, 98)

const F_DARK := Color8(22, 48, 32)
const F_MID := Color8(46, 92, 50)

const D_DARK := Color8(124, 84, 50)
const D_MID := Color8(178, 128, 78)
const D_MID2 := Color8(164, 116, 70)
const D_LIGHT := Color8(206, 160, 104)
const D_PEBBLE := Color8(152, 142, 130)

const S_DARK := Color8(206, 178, 118)
const S_MID := Color8(228, 204, 144)
const S_LIGHT := Color8(242, 224, 174)

const M_BANK := Color8(128, 100, 64)
const M_BANK_DARK := Color8(92, 70, 46)

const W_FOAM := Color8(206, 236, 240)
const W_LIGHT := Color8(104, 178, 214)
const W_MID := Color8(66, 140, 194)
const W_DEEP := Color8(46, 104, 166)
const W_RIPPLE := Color8(78, 140, 196)

const R_OUT := Color8(44, 36, 42)
const R_DARK := Color8(76, 66, 70)
const R_MID := Color8(118, 106, 102)
const R_LIGHT := Color8(152, 138, 128)
const R_HI := Color8(186, 174, 158)
const MOSS := Color8(108, 150, 70)

const WD_DARK := Color8(84, 52, 32)
const WD_MID := Color8(128, 84, 48)
const WD_LIGHT := Color8(168, 118, 70)
const WD_HI := Color8(198, 152, 98)
const WD_END := Color8(216, 174, 116)

const ST_DARK := Color8(148, 102, 46)
const ST_MID := Color8(204, 156, 72)
const ST_LIGHT := Color8(232, 196, 110)

const L_OUT := Color8(22, 48, 32)
const LEAVES := [
	[Color8(40, 92, 52), Color8(62, 128, 62), Color8(96, 164, 72), Color8(146, 200, 94)],
	[Color8(70, 104, 44), Color8(110, 146, 56), Color8(150, 182, 70), Color8(196, 214, 104)],
	[Color8(34, 84, 58), Color8(52, 116, 70), Color8(82, 152, 84), Color8(130, 190, 104)],
]
const PINE := [Color8(26, 70, 56), Color8(40, 100, 70), Color8(66, 136, 82), Color8(108, 168, 98)]

const OUTLINE := Color8(38, 22, 18)
const SHADOW := Color(0.06, 0.04, 0.08, 0.28)
const HERO_COLORS := {
	"h": Color8(78, 46, 30), "H": Color8(118, 74, 42),
	"s": Color8(234, 172, 126), "S": Color8(194, 122, 86), "e": Color8(30, 18, 16),
	"f": Color8(170, 110, 62), "F": Color8(124, 76, 42), "g": Color8(204, 148, 90),
	"r": Color8(216, 190, 122), "k": Color8(112, 74, 46),
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_gen_terrain()
	_gen_autotiles()
	_gen_hero()
	_gen_props()
	_gen_fx()
	_gen_combat()
	print("generate_art: OK")
	quit()


# --- Outils --------------------------------------------------------------

static func _h(x: int, y: int, s: int = 0) -> float:
	var n := (x * 73856093) ^ (y * 19349663) ^ (s * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFF) / 65535.0


## Ondulation périodique (période 32) des bords d'auto-tuiles : raccord parfait d'une tuile à l'autre.
static func _wob(t: int, side: int) -> float:
	return roundf(1.1 * sin(TAU * t / 32.0 * 2.0 + side * 1.7) + 0.7 * sin(TAU * t / 32.0 * 5.0 + side * 0.9))


func _img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


func _save(img: Image, file: String) -> void:
	var err := img.save_png(OUT + file)
	if err != OK:
		push_error("Échec d'écriture %s (%d)" % [file, err])


## Contour 4-voisins autour des pixels opaques.
func _outline(img: Image, col: Color) -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and src.get_pixelv(p).a > 0.5:
					img.set_pixel(x, y, col)
					break


## Ombre portée elliptique, posée seulement sur les pixels vides.
func _ground_shadow(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0 and img.get_pixel(x, y).a == 0.0:
				img.set_pixel(x, y, SHADOW)


func _grass(x: int, y: int, s: int) -> Color:
	x &= 31
	y &= 31
	var c := G_MID
	if _h(x >> 3, y >> 3, s + 11) < 0.4 and _h(x, y, s + 5) < 0.8:
		c = G_MID2
	var r := _h(x, y, s)
	if r < 0.045:
		return G_DARK
	if _h(x, (y + 1) & 31, s) < 0.045:
		return G_LIGHT
	if r > 0.978:
		return G_HI
	return c


# --- Terrain : tuiles uniques ---------------------------------------------

func _gen_terrain() -> void:
	var img := _img(T * 8, T * 4)
	for i in 4:
		_tile_fill(img, Ids.GRASS[i], func(x, y): return _grass(x, y, i))
	for i in 3:
		var at: Vector2i = Ids.GRASS_FLOWERS[i]
		_tile_fill(img, at, func(x, y): return _grass(x, y, i))
		_flowers(img, at * T, 20 + i)
	for i in Ids.GRASS_DETAIL.size():
		var at: Vector2i = Ids.GRASS_DETAIL[i]
		_tile_fill(img, at, func(x, y): return _grass(x, y, i + 1))
		_grass_detail(img, at * T, i)
	for v in 4:
		_face(img, Vector2i(Ids.FACE_TOP_COL + v, Ids.FACE_TOP_ROW) * T, true, v & 1, v & 2)
		_face(img, Vector2i(Ids.FACE_BOTTOM_COL + v, Ids.FACE_TOP_ROW) * T, false, v & 1, v & 2)
	_stairs(img, Ids.STAIRS_TOP * T, true)
	_stairs(img, Ids.STAIRS_BOTTOM * T, false)
	_cliff_shadow(img, Ids.CLIFF_SHADOW * T)
	_lily(img, Ids.LILY_PADS[0] * T, false)
	_lily(img, Ids.LILY_PADS[1] * T, true)
	for rails in 4:
		_bridge(img, Vector2i(rails, Ids.BRIDGE_ROW) * T, rails, false)
		_bridge(img, Vector2i(4 + rails, Ids.BRIDGE_ROW) * T, rails, true)
	_save(img, "terrain.png")


func _tile_fill(img: Image, at: Vector2i, fn: Callable) -> void:
	for y in T:
		for x in T:
			img.set_pixel(at.x * T + x, at.y * T + y, fn.call(x, y))


func _flowers(img: Image, o: Vector2i, s: int) -> void:
	var colors := [Color8(250, 246, 230), Color8(246, 214, 92), Color8(234, 134, 164), Color8(150, 172, 240)]
	for i in 6:
		var fx := 3 + int(_h(i, s, 41) * 26)
		var fy := 3 + int(_h(s, i, 43) * 26)
		var col: Color = colors[int(_h(i, i, s + 47) * 4.0) % 4]
		img.set_pixel(o.x + fx, o.y + fy + 1, G_DARK)
		for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]:
			img.set_pixelv(o + Vector2i(fx, fy) + d, col)
		img.set_pixel(o.x + fx, o.y + fy, Color8(250, 222, 120) if col != colors[1] else Color8(214, 120, 60))


## Touffes d'herbe haute (variantes 0 et 1) ou petits cailloux (variante 2).
func _grass_detail(img: Image, o: Vector2i, v: int) -> void:
	for i in 3 if v < 2 else 4:
		var p := o + Vector2i(5 + int(_h(i, v, 44) * 22.0), 6 + int(_h(v, i, 45) * 20.0))
		if v < 2:
			for b in [[-2, 2], [-1, 3], [0, 4], [1, 3], [2, 2]]:
				for k in b[1]:
					img.set_pixelv(p + Vector2i(b[0], -k), G_DARK if k == 0 else (G_LIGHT if k == b[1] - 1 else G_MID2))
			img.set_pixelv(p + Vector2i(0, -4), G_HI)
		else:
			img.set_pixelv(p, R_LIGHT)
			img.set_pixelv(p + Vector2i(1, 0), R_MID)
			img.set_pixelv(p + Vector2i(0, 1), R_DARK)
			img.set_pixelv(p + Vector2i(1, 1), G_DARK)


## Paroi rocheuse : blocs irréguliers allongés (Voronoï périodique 32 x 64), éclairés en haut à gauche.
func _rock_face(x: int, gy: int) -> Color:
	var best := 1e9
	var second := 1e9
	var center := Vector2.ZERO
	var cell_id := 0
	for gx in range((x >> 3) - 1, (x >> 3) + 2):
		for gr in range((gy >> 4) - 1, (gy >> 4) + 2):
			var ix := posmod(gx, 4)
			var iy := posmod(gr, 4)
			var cx := gx * 8 + 4 + (_h(ix, iy, 90) - 0.5) * 6.0
			var cy := gr * 16 + 8 + (_h(iy, ix, 91) - 0.5) * 10.0
			var d := Vector2(x + 0.5 - cx, (gy + 0.5 - cy) * 0.55).length()
			if d < best:
				second = best
				best = d
				center = Vector2(cx, cy)
				cell_id = ix * 4 + iy
			elif d < second:
				second = d
	if second - best < 0.9:
		return R_OUT if second - best < 0.4 else R_DARK
	var t := ((x + 0.5 - center.x) * 0.9 + (gy + 0.5 - center.y) * 0.35) / 5.0 + (_h(x, gy, 92) - 0.5) * 0.3
	var c := R_MID
	if t < -0.55:
		c = R_HI
	elif t < -0.05:
		c = R_LIGHT
	elif t > 0.6:
		c = R_DARK
	return c.lerp(Color8(138, 112, 90), _h(cell_id, 0, 93) * 0.35)


func _face(img: Image, o: Vector2i, top: bool, lend: int, rend: int) -> void:
	for y in T:
		for x in T:
			var gy := y + (0 if top else T)
			var c := _rock_face(x, gy)
			# Assombrissement progressif vers le pied de la falaise.
			c = c.lerp(R_DARK, clampf(gy / 64.0, 0.0, 1.0) * 0.35)
			if top:
				var drip := int(_h(x, 0, 77) * 3.0) + (6 if _h(x, 1, 78) < 0.1 else 0)
				if y < 2 + drip:
					c = _highland(G_DARK if (y > 1 or _h(x, y, 79) < 0.3) else G_MID)
				elif y == 2 + drip:
					c = R_OUT
			else:
				if y >= 29:
					c = R_DARK if y < 31 else R_OUT
			if lend:
				if x == 0:
					c = R_OUT
				elif x <= 2 and (not top or y > 2):
					c = R_HI if x == 1 else R_LIGHT
			if rend:
				if x == 31:
					c = R_OUT
				elif x >= 29:
					c = R_DARK
			img.set_pixel(o.x + x, o.y + y, c)


func _stairs(img: Image, o: Vector2i, top: bool) -> void:
	for y in T:
		for x in T:
			var c: Color
			if x == 0 or x == 31:
				c = R_OUT
			elif x < 4 or x > 27:
				c = R_MID if _h(x, y, 5) > 0.2 else R_DARK
				if x == 1:
					c = R_LIGHT
			else:
				var step := (y + (0 if top else T)) % 8
				c = [R_HI, R_LIGHT, R_LIGHT, R_LIGHT, R_MID, R_MID, R_DARK, R_OUT][step]
				if step < 4 and _h(x, y, 6) < 0.07:
					c = R_MID
			img.set_pixel(o.x + x, o.y + y, c)


func _cliff_shadow(img: Image, o: Vector2i) -> void:
	for y in 7:
		for x in T:
			var a: float = [0.34, 0.3, 0.24, 0.18, 0.12, 0.08, 0.04][y]
			if y >= 4 and (x + y) % 2 == 0:
				continue
			img.set_pixel(o.x + x, o.y + y, Color(0.06, 0.04, 0.1, a))


func _lily(img: Image, o: Vector2i, flower: bool) -> void:
	var pads := [Vector3(10, 12, 5), Vector3(21, 20, 4), Vector3(12, 24, 3)]
	for p in pads:
		for y in range(-5, 6):
			for x in range(-6, 7):
				var dx: float = x / p.z
				var dy: float = y / (p.z * 0.7)
				var dd := dx * dx + dy * dy
				if dd > 1.0:
					continue
				# Encoche en V de la feuille.
				if x > 0 and absf(y) < x * 0.4:
					continue
				var c := Color8(76, 150, 72)
				if dd > 0.6:
					c = Color8(48, 112, 58)
				elif y < 0 and x < 0:
					c = Color8(112, 182, 92)
				img.set_pixel(o.x + int(p.x) + x, o.y + int(p.y) + y, c)
	if flower:
		var f := Vector2i(o.x + 10, o.y + 11)
		for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 0)]:
			img.set_pixelv(f + d, Color8(244, 170, 196))
		img.set_pixelv(f + Vector2i(0, -1), Color8(252, 226, 236))


func _bridge(img: Image, o: Vector2i, rails: int, vertical: bool) -> void:
	for v in T:
		for u in T:
			# u : sens des planches (travers), v : sens de la marche. Pont horizontal : u = x.
			var board := u >> 2
			var c: Color = WD_LIGHT if _h(board, 0, 81) < 0.5 else WD_MID
			if (u & 3) == 3:
				c = WD_DARK
			elif (v == 5 or v == 26) and (u & 3) == 1:
				c = R_DARK
			elif _h(u, v, 82) < 0.05:
				c = WD_HI
			var r := -1
			if rails & 1 and v < 5:
				r = v
			elif rails & 2 and v > 26:
				r = 31 - v
			if r >= 0:
				c = [WD_DARK, WD_HI, WD_LIGHT, WD_MID, WD_DARK][r]
				if (u % 16) in [2, 3]:
					c = WD_DARK if r != 1 else WD_MID
			var x := v if vertical else u
			var y := u if vertical else v
			img.set_pixel(o.x + x, o.y + y, c)


# --- Terrain : auto-tuiles (256 masques) -----------------------------------

func _gen_autotiles() -> void:
	_auto(Ids.AUTO_FILES[Ids.Auto.PATH], 5, 14, _dirt, func(x, y, _d): return _grass(x, y, 0), D_DARK)
	_auto(Ids.AUTO_FILES[Ids.Auto.SAND], 3, 10, _sand, func(x, y, _d): return _grass(x, y, 1), S_DARK)
	_auto(Ids.AUTO_FILES[Ids.Auto.WATER], 3, 14, _water, _bank, W_FOAM)
	_auto(Ids.AUTO_FILES[Ids.Auto.FOREST], 4, 8, _forest_floor, _forest_edge, F_DARK)
	var img := _img(T * 16, T * 16)
	for mask in 256:
		_plateau(img, Ids.mask_coords(mask) * T, mask)
	_save(img, Ids.AUTO_FILES[Ids.Auto.PLATEAU])


func _auto(file: String, w: int, radius: float, inside: Callable, outside: Callable, rim: Color) -> void:
	var img := _img(T * 16, T * 16)
	for mask in 256:
		var o := Ids.mask_coords(mask) * T
		for y in T:
			for x in T:
				var d := _depth(mask, x, y, w, radius)
				var c: Color
				if d >= 1.0:
					c = inside.call(x, y, d)
				elif d >= 0.0:
					c = rim
				else:
					c = outside.call(x, y, -d)
				img.set_pixel(o.x + x, o.y + y, c)
	_save(img, file)


## Distance signée (en pixels) vers l'intérieur du terrain, selon les voisins fermés du masque.
func _depth(mask: int, x: int, y: int, w: int, r: float) -> float:
	var p := Vector2(x + 0.5, y + 0.5)
	var n := (mask & Ids.N) == 0
	var e := (mask & Ids.E) == 0
	var s := (mask & Ids.S) == 0
	var wc := (mask & Ids.W) == 0
	var d := 99.0
	if n:
		d = minf(d, p.y - w - _wob(x, 0))
	if s:
		d = minf(d, (T - p.y) - w - _wob(x, 1))
	if wc:
		d = minf(d, p.x - w - _wob(y, 2))
	if e:
		d = minf(d, (T - p.x) - w - _wob(y, 3))
	var k := w + r
	if n and wc and p.x < k and p.y < k:
		d = minf(d, r - p.distance_to(Vector2(k, k)))
	if n and e and p.x > T - k and p.y < k:
		d = minf(d, r - p.distance_to(Vector2(T - k, k)))
	if s and wc and p.x < k and p.y > T - k:
		d = minf(d, r - p.distance_to(Vector2(k, T - k)))
	if s and e and p.x > T - k and p.y > T - k:
		d = minf(d, r - p.distance_to(Vector2(T - k, T - k)))
	if not n and not e and (mask & Ids.NE) == 0:
		d = minf(d, p.distance_to(Vector2(T, 0)) - w - 1.0)
	if not n and not wc and (mask & Ids.NW) == 0:
		d = minf(d, p.distance_to(Vector2(0, 0)) - w - 1.0)
	if not s and not e and (mask & Ids.SE) == 0:
		d = minf(d, p.distance_to(Vector2(T, T)) - w - 1.0)
	if not s and not wc and (mask & Ids.SW) == 0:
		d = minf(d, p.distance_to(Vector2(0, T)) - w - 1.0)
	return d


func _dirt(x: int, y: int, d: float) -> Color:
	var c := D_MID if _h(x >> 2, y >> 2, 31) > 0.35 else D_MID2
	var r := _h(x, y, 32)
	if r < 0.025:
		return D_PEBBLE
	if _h(x, y + 1, 32) < 0.025:
		return D_LIGHT
	if r > 0.93:
		c = D_LIGHT
	elif r > 0.88:
		c = D_MID2
	if d < 2.5:
		c = c.lerp(D_DARK, 0.45)
	return c


func _sand(x: int, y: int, _d: float) -> Color:
	var r := _h(x, y, 33)
	if r < 0.08:
		return S_DARK
	if r > 0.9:
		return S_LIGHT
	return S_MID


func _water(x: int, y: int, d: float) -> Color:
	if d < 3.0:
		return W_LIGHT
	if d < 6.0:
		return W_MID if _h(x, y, 34) > 0.15 else W_LIGHT
	# Petites rides statiques ; l'animation est assurée par le shader.
	if _h(x >> 2, y, 35) < 0.05 and (x & 3) != 3:
		return W_RIPPLE
	return W_DEEP


func _bank(x: int, y: int, d: float) -> Color:
	if d < 1.5:
		return M_BANK_DARK
	if d < 3.0:
		return M_BANK
	return _grass(x, y, 0)


## Sous-bois vu d'en haut : une masse de feuillage sombre en touffes (périodique sur 32 px),
## qui comble les trouées entre les arbres de la forêt dense.
func _forest_floor(x: int, y: int, d: float) -> Color:
	var best_y := -99.0
	var col := F_DARK
	for gy in range((y >> 3) - 1, (y >> 3) + 2):
		for gx in range((x >> 3) - 1, (x >> 3) + 2):
			var cx := gx * 8 + 4 + (_h(gx & 3, gy & 3, 37) - 0.5) * 4.0
			var cy := gy * 8 + 4 + (_h(gy & 3, gx & 3, 38) - 0.5) * 4.0
			var r := 5.2 + _h(gx & 3, gy & 3, 39) * 1.6
			var dx := x + 0.5 - cx
			var dy := y + 0.5 - cy
			if dx * dx + dy * dy > r * r or cy < best_y:
				continue
			best_y = cy
			var t := (dx * 0.6 + dy * 0.8) / r
			col = Color8(66, 122, 62) if t < -0.45 else (F_MID if t < 0.35 else Color8(32, 66, 40))
	if d < 3.0 and col != F_DARK:
		col = col.lerp(F_DARK, 0.3)
	return col


func _forest_edge(x: int, y: int, d: float) -> Color:
	var c := _grass(x, y, 2)
	if d < 2.0:
		c = c.lerp(F_MID, 0.5)
	return c


func _plateau(img: Image, o: Vector2i, mask: int) -> void:
	var n := (mask & Ids.N) == 0
	var e := (mask & Ids.E) == 0
	var s := (mask & Ids.S) == 0
	var wc := (mask & Ids.W) == 0
	for y in T:
		for x in T:
			var c := _highland(_grass(x, y, 3))
			var ww := 7 + int(_wob(y, 6) * 0.5)
			var we := 7 + int(_wob(y, 7) * 0.5)
			var wn := 5 + int(_wob(x, 8) * 0.5)
			if s and y >= 29:
				c = _highland(G_HI if y == 29 else G_LIGHT)
			var rock := false
			if wc and x < ww:
				c = [R_OUT, R_HI, R_LIGHT, R_LIGHT, R_LIGHT, R_MID, R_DARK, R_DARK][x]
				rock = true
			if e and x >= T - we:
				c = [R_OUT, R_DARK, R_DARK, R_MID, R_MID, R_MID, R_LIGHT, R_LIGHT][31 - x]
				rock = true
			if n and y < wn:
				c = [R_OUT, R_LIGHT, R_LIGHT, R_LIGHT, R_MID, R_DARK][y]
				rock = true
			if rock and c != R_OUT and _h(x, y, 38) < 0.12:
				c = c.lerp(R_DARK, 0.7)
			img.set_pixel(o.x + x, o.y + y, c)


## Herbe d'altitude : plus claire et plus dorée que celle de la plaine, pour lire les niveaux.
func _highland(c: Color) -> Color:
	return c.lerp(Color8(196, 210, 112), 0.2)


# --- Héros -----------------------------------------------------------------
# Gabarits 16 x 23 sans contour (ajouté automatiquement). Bras dessinés à part pour le balancement.

const HERO_DOWN := [
	"................",
	".....hhHHhh.....",
	"...hhHHHhhhhh...",
	"..hhHHhhhhhhhh..",
	"..hHhhhhhhhhhh..",
	"..hhhsssssshhh..",
	"..hhssssssssSh..",
	"..hssessssesSh..",
	"..hssessssesSh..",
	"..hssssSSsssSh..",
	"..hhshhhhhhshh..",
	"...hhhhhhhhhh...",
	"....ffhhhhff....",
	"....gfhhhhfF....",
	"....gffhhffF....",
	"....gfffffFF....",
	"....ffgfffFF....",
	"....rrrrrrrr....",
	"....fFfFfFfF....",
]
const HERO_UP := [
	"................",
	".....hhHHhh.....",
	"...hhHHHhhhhh...",
	"..hhHHhhhhhhhh..",
	"..hHhhhhhhhhhh..",
	"..hhHhhhhhhhhh..",
	"..hhhhhhhhhhhh..",
	"..hhhHhhhhhhhh..",
	"..hhhhhhhhhhhh..",
	"..hhhhhhhhhhhh..",
	"...hhhhhhhhhh...",
	"....hhhhhhhh....",
	"....ffhhhhff....",
	"....gffhhffF....",
	"....gfffffFF....",
	"....gfffffFF....",
	"....ffgfffFF....",
	"....rrrrrrrr....",
	"....fFfFfFfF....",
]
const HERO_SIDE := [
	"................",
	"....hhHHhh......",
	"...hhHHHhhhh....",
	"..hhHHhhhhhhh...",
	"..hhhhhhhhhhhh..",
	"..hhhhhhsssss...",
	"..hhhhhsssssss..",
	"..hhhhSssssess..",
	"..hhhhSssssesss.",
	"..hhhhhsssssSs..",
	"...hhhhhshhhh...",
	"....hhhhhhhh....",
	".....ffhhhhf....",
	".....gfffhhf....",
	".....gfffffF....",
	".....gffFffF....",
	".....ffffFFF....",
	".....rrrrrrr....",
	".....fFfFfFf....",
]
const LEGS_FRONT_IDLE := [".....sS..sS.....", ".....sS..sS.....", ".....sS..sS.....", "....kkk..kkk...."]
const LEGS_FRONT_L := [".....sS..sS.....", ".....sS..sS.....", "....kkk..sS.....", ".........kkk...."]
const LEGS_FRONT_R := [".....sS..sS.....", ".....sS..sS.....", ".....sS..kkk....", "....kkk........."]
const LEGS_SIDE_IDLE := [".......sS.......", ".......sS.......", ".......sS.......", ".......kkk......"]
const LEGS_SIDE_STRIDE := ["......sS.sS.....", ".....sS...sS....", ".....sS....sS...", "....kkk....kkk.."]
const LEGS_SIDE_STRIDE2 := ["......Ss.Ss.....", ".....Ss...Ss....", ".....Ss....Ss...", "....kkk....kkk.."]


## Alliés : couleurs remplacées sur la palette du héros, sans barbe (« jeune ») ou avec bandeau.
const FOLLOWERS := [
	{"colors": {"h": Color8(168, 80, 38), "H": Color8(214, 124, 62),
		"f": Color8(142, 140, 132), "F": Color8(100, 98, 96), "g": Color8(180, 178, 168)}, "beard": true, "band": false},
	{"colors": {"h": Color8(42, 32, 32), "H": Color8(80, 62, 58),
		"f": Color8(206, 166, 98), "F": Color8(150, 108, 58), "g": Color8(234, 202, 142)}, "beard": true, "band": true},
	{"colors": {"h": Color8(126, 86, 52), "H": Color8(168, 118, 70),
		"f": Color8(112, 72, 42), "F": Color8(80, 50, 30), "g": Color8(144, 98, 60)}, "beard": false, "band": false},
	# Recrues (phase 3) : blond en peau grise, ancien aux cheveux gris, bandeau sur peau rousse,
	# auburn en fourrure claire, cape de feuilles.
	{"colors": {"h": Color8(206, 164, 86), "H": Color8(236, 202, 128),
		"f": Color8(118, 124, 134), "F": Color8(84, 88, 98), "g": Color8(152, 158, 166)}, "beard": false, "band": false},
	{"colors": {"h": Color8(146, 142, 136), "H": Color8(190, 186, 178),
		"f": Color8(150, 96, 54), "F": Color8(108, 66, 36), "g": Color8(186, 130, 80)}, "beard": true, "band": false},
	{"colors": {"h": Color8(48, 36, 34), "H": Color8(86, 66, 60),
		"f": Color8(180, 98, 54), "F": Color8(132, 66, 34), "g": Color8(214, 136, 84)}, "beard": false, "band": true},
	{"colors": {"h": Color8(122, 54, 36), "H": Color8(164, 84, 54),
		"f": Color8(198, 192, 178), "F": Color8(150, 144, 132), "g": Color8(226, 222, 210)}, "beard": true, "band": false},
	{"colors": {"h": Color8(90, 58, 36), "H": Color8(132, 88, 54),
		"f": Color8(106, 128, 68), "F": Color8(76, 96, 48), "g": Color8(138, 162, 92)}, "beard": false, "band": true},
]
const BAND := Color8(186, 58, 48)
## Villageois du campement (phase 3B) : tuniques claires, sans barbe.
const VILLAGERS := [
	{"h": Color8(60, 40, 30), "H": Color8(98, 68, 48), "f": Color8(214, 196, 158), "F": Color8(164, 146, 112), "g": Color8(236, 222, 190)},
	{"h": Color8(176, 110, 56), "H": Color8(214, 150, 86), "f": Color8(150, 74, 56), "F": Color8(108, 50, 38), "g": Color8(184, 104, 80)},
]


func _gen_hero() -> void:
	_save(_character_sheet(HERO_COLORS, true, false), "hero.png")
	for i in FOLLOWERS.size():
		var v: Dictionary = FOLLOWERS[i]
		var colors := HERO_COLORS.duplicate()
		colors.merge(v["colors"], true)
		colors["b"] = BAND
		_save(_character_sheet(colors, v["beard"], v["band"]), "follower_%d.png" % i)
	for i in VILLAGERS.size():
		var colors := HERO_COLORS.duplicate()
		colors.merge(VILLAGERS[i], true)
		_save(_character_sheet(colors, false, false), "villager_%d.png" % i)


## Planche 6 x 3 : colonnes repos 0-1, marche 2-5 ; lignes face, dos, profil (vers la droite).
func _character_sheet(colors: Dictionary, beard: bool, band: bool) -> Image:
	var img := _img(32 * 6, 32 * 3)
	var bob := [0, 1, 0, -1, 0, -1]
	for row in 3:
		var body := _variant_rows([HERO_DOWN, HERO_UP, HERO_SIDE][row], row, beard, band)
		for col in 6:
			var legs: Array
			var arm_l := 0
			var arm_r := 0
			var arm_dx := 0
			if row < 2:
				legs = [LEGS_FRONT_IDLE, LEGS_FRONT_IDLE, LEGS_FRONT_L, LEGS_FRONT_IDLE, LEGS_FRONT_R, LEGS_FRONT_IDLE][col]
				arm_l = [0, 1, 0, 0, 1, 0][col]
				arm_r = [0, 1, 1, 0, 0, 0][col]
			else:
				legs = [LEGS_SIDE_IDLE, LEGS_SIDE_IDLE, LEGS_SIDE_STRIDE, LEGS_SIDE_IDLE, LEGS_SIDE_STRIDE2, LEGS_SIDE_IDLE][col]
				arm_dx = [0, 0, -1, 0, 1, 0][col]
				arm_l = 1 if col == 1 else 0
			var frame := _img(32, 32)
			var o := Vector2i(8, 8)
			# Jambes (avec une rangée de hanche cachée sous la tunique).
			_stamp(frame, [legs[0]], o + Vector2i(0, 18), colors)
			_stamp(frame, legs, o + Vector2i(0, 19), colors)
			var up := o + Vector2i(0, bob[col])
			if row < 2:
				_arm(frame, up + Vector2i(2, 12 + arm_l), false, colors)
				_arm(frame, up + Vector2i(12, 12 + arm_r), true, colors)
			_stamp(frame, body, up, colors)
			if row == 2:
				_arm(frame, up + Vector2i(7 + arm_dx, 12 + arm_l), false, colors)
			_outline(frame, OUTLINE)
			img.blit_rect(frame, Rect2i(0, 0, 32, 32), Vector2i(col * 32, row * 32))
	return img


## Variantes de gabarit : menton rasé (rangées 10-11 en peau, poitrine sans barbe) et bandeau (rangée 4).
func _variant_rows(rows: Array, view: int, beard: bool, band: bool) -> Array:
	var out := []
	for y in rows.size():
		var line: String = rows[y]
		if band and y == 4:
			line = line.replace("h", "b").replace("H", "b")
		if not beard and view != 1:
			# Colonnes du visage par vue : [rangée 10, rangée 11, poitrine].
			var spans: Array = [[[4, 11], [5, 10], [5, 10]], [], [[8, 12], [8, 11], [7, 10]]][view]
			var span: Array = []
			var to := "s"
			if y == 10 or y == 11:
				span = spans[y - 10]
			elif y >= 12 and y <= 14:
				span = spans[2]
				to = "f"
			for x in range(span[0], span[1] + 1) if not span.is_empty() else []:
				if line[x] == "h":
					line = line.substr(0, x) + to + line.substr(x + 1)
		out.append(line)
	return out


func _stamp(img: Image, rows: Array, o: Vector2i, colors: Dictionary = HERO_COLORS) -> void:
	for y in rows.size():
		var line: String = rows[y]
		for x in line.length():
			var ch := line[x]
			if ch != ".":
				img.set_pixel(o.x + x, o.y + y, colors[ch])


func _arm(img: Image, o: Vector2i, shaded: bool, colors: Dictionary) -> void:
	for y in 6:
		img.set_pixel(o.x, o.y + y, colors["S" if shaded else "s"])
		img.set_pixel(o.x + 1, o.y + y, colors["S"])


# --- Décors (atlas props.png + props.json) ---------------------------------

func _gen_props() -> void:
	var sprites := []  # [nom, image, pivot]
	for v in 3:
		sprites.append(["tree_%d" % v, _tree(v), Vector2i(24, 58)])
	for v in 2:
		sprites.append(["pine_%d" % v, _pine(v), Vector2i(16, 57)])
	for v in 2:
		sprites.append(["bush_%d" % v, _bush(v), Vector2i(13, 18)])
	sprites.append(["rock_small", _rock_small(), Vector2i(9, 12)])
	sprites.append(["rock_large", _rock_large(), Vector2i(17, 23)])
	sprites.append(["hut_0", _hut_cone(), Vector2i(32, 58)])
	sprites.append(["hut_1", _hut_dome(), Vector2i(32, 58)])
	sprites.append(["crate", _crate(), Vector2i(9, 16)])
	sprites.append(["log", _log(), Vector2i(15, 12)])
	sprites.append(["woodpile", _woodpile(), Vector2i(14, 21)])
	sprites.append(["rack", _rack(), Vector2i(15, 28)])
	sprites.append(["menhir", _menhir(), Vector2i(9, 38)])
	sprites.append(["totem", _totem(), Vector2i(8, 40)])
	for v in 2:
		sprites.append(["reeds_%d" % v, _reeds(v), Vector2i(7, 18)])
	# Campement en évolution (phase 3B).
	sprites.append(["longhouse", _longhouse(), Vector2i(48, 60)])
	sprites.append(["palisade", _palisade(), Vector2i(16, 37)])
	sprites.append(["rack_meat", _rack_meat(), Vector2i(15, 28)])
	sprites.append(["baskets", _baskets(), Vector2i(13, 17)])
	sprites.append(["torch", _torch(), Vector2i(5, 27)])
	sprites.append(["banner", _banner(), Vector2i(8, 41)])
	_pack(sprites, "props")


func _pack(sprites: Array, base: String) -> void:
	var width := 256
	var x := 0
	var y := 0
	var row_h := 0
	var rects := {}
	for s in sprites:
		var im: Image = s[1]
		if x + im.get_width() > width:
			x = 0
			y += row_h + 1
			row_h = 0
		rects[s[0]] = {"rect": [x, y, im.get_width(), im.get_height()], "pivot": [s[2].x, s[2].y]}
		x += im.get_width() + 1
		row_h = maxi(row_h, im.get_height())
	var atlas := _img(width, y + row_h)
	for s in sprites:
		var r: Array = rects[s[0]]["rect"]
		atlas.blit_rect(s[1], Rect2i(0, 0, r[2], r[3]), Vector2i(r[0], r[1]))
	_save(atlas, base + ".png")
	var f := FileAccess.open(OUT + base + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify(rects, "\t", true))
	f.close()


## Grappe de feuillage ombrée (lumière en haut à gauche).
func _leaf_blob(img: Image, c: Vector3, pal: Array, seed: int) -> void:
	var r := c.z
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dx := x + 0.5 - c.x
			var dy := y + 0.5 - c.y
			var dist := sqrt(dx * dx + dy * dy)
			if dist > r:
				continue
			var t := (dx * 0.6 + dy * 0.8) / r + (_h(x >> 1, y >> 1, seed) - 0.5) * 0.5
			var col: Color
			if dist > r - 1.4 and dx + dy > 0.0:
				col = pal[0]
			elif t < -0.55:
				col = pal[3]
			elif t < -0.1:
				col = pal[2]
			elif t < 0.45:
				col = pal[1]
			else:
				col = pal[0]
			img.set_pixel(x, y, col)


func _trunk(img: Image, x0: int, x1: int, y0: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var c := WD_MID
			if x == x0:
				c = WD_LIGHT
			elif x >= x1 - 1:
				c = WD_DARK
			if _h(x, y, 50) < 0.12:
				c = WD_DARK
			img.set_pixel(x, y, c)
	img.set_pixel(x0 - 1, y1, WD_MID)
	img.set_pixel(x1 + 1, y1, WD_DARK)


func _tree(v: int) -> Image:
	var img := _img(48, 64)
	_trunk(img, 21, 26, 38, 57)
	var pal: Array = LEAVES[v]
	var blobs := [
		Vector3(24, 24, 16), Vector3(12, 31, 9), Vector3(36, 31, 9), Vector3(24, 36, 11),
		Vector3(16, 18, 10), Vector3(32, 17, 10), Vector3(24, 12, 9),
	]
	if v == 1:
		blobs = [Vector3(24, 26, 15), Vector3(14, 33, 8), Vector3(34, 33, 8), Vector3(24, 37, 9), Vector3(18, 19, 10), Vector3(30, 18, 9)]
	for i in blobs.size():
		_leaf_blob(img, blobs[i], pal, v * 10 + i)
	if v == 2:
		for i in 14:
			var px := 10 + int(_h(i, 2, 51) * 28.0)
			var py := 8 + int(_h(2, i, 52) * 28.0)
			if img.get_pixel(px, py).a > 0.0 and img.get_pixel(px, py) != pal[0]:
				img.set_pixel(px, py, Color8(240, 156, 186))
				img.set_pixel(px, py - 1, Color8(252, 210, 222))
	_outline(img, L_OUT)
	_ground_shadow(img, 24, 58, 14, 3.5)
	return img


func _pine(v: int) -> Image:
	var img := _img(32, 60)
	_trunk(img, 14, 17, 46, 56)
	var tiers := [Vector3(24, 50, 15), Vector3(14, 38, 12), Vector3(4, 25, 8)]
	if v == 1:
		tiers = [Vector3(20, 49, 14), Vector3(8, 34, 10)]
	for ti in tiers.size():
		var t: Vector3 = tiers[ti]
		for y in range(int(t.x), int(t.y)):
			var k := float(y - t.x) / (t.y - t.x)
			var half := t.z * pow(k, 0.85)
			for x in range(int(16 - half), int(16 + half) + 1):
				if y > t.y - 3 and (x + ti) % 3 == 0:
					continue
				var rel := (x + 0.5 - 16.0) / maxf(half, 1.0) + (_h(x, y, 53 + v) - 0.5) * 0.4
				var col: Color = PINE[1]
				if rel < -0.4:
					col = PINE[2]
				elif rel > 0.35:
					col = PINE[0]
				if k < 0.2 and rel < 0.2:
					col = PINE[3]
				img.set_pixel(x, y, col)
	_outline(img, L_OUT)
	_ground_shadow(img, 16, 57, 10, 3)
	return img


func _bush(v: int) -> Image:
	var img := _img(26, 21)
	var pal: Array = LEAVES[0]
	for b in [Vector3(7, 13, 6), Vector3(19, 13, 6), Vector3(13, 10, 8)]:
		_leaf_blob(img, b, pal, 60 + v)
	if v == 1:
		for i in 6:
			var px := 6 + int(_h(i, 7, 61) * 14.0)
			var py := 6 + int(_h(7, i, 62) * 10.0)
			if img.get_pixel(px, py).a > 0.0:
				img.set_pixel(px, py, Color8(206, 56, 64))
				img.set_pixel(px, py - 1, Color8(246, 130, 120))
	_outline(img, L_OUT)
	_ground_shadow(img, 13, 18, 10, 2.5)
	return img


func _rock_shape(img: Image, cx: float, cy: float, rx: float, ry: float, seed: int) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dy > 0.55:
				dy = 0.55 + (dy - 0.55) * 2.0
			var dd := dx * dx + dy * dy
			if dd > 1.0:
				continue
			var t := dx * 0.6 + dy * 0.8 + (_h(x, y, seed) - 0.5) * 0.3
			var c := R_MID
			if t < -0.5:
				c = R_HI
			elif t < -0.05:
				c = R_LIGHT
			elif t > 0.5:
				c = R_DARK
			if dy < -0.5 and _h(x, y, seed + 1) < 0.35:
				c = MOSS
			img.set_pixel(x, y, c)


func _rock_small() -> Image:
	var img := _img(18, 14)
	_rock_shape(img, 9, 7.5, 7.5, 6, 63)
	_outline(img, R_OUT)
	_ground_shadow(img, 9, 12.5, 8, 2)
	return img


func _rock_large() -> Image:
	var img := _img(36, 27)
	_rock_shape(img, 14, 13, 12, 11, 64)
	_rock_shape(img, 23, 16, 10, 8, 65)
	for i in 5:
		img.set_pixel(18 + i, 10 + i / 2, R_DARK)
	_outline(img, R_OUT)
	_ground_shadow(img, 18, 24, 16, 3)
	return img


func _hut_cone() -> Image:
	var img := _img(64, 64)
	for y in range(8, 57):
		var half := 29.0 * pow((y - 8) / 48.0, 0.8)
		for x in range(int(32 - half), int(32 + half) + 1):
			var rel := (x + 0.5 - 32.0) / maxf(half, 1.0)
			var row := (y - 8) / 5
			var c := ST_MID
			if rel < -0.45:
				c = ST_LIGHT
			elif rel > 0.4:
				c = ST_DARK
			if (y - 8) % 5 == 4 and _h(x, row, 66) < 0.7:
				c = c.lerp(WD_DARK, 0.45)
			elif _h(x, row, 67) < 0.14:
				c = c.lerp(ST_LIGHT, 0.5)
			img.set_pixel(x, y, c)
	# Entrée.
	for y in range(36, 57):
		for x in range(25, 39):
			var inside := y >= 43 or Vector2(x + 0.5, y + 0.5).distance_to(Vector2(32, 43)) <= 7.0
			if inside:
				img.set_pixel(x, y, Color8(44, 26, 20) if x > 26 else Color8(70, 44, 30))
	for y in range(40, 57):
		img.set_pixel(24, y, WD_LIGHT)
		img.set_pixel(39, y, WD_DARK)
	# Perches au sommet.
	for p in [[Vector2(32, 10), Vector2(24, 0)], [Vector2(32, 10), Vector2(40, 0)], [Vector2(32, 10), Vector2(31, 0)]]:
		for i in 12:
			var q: Vector2 = p[0].lerp(p[1], i / 11.0)
			img.set_pixel(int(q.x), int(q.y), WD_MID if i % 3 else WD_DARK)
	_outline(img, OUTLINE)
	_ground_shadow(img, 33, 58, 30, 4.5)
	return img


func _hut_dome() -> Image:
	var img := _img(64, 64)
	for y in range(18, 57):
		for x in range(3, 61):
			var dx := (x + 0.5 - 32.0) / 29.0
			var dy := (y + 0.5 - 57.0) / 38.0
			if dx * dx + dy * dy > 1.0:
				continue
			var c := Color8(160, 104, 60)
			var t := dx * 0.7 + dy * 0.4
			if t < -0.5:
				c = Color8(196, 140, 88)
			elif t > 0.35:
				c = Color8(118, 74, 42)
			if (x - 4) % 11 == 0:
				c = Color8(96, 60, 36)
			elif _h(x >> 1, y >> 1, 68) < 0.08:
				c = Color8(132, 84, 48)
			img.set_pixel(x, y, c)
	for y in range(38, 57):
		for x in range(26, 39):
			if y >= 44 or Vector2(x + 0.5, y + 0.5).distance_to(Vector2(32.5, 44)) <= 6.5:
				img.set_pixel(x, y, Color8(44, 26, 20))
	# Rabat de peau et défenses décoratives.
	for y in range(40, 52):
		img.set_pixel(36, y, Color8(196, 140, 88))
		img.set_pixel(37, y, Color8(160, 104, 60))
	for p in [Vector2i(20, 22), Vector2i(43, 22)]:
		for i in 6:
			img.set_pixel(p.x + (i / 2 if p.x > 32 else -i / 2), p.y - i, Color8(238, 230, 206))
	for p in [[Vector2(32, 21), Vector2(26, 10)], [Vector2(32, 21), Vector2(38, 10)]]:
		for i in 12:
			var q: Vector2 = p[0].lerp(p[1], i / 11.0)
			img.set_pixel(int(q.x), int(q.y), WD_MID)
	_outline(img, OUTLINE)
	_ground_shadow(img, 33, 58, 30, 4.5)
	return img


func _crate() -> Image:
	var img := _img(18, 18)
	for y in range(1, 17):
		for x in range(1, 17):
			var c := WD_MID
			if y < 5:
				c = WD_LIGHT if y > 1 else WD_HI
			elif y in [9, 13]:
				c = WD_DARK
			if x in [1, 16] and y >= 5:
				c = WD_DARK
			img.set_pixel(x, y, c)
	_outline(img, OUTLINE)
	return img


func _log() -> Image:
	var img := _img(30, 14)
	for y in range(3, 12):
		for x in range(2, 25):
			var c := WD_MID
			if y == 3:
				c = WD_LIGHT
			elif y >= 10:
				c = WD_DARK
			elif _h(x >> 1, y, 69) < 0.25:
				c = WD_DARK
			img.set_pixel(x, y, c)
	for y in range(2, 13):
		for x in range(21, 30):
			var dx := (x + 0.5 - 25.0) / 3.8
			var dy := (y + 0.5 - 7.5) / 5.0
			var dd := dx * dx + dy * dy
			if dd <= 1.0:
				img.set_pixel(x, y, WD_END if dd > 0.25 else WD_LIGHT)
	_outline(img, OUTLINE)
	return img


func _woodpile() -> Image:
	var img := _img(28, 23)
	for p in [Vector2(6, 17), Vector2(14, 17), Vector2(22, 17), Vector2(10, 11), Vector2(18, 11), Vector2(14, 5)]:
		for y in img.get_height():
			for x in img.get_width():
				var d := Vector2(x + 0.5, y + 0.5).distance_to(p)
				if d <= 4.4:
					img.set_pixel(x, y, WD_DARK if d > 3.4 else (WD_LIGHT if d < 1.2 else WD_END))
	_outline(img, OUTLINE)
	_ground_shadow(img, 14, 21.5, 13, 2)
	return img


## Maison longue au toit de chaume (96 x 64) : bâtiment du village prospère.
func _longhouse() -> Image:
	var img := _img(96, 64)
	# Murs de rondins.
	for y in range(40, 60):
		for x in range(8, 88):
			var c := WD_MID if (y - 40) % 5 < 3 else WD_DARK
			if (y - 40) % 5 == 0:
				c = WD_LIGHT
			img.set_pixel(x, y, c)
	# Toit : demi-ellipse de chaume, rangées décalées, ombré à droite.
	for y in range(8, 46):
		for x in range(2, 94):
			var dx := (x + 0.5 - 48.0) / 46.0
			var dy := (y + 0.5 - 46.0) / 38.0
			if dx * dx + dy * dy > 1.0:
				continue
			var row := (y - 8) / 5
			var c := ST_MID
			if dx < -0.5:
				c = ST_LIGHT
			elif dx > 0.45:
				c = ST_DARK
			if (y - 8) % 5 == 4 and _h(x, row, 98) < 0.7:
				c = c.lerp(WD_DARK, 0.45)
			elif _h(x, row, 99) < 0.12:
				c = c.lerp(ST_LIGHT, 0.5)
			img.set_pixel(x, y, c)
	# Porte et poutres d'angle.
	for y in range(44, 60):
		for x in range(42, 54):
			if y >= 49 or Vector2(x + 0.5, y + 0.5).distance_to(Vector2(48, 49)) <= 6.0:
				img.set_pixel(x, y, Color8(44, 26, 20))
	for y in range(40, 60):
		for x in [8, 87]:
			img.set_pixel(x, y, WD_DARK)
	for p in [[Vector2(48, 9), Vector2(40, 1)], [Vector2(48, 9), Vector2(56, 1)]]:
		for i in 12:
			var q: Vector2 = p[0].lerp(p[1], i / 11.0)
			img.set_pixel(int(q.x), int(q.y), WD_MID)
	_outline(img, OUTLINE)
	_ground_shadow(img, 48, 60, 46, 4.5)
	return img


## Tronçon de palissade : pieux taillés en pointe liés par une corde.
func _palisade() -> Image:
	var img := _img(32, 40)
	for k in 5:
		var x0 := 1 + k * 6
		var top := 4 + int(_h(k, 0, 100) * 4.0)
		for y in range(top, 38):
			for x in range(x0, x0 + 5):
				var c := WD_LIGHT if x == x0 else (WD_DARK if x == x0 + 4 else WD_MID)
				if y < top + 3 and (x < x0 + 1 + (y - top) or x > x0 + 3 - (y - top)):
					continue
				img.set_pixel(x, y, c)
	for x in 32:
		for y in [15, 29]:
			img.set_pixel(x, y, HERO_COLORS["r"])
			img.set_pixel(x, y + 1, ST_DARK)
	_outline(img, OUTLINE)
	_ground_shadow(img, 16, 38, 16, 2.0)
	return img


## Séchoir garni de lanières de viande (réserve de vivres).
func _rack_meat() -> Image:
	var img := _img(30, 30)
	for y in range(3, 29):
		for x in [3, 26]:
			img.set_pixel(x, y, WD_MID)
			img.set_pixel(x + 1, y, WD_DARK)
	for x in range(2, 28):
		img.set_pixel(x, 4, WD_LIGHT)
		img.set_pixel(x, 5, WD_DARK)
	for k in 5:
		var x0 := 7 + k * 4
		var length := 9 + int(_h(k, 1, 101) * 7.0)
		for y in range(6, 6 + length):
			img.set_pixel(x0, y, Color8(198, 84, 70) if y % 3 else Color8(150, 56, 50))
			img.set_pixel(x0 + 1, y, Color8(230, 130, 110) if y < 8 + length / 2 else Color8(178, 70, 60))
	_outline(img, OUTLINE)
	_ground_shadow(img, 15, 29, 13, 1.5)
	return img


## Paniers de réserve tressés, l'un rempli de baies.
func _baskets() -> Image:
	var img := _img(26, 20)
	for b in [Vector3(8, 12, 6), Vector3(18, 13, 5)]:
		for y in range(int(b.y - b.z), int(b.y + b.z) + 1):
			for x in range(int(b.x - b.z), int(b.x + b.z) + 1):
				var d := Vector2((x + 0.5 - b.x) / b.z, (y + 0.5 - b.y) / b.z)
				if d.y < -0.35 or d.length() > 1.0:
					continue
				var weave := (x + y) % 3 == 0
				img.set_pixel(x, y, ST_DARK if weave else ST_MID)
	for i in 7:
		var p := Vector2i(4 + int(_h(i, 2, 102) * 8.0), 8 + int(_h(2, i, 103) * 2.0))
		img.set_pixelv(p, Color8(150, 40, 70))
		img.set_pixelv(p + Vector2i(0, -1), Color8(206, 70, 100))
	_outline(img, OUTLINE)
	_ground_shadow(img, 13, 18, 12, 1.5)
	return img


## Torche plantée à l'entrée du camp.
func _torch() -> Image:
	var img := _img(10, 29)
	for y in range(9, 28):
		img.set_pixel(4, y, WD_MID)
		img.set_pixel(5, y, WD_DARK)
	for x in range(3, 7):
		img.set_pixel(x, 9, HERO_COLORS["r"])
	_outline(img, OUTLINE)
	for p in [Vector2i(4, 3), Vector2i(5, 4), Vector2i(4, 5), Vector2i(5, 6), Vector2i(4, 7), Vector2i(5, 8), Vector2i(3, 6), Vector2i(6, 7)]:
		img.set_pixelv(p, Color8(255, 194, 64))
	for p in [Vector2i(4, 6), Vector2i(5, 7), Vector2i(4, 7)]:
		img.set_pixelv(p, Color8(255, 244, 170))
	img.set_pixel(5, 2, Color8(240, 106, 40))
	return img


## Bannière de peau peinte sur une perche.
func _banner() -> Image:
	var img := _img(16, 43)
	for y in range(2, 42):
		img.set_pixel(3, y, WD_MID)
		img.set_pixel(4, y, WD_DARK)
	for y in range(5, 22):
		var width := 10 - (2 if y > 18 and y % 2 else 0)
		for x in range(5, 5 + width):
			img.set_pixel(x, y, HERO_COLORS["g"] if x < 9 else HERO_COLORS["f"])
	# Motif : soleil rouge.
	for p in [Vector2i(9, 11), Vector2i(10, 11), Vector2i(9, 12), Vector2i(10, 12), Vector2i(9, 9), Vector2i(12, 11), Vector2i(9, 14), Vector2i(7, 12)]:
		img.set_pixelv(p, Color8(190, 70, 50))
	for p in [Vector2i(2, 1), Vector2i(5, 1), Vector2i(3, 0)]:
		img.set_pixelv(p, Color8(240, 236, 220))
	_outline(img, OUTLINE)
	_ground_shadow(img, 4, 42, 5, 1.2)
	return img


func _rack() -> Image:
	var img := _img(30, 30)
	for y in range(3, 29):
		for x in [3, 26]:
			img.set_pixel(x, y, WD_MID)
			img.set_pixel(x + 1, y, WD_DARK)
	for x in range(2, 28):
		img.set_pixel(x, 4, WD_LIGHT)
		img.set_pixel(x, 5, WD_DARK)
	for y in range(6, 23):
		var inset := 1 + int(_h(0, y, 70) * 2.0)
		for x in range(7 + inset, 23 - inset):
			var c := HERO_COLORS["g"] if x < 12 else HERO_COLORS["f"]
			if _h(x >> 1, y >> 1, 71) < 0.15:
				c = HERO_COLORS["F"]
			img.set_pixel(x, y, c)
	_outline(img, OUTLINE)
	return img


func _menhir() -> Image:
	var img := _img(18, 41)
	for y in range(2, 39):
		var half := 6.0
		if y < 9:
			half = 6.0 * sqrt((y - 1) / 8.0)
		var lean := (38 - y) / 18.0
		for x in range(int(9 - half + lean), int(9 + half + lean) + 1):
			var rel := (x + 0.5 - 9.0 - lean) / maxf(half, 1.0)
			var c := R_MID
			if rel < -0.45:
				c = R_LIGHT
			elif rel > 0.45:
				c = R_DARK
			if _h(x, y, 72) < 0.06:
				c = Color8(188, 196, 110)
			elif y < 14 and _h(x, y, 73) < 0.2 and rel < 0.2:
				c = MOSS
			img.set_pixel(x, y, c)
	# Spirale gravée.
	for q in [Vector2i(9, 18), Vector2i(10, 18), Vector2i(11, 19), Vector2i(11, 20), Vector2i(10, 21), Vector2i(9, 21), Vector2i(8, 20), Vector2i(8, 19), Vector2i(10, 19)]:
		img.set_pixelv(q, R_HI)
	_outline(img, R_OUT)
	_ground_shadow(img, 9, 39, 8, 2)
	return img


func _totem() -> Image:
	var img := _img(16, 43)
	for y in range(7, 41):
		for x in range(4, 12):
			var c := WD_MID
			if x == 4:
				c = WD_LIGHT
			elif x >= 10:
				c = WD_DARK
			if y in [16, 17]:
				c = Color8(190, 70, 50)
			elif y in [30, 31]:
				c = ST_LIGHT
			img.set_pixel(x, y, c)
	for face_y in [10, 23]:
		img.set_pixel(6, face_y, OUTLINE)
		img.set_pixel(9, face_y, OUTLINE)
		for x in range(6, 10):
			img.set_pixel(x, face_y + 3, WD_DARK)
	var feathers := [[3, Color8(240, 236, 220)], [6, Color8(200, 74, 54)], [9, Color8(240, 236, 220)], [12, Color8(220, 170, 70)]]
	for f in feathers:
		for y in range(1, 7):
			img.set_pixel(f[0] + (1 if y < 3 else 0), y, f[1])
	_outline(img, OUTLINE)
	_ground_shadow(img, 8, 41, 6, 1.5)
	return img


func _reeds(v: int) -> Image:
	var img := _img(14, 20)
	for i in 5:
		var bx := 2 + i * 2 + (v if i % 2 else 0)
		var hgt := 9 + int(_h(i, v, 74) * 8.0)
		for k in hgt:
			var x := bx + int(sin(k * 0.25 + i) * (k / 8.0))
			var c := G_DARK if k < 4 else (Color8(150, 172, 84) if i % 2 else G_LIGHT)
			img.set_pixel(clampi(x, 0, 13), 18 - k, c)
		if i % 2 == 0 and hgt > 11:
			for k in 3:
				img.set_pixel(clampi(bx + int(sin(hgt * 0.25 + i) * (hgt / 8.0)), 0, 13), 18 - hgt + k, Color8(110, 68, 40))
	return img


# --- Effets ----------------------------------------------------------------

func _gen_fx() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "fx"))
	_save(_campfire(), "fx/campfire.png")
	_save(_campfire_big(), "fx/campfire_big.png")
	var glow := _img(48, 48)
	for y in 48:
		for x in 48:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(24, 24))
			var a := 0.0
			if d < 8:
				a = 0.4
			elif d < 14:
				a = 0.24
			elif d < 20:
				a = 0.12
			elif d < 24:
				a = 0.05
			glow.set_pixel(x, y, Color(1.0, 0.62, 0.25, a))
	_save(glow, "fx/glow.png")
	var smoke := _img(4, 4)
	smoke.fill(Color(0.84, 0.82, 0.8, 0.9))
	for c in [Vector2i(0, 0), Vector2i(3, 0), Vector2i(0, 3), Vector2i(3, 3)]:
		smoke.set_pixelv(c, Color(0.84, 0.82, 0.8, 0.35))
	_save(smoke, "fx/smoke.png")
	var shadow := _img(16, 6)
	_ground_shadow(shadow, 8, 3, 7, 2.5)
	_save(shadow, "fx/shadow.png")
	var fly := _img(16, 8)
	for p in [Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3), Vector2i(1, 4), Vector2i(5, 1), Vector2i(5, 2), Vector2i(5, 3), Vector2i(6, 2), Vector2i(6, 4)]:
		fly.set_pixelv(p + Vector2i(0, 1), Color.WHITE)
	for p in [Vector2i(10, 2), Vector2i(10, 3), Vector2i(13, 2), Vector2i(13, 3)]:
		fly.set_pixelv(p + Vector2i(0, 1), Color.WHITE)
	for x in [3, 4, 11, 12]:
		fly.set_pixel(x, 3, OUTLINE)
		fly.set_pixel(x, 4, OUTLINE)
	_save(fly, "fx/butterfly.png")


func _campfire() -> Image:
	var img := _img(32 * 4, 32)
	var heights := [[7, 12, 8], [9, 10, 6], [6, 13, 9], [8, 11, 7]]
	for f in 4:
		var fr := _img(32, 32)
		var stones := []
		for k in 8:
			var a := TAU * k / 8.0 + 0.3
			stones.append(Vector2(16 + cos(a) * 10.0, 25 + sin(a) * 4.0))
		for st in stones:
			if st.y <= 25:
				_stone(fr, st)
		for i in 12:
			fr.set_pixel(10 + i, 24 - i / 3, WD_MID)
			fr.set_pixel(10 + i, 25 - i / 3, WD_DARK)
			fr.set_pixel(21 - i, 24 - i / 3, WD_LIGHT)
			fr.set_pixel(21 - i, 25 - i / 3, WD_DARK)
		for st in stones:
			if st.y > 25:
				_stone(fr, st)
		_outline(fr, OUTLINE)
		var xs := [12, 16, 20]
		for t in 3:
			var hgt: int = heights[f][t]
			for i in hgt:
				var k := float(i) / hgt
				var half := int(round(2.6 * (1.0 - k) + 0.4))
				var sway := int(round(sin(k * 3.0 + f * 1.6 + t) * 1.2 * k))
				for dx in range(-half, half + 1):
					var rel := absf(dx) / maxf(half, 1.0)
					var c := Color8(240, 106, 40)
					if rel < 0.4 and k < 0.6:
						c = Color8(255, 244, 170)
					elif rel < 0.8 and k < 0.85:
						c = Color8(255, 194, 64)
					fr.set_pixel(xs[t] + dx + sway, 23 - i, c)
		var sx: int = [19, 13, 17, 14][f]
		fr.set_pixel(sx, 7 - f, Color8(255, 224, 130))
		img.blit_rect(fr, Rect2i(0, 0, 32, 32), Vector2i(f * 32, 0))
	return img


## Grand feu central du village prospère : 4 images 48 x 40, couronne de pierres plus large.
func _campfire_big() -> Image:
	var img := _img(48 * 4, 40)
	var heights := [[9, 14, 18, 13, 8], [11, 16, 15, 14, 9], [8, 13, 19, 15, 10], [10, 17, 16, 12, 9]]
	for f in 4:
		var fr := _img(48, 40)
		var stones := []
		for k in 11:
			var a := TAU * k / 11.0 + 0.2
			stones.append(Vector2(24 + cos(a) * 15.0, 32 + sin(a) * 5.5))
		for st in stones:
			if st.y <= 32:
				_stone(fr, st)
		for i in 18:
			fr.set_pixel(15 + i, 32 - i / 3, WD_MID)
			fr.set_pixel(15 + i, 33 - i / 3, WD_DARK)
			fr.set_pixel(32 - i, 32 - i / 3, WD_LIGHT)
			fr.set_pixel(32 - i, 33 - i / 3, WD_DARK)
		for st in stones:
			if st.y > 32:
				_stone(fr, st)
		_outline(fr, OUTLINE)
		var xs := [16, 20, 24, 28, 32]
		for t in 5:
			var hgt: int = heights[f][t]
			for i in hgt:
				var k := float(i) / hgt
				var half := int(round(3.4 * (1.0 - k) + 0.5))
				var sway := int(round(sin(k * 3.0 + f * 1.6 + t) * 1.5 * k))
				for dx in range(-half, half + 1):
					var rel := absf(dx) / maxf(half, 1.0)
					var c := Color8(240, 106, 40)
					if rel < 0.4 and k < 0.6:
						c = Color8(255, 244, 170)
					elif rel < 0.8 and k < 0.85:
						c = Color8(255, 194, 64)
					fr.set_pixel(xs[t] + dx + sway, 30 - i, c)
		for s in 2:
			var sx: int = [27, 19, 25, 21][(f + s) % 4]
			fr.set_pixel(sx, 9 - f - s * 3, Color8(255, 224, 130))
		img.blit_rect(fr, Rect2i(0, 0, 48, 40), Vector2i(f * 48, 0))
	return img


func _stone(img: Image, c: Vector2) -> void:
	for y in range(-2, 3):
		for x in range(-3, 4):
			if x * x / 9.0 + y * y / 4.0 > 1.0:
				continue
			img.set_pixel(int(c.x) + x, int(c.y) + y, R_HI if y < 0 else (R_MID if y == 0 else R_DARK))


# --- Combat : sangliers, impacts, butin, chiffres -------------------------

const BOARS := [
	# Jeune sanglier : brun chaud. Grand sanglier : gris-brun sombre, défenses longues, plus massif.
	{"fur": [Color8(92, 58, 38), Color8(128, 84, 52), Color8(158, 108, 68)], "mane": Color8(64, 40, 28),
		"snout": Color8(176, 128, 112), "size": 1.0, "tusk": 2},
	{"fur": [Color8(62, 52, 50), Color8(92, 78, 72), Color8(120, 104, 94)], "mane": Color8(176, 168, 150),
		"snout": Color8(150, 118, 108), "size": 1.18, "tusk": 4},
]
## Chiffres et signes, glyphes 4 x 6 (contour ajouté : cases de 6 x 8).
const GLYPHS := {
	"0": [".##.", "#..#", "#..#", "#..#", "#..#", ".##."],
	"1": [".#..", "##..", ".#..", ".#..", ".#..", "###."],
	"2": [".##.", "#..#", "..#.", ".#..", "#...", "####"],
	"3": ["###.", "...#", ".##.", "...#", "...#", "###."],
	"4": ["#..#", "#..#", "####", "...#", "...#", "...#"],
	"5": ["####", "#...", "###.", "...#", "...#", "###."],
	"6": [".##.", "#...", "###.", "#..#", "#..#", ".##."],
	"7": ["####", "...#", "..#.", ".#..", ".#..", ".#.."],
	"8": [".##.", "#..#", ".##.", "#..#", "#..#", ".##."],
	"9": [".##.", "#..#", "#..#", ".###", "...#", ".##."],
	"+": ["....", ".#..", "###.", ".#..", "....", "...."],
	"-": ["....", "....", "###.", "....", "....", "...."],
	"A": [".##.", "#..#", "#..#", "####", "#..#", "#..#"],
	"B": ["###.", "#..#", "###.", "#..#", "#..#", "###."],
	"C": [".###", "#...", "#...", "#...", "#...", ".###"],
	"D": ["###.", "#..#", "#..#", "#..#", "#..#", "###."],
	"E": ["####", "#...", "###.", "#...", "#...", "####"],
	"F": ["####", "#...", "###.", "#...", "#...", "#..."],
	"G": [".###", "#...", "#.##", "#..#", "#..#", ".###"],
	"H": ["#..#", "#..#", "####", "#..#", "#..#", "#..#"],
	"I": ["###.", ".#..", ".#..", ".#..", ".#..", "###."],
	"J": ["..##", "...#", "...#", "...#", "#..#", ".##."],
	"K": ["#..#", "#.#.", "##..", "#.#.", "#..#", "#..#"],
	"L": ["#...", "#...", "#...", "#...", "#...", "####"],
	"M": ["#..#", "####", "####", "#..#", "#..#", "#..#"],
	"N": ["#..#", "##.#", "#.##", "#..#", "#..#", "#..#"],
	"O": [".##.", "#..#", "#..#", "#..#", "#..#", ".##."],
	"P": ["###.", "#..#", "#..#", "###.", "#...", "#..."],
	"Q": [".##.", "#..#", "#..#", "#..#", "#.#.", ".#.#"],
	"R": ["###.", "#..#", "#..#", "###.", "#.#.", "#..#"],
	"S": [".###", "#...", ".##.", "...#", "...#", "###."],
	"T": ["###.", ".#..", ".#..", ".#..", ".#..", ".#.."],
	"U": ["#..#", "#..#", "#..#", "#..#", "#..#", ".##."],
	"V": ["#..#", "#..#", "#..#", "#..#", ".##.", ".##."],
	"W": ["#..#", "#..#", "#..#", "####", "####", "#..#"],
	"X": ["#..#", "#..#", ".##.", ".##.", "#..#", "#..#"],
	"Y": ["#..#", "#..#", ".##.", ".#..", ".#..", ".#.."],
	"Z": ["####", "...#", "..#.", ".#..", "#...", "####"],
	"%": ["#..#", "...#", "..#.", ".#..", "#...", "#..#"],
	"/": ["...#", "..#.", "..#.", ".#..", ".#..", "#..."],
}
## Partagé avec PixelText.GLYPHS (même ordre).
const GLYPH_ORDER := "0123456789+-ABCDEFGHIJKLMNOPQRSTUVWXYZ%/"


func _gen_combat() -> void:
	for i in BOARS.size():
		_save(_boar_sheet(BOARS[i]), "boar_%d.png" % i)
	_save(_slash(), "fx/slash.png")
	_save(_spark(), "fx/spark.png")
	_save(_puff(), "fx/puff.png")
	_save(_pickups(), "fx/pickups.png")
	_save(_digits(), "fx/digits.png")
	_save(_upgrade_icons(), "fx/upgrade_icons.png")
	_save(_marker(), "fx/marker.png")


## Icônes d'amélioration, cases 16 x 16 : recrue, force (massue), aimant (sac), vigueur (cœur).
func _upgrade_icons() -> Image:
	var img := _img(64, 16)
	var gold := Color8(255, 214, 90)
	# Recrue : tête d'homme des cavernes et signe plus.
	var head := _img(16, 16)
	for y in range(3, 13):
		for x in range(2, 11):
			var d := Vector2((x + 0.5 - 6.5) / 4.5, (y + 0.5 - 8.0) / 5.0).length()
			if d <= 1.0:
				head.set_pixel(x, y, HERO_COLORS["h"] if y < 6 or x < 4 or x > 9 or y > 10 else HERO_COLORS["s"])
	head.set_pixel(5, 7, OUTLINE)
	head.set_pixel(8, 7, OUTLINE)
	for k in range(-2, 3):
		head.set_pixel(12 + k, 4, gold)
		head.set_pixel(12, 4 + k, gold)
	# Force : massue en diagonale.
	var club := _img(16, 16)
	for i in 9:
		club.set_pixel(3 + i, 13 - i, WD_MID)
		club.set_pixel(4 + i, 13 - i, WD_DARK)
	for y in range(1, 7):
		for x in range(9, 15):
			if Vector2(x + 0.5 - 11.5, y + 0.5 - 4.0).length() <= 3.2:
				club.set_pixel(x, y, WD_LIGHT if x + y < 15 else WD_MID)
	club.set_pixel(11, 3, WD_HI)
	# Aimant : sac de peau fermé par un lien.
	var bag := _img(16, 16)
	for y in range(5, 15):
		for x in range(2, 14):
			if Vector2((x + 0.5 - 8.0) / 5.5, (y + 0.5 - 10.0) / 4.8).length() <= 1.0:
				bag.set_pixel(x, y, HERO_COLORS["g"] if x < 7 else HERO_COLORS["f"])
	for x in range(5, 11):
		bag.set_pixel(x, 4, HERO_COLORS["f"])
		bag.set_pixel(x, 5, HERO_COLORS["r"])
	for p in [Vector2i(6, 2), Vector2i(7, 3), Vector2i(9, 3), Vector2i(10, 2)]:
		bag.set_pixelv(p, HERO_COLORS["F"])
	# Vigueur : cœur.
	var heart := _img(16, 16)
	for y in 16:
		for x in 16:
			var px := (x + 0.5 - 8.0) / 6.0
			var py := (y + 0.5 - 8.5) / 6.0
			var v := pow(px * px + py * py - 0.45, 3.0) - px * px * pow(-py, 3.0) * 1.6
			if v <= 0.0:
				heart.set_pixel(x, y, Color8(236, 78, 74) if px < 0.0 or py > 0.1 else Color8(200, 50, 56))
	heart.set_pixel(5, 6, Color8(255, 190, 180))
	var icons := [head, club, bag, heart]
	for i in icons.size():
		_outline(icons[i], OUTLINE)
		img.blit_rect(icons[i], Rect2i(0, 0, 16, 16), Vector2i(i * 16, 0))
	return img


## Repère doré au-dessus du feu quand un achat est possible.
func _marker() -> Image:
	var img := _img(9, 12)
	var rows := ["..#####..", ".#######.", "..#####..", "...###...", "....#....", ".........", "...###...", "...###..."]
	for y in rows.size():
		for x in 9:
			if rows[y][x] == "#":
				img.set_pixel(x, y + 2, Color8(255, 214, 90) if y < 2 else Color8(240, 170, 60))
	_outline(img, OUTLINE)
	return img


## Planche de profil (vers la droite), cases 44 x 30 : repos 0-1, course 2-5, charge préparée 6, K.O. 7.
func _boar_sheet(v: Dictionary) -> Image:
	var img := _img(44 * 8, 30)
	var fur: Array = v["fur"]
	var s: float = v["size"]
	for f in 8:
		var fr := _img(44, 30)
		var bob: int = [0, 1, 0, -1, 0, -1, 0, 0][f]
		var down := f == 6
		var ko := f == 7
		var body := Vector2(20, 17 + bob) if not ko else Vector2(20, 21)
		var rx := 12.0 * s
		var ry := 7.0 * s
		# Pattes (dessinées d'abord, le corps les recouvre).
		var legs := [-8.0, -4.0, 5.0, 9.0]
		var swing: Array = [[0, 0, 0, 0], [0, 0, 0, 0], [2, -2, -2, 2], [0, 0, 0, 0], [-2, 2, 2, -2], [0, 0, 0, 0], [-1, -2, 2, 3], [0, 0, 0, 0]][f]
		for k in 4:
			var lx: int = int(body.x + legs[k] * s) + swing[k]
			if ko:
				for y in range(int(body.y - ry) - 4, int(body.y - ry) + 1):
					fr.set_pixel(lx, y, fur[0])
					fr.set_pixel(lx + 1, y, fur[0])
			else:
				for y in range(int(body.y + ry * 0.5), 27):
					fr.set_pixel(lx, y, fur[0])
					fr.set_pixel(lx + 1, y, fur[0] if y < 26 else OUTLINE)
		# Corps : dos clair (lumière en haut), ventre sombre.
		for y in fr.get_height():
			for x in fr.get_width():
				var dx := (x + 0.5 - body.x) / rx
				var dy := (y + 0.5 - body.y) / ry
				if dx * dx + dy * dy > 1.0:
					continue
				var c: Color = fur[1]
				if dy < -0.35:
					c = fur[2]
				elif dy > 0.45:
					c = fur[0]
				if _h(x >> 1, y, 95) < 0.12:
					c = c.lerp(fur[0], 0.6)
				fr.set_pixel(x, y, c)
		# Crinière en pics le long du dos.
		if not ko:
			for x in range(int(body.x - rx * 0.6), int(body.x + rx * 0.7)):
				var spike := 2 + int(_h(x, 0, 96) * 2.0)
				var y0 := int(body.y - ry * sqrt(maxf(1.0 - pow((x + 0.5 - body.x) / rx, 2.0), 0.0)))
				for k in spike:
					fr.set_pixel(x, y0 - k + 1, v["mane"])
		# Tête, groin, défense, œil, oreille.
		var head := body + Vector2(rx + 1.0, 1.0 + (2.0 if down else 0.0))
		for y in fr.get_height():
			for x in fr.get_width():
				var dx := (x + 0.5 - head.x) / (6.0 * s)
				var dy := (y + 0.5 - head.y) / (5.0 * s)
				if dx * dx + dy * dy <= 1.0:
					fr.set_pixel(x, y, fur[2] if dy < -0.3 else fur[1])
		var snout := Vector2i(int(head.x + 5.0 * s), int(head.y))
		for y in range(-1, 2):
			for x in 3:
				fr.set_pixel(snout.x + x, snout.y + y, v["snout"])
		fr.set_pixel(snout.x + 2, snout.y, OUTLINE)
		for k in int(v["tusk"]):
			fr.set_pixel(snout.x - 1 + k / 2, snout.y + 2 - k, Color8(244, 236, 214))
		var eye := Vector2i(int(head.x + 1), int(head.y - 2))
		if ko:
			for d in [Vector2i(-1, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1)]:
				fr.set_pixelv(eye + d, OUTLINE)
		else:
			fr.set_pixelv(eye, Color8(200, 40, 30) if down else OUTLINE)
		for k in 3:
			fr.set_pixel(int(head.x - 3) + k / 2, int(head.y - 5 * s) - k + 1, fur[0])
		# Queue en tire-bouchon.
		for p in [Vector2i(-1, -2), Vector2i(-2, -3), Vector2i(-3, -2)]:
			fr.set_pixelv(Vector2i(int(body.x - rx), int(body.y)) + p, fur[0])
		_outline(fr, OUTLINE)
		_ground_shadow(fr, body.x, 27.5, rx + 2.0, 2.5)
		img.blit_rect(fr, Rect2i(0, 0, 44, 30), Vector2i(f * 44, 0))
	return img


## Arc de coup de massue, 3 images 32 x 32, orienté vers la droite.
func _slash() -> Image:
	var img := _img(96, 32)
	var arcs := [[-80.0, -10.0, 1.0], [-60.0, 60.0, 1.0], [10.0, 80.0, 0.55]]
	for f in 3:
		var a0: float = arcs[f][0]
		var a1: float = arcs[f][1]
		var alpha: float = arcs[f][2]
		for y in 32:
			for x in 32:
				var d := Vector2(x + 0.5 - 10.0, y + 0.5 - 16.0)
				var ang := rad_to_deg(d.angle())
				var r := d.length()
				if ang < a0 or ang > a1 or r < 9.0 or r > 15.0:
					continue
				var thick := 2.0 + 3.0 * sin((ang - a0) / (a1 - a0) * PI)
				if r > 9.0 + thick + 1.5:
					continue
				var c := Color8(255, 252, 230) if r > 9.0 + thick * 0.4 else Color8(255, 214, 120)
				img.set_pixel(f * 32 + x, y, Color(c, alpha))
	return img


## Étincelle d'impact, 3 images 16 x 16.
func _spark() -> Image:
	var img := _img(48, 16)
	var white := Color8(255, 252, 236)
	var gold := Color8(255, 206, 90)
	for f in 3:
		var o := Vector2i(f * 16 + 8, 8)
		var arm: int = [2, 5, 6][f]
		for k in range(-arm, arm + 1):
			if f == 2 and absi(k) < 4:
				continue
			var c := white if absi(k) < arm - 1 else gold
			img.set_pixelv(o + Vector2i(k, 0), c)
			img.set_pixelv(o + Vector2i(0, k), c)
		if f == 1:
			for d in [Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-2, 2), Vector2i(2, 2)]:
				img.set_pixelv(o + d, gold)
	return img


## Petit nuage de poussière, 3 images 12 x 10.
func _puff() -> Image:
	var img := _img(36, 10)
	for f in 3:
		var r := 2.5 + f * 1.3
		for y in 10:
			for x in 12:
				var d := Vector2(x + 0.5 - 6.0, (y + 0.5 - 6.0) * 1.3).length()
				if d <= r and (f < 2 or (x + y) % 2 == 0):
					img.set_pixel(f * 12 + x, y, Color8(214, 200, 170) if d < r - 1.2 else Color8(176, 160, 132))
	return img


## Butin, cases 12 x 12 : viande (vivres), peau, os (matériaux), dent gravée (savoir).
func _pickups() -> Image:
	var img := _img(48, 12)
	var meat := _img(12, 12)
	for y in 12:
		for x in 12:
			var d := Vector2((x + 0.5 - 5.0) / 4.0, (y + 0.5 - 5.5) / 3.2)
			if d.length() <= 1.0:
				meat.set_pixel(x, y, Color8(214, 92, 84) if d.y > 0.2 or d.x > 0.3 else Color8(240, 140, 128))
	for p in [Vector2i(8, 7), Vector2i(9, 8), Vector2i(10, 9), Vector2i(10, 8), Vector2i(9, 9)]:
		meat.set_pixelv(p, Color8(244, 236, 214))
	var hide := _img(12, 12)
	for y in range(2, 10):
		var inset := absi(y - 6) / 2
		for x in range(1 + inset, 11 - inset):
			hide.set_pixel(x, y, Color8(186, 128, 74) if _h(x, y, 97) > 0.25 else Color8(124, 78, 44))
	var bone := _img(12, 12)
	for i in 7:
		bone.set_pixel(3 + i, 8 - i, Color8(244, 236, 214))
	for p in [Vector2i(2, 8), Vector2i(3, 9), Vector2i(9, 1), Vector2i(10, 2)]:
		bone.set_pixelv(p, Color8(222, 210, 184))
	var tooth := _img(12, 12)
	for y in range(1, 11):
		var half := 3 - absi(y - 4) / 3 if y < 8 else 1
		for x in range(6 - half, 6 + half):
			tooth.set_pixel(x, y, Color8(150, 128, 236) if x < 6 else Color8(104, 86, 200))
	tooth.set_pixel(5, 3, Color8(236, 228, 255))
	tooth.set_pixel(5, 4, Color8(236, 228, 255))
	var sprites := [meat, hide, bone, tooth]
	for i in sprites.size():
		_outline(sprites[i], OUTLINE)
		img.blit_rect(sprites[i], Rect2i(0, 0, 12, 12), Vector2i(i * 12, 0))
	return img


func _digits() -> Image:
	var img := _img(6 * GLYPH_ORDER.length(), 8)
	for i in GLYPH_ORDER.length():
		var cell := _img(6, 8)
		var rows: Array = GLYPHS[GLYPH_ORDER[i]]
		for y in rows.size():
			for x in 4:
				if rows[y][x] == "#":
					cell.set_pixel(1 + x, 1 + y, Color.WHITE)
		_outline(cell, OUTLINE)
		img.blit_rect(cell, Rect2i(0, 0, 6, 8), Vector2i(i * 6, 0))
	return img
