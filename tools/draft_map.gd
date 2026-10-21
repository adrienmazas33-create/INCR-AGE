extends SceneTree
## Esquisse de la carte du prototype : formes placées à la main (coordonnées en tuiles),
## exportées vers data/maps/prototype.txt, qui devient la source éditable de la carte.
## Relancer ÉCRASE les retouches faites à la main dans le fichier texte.
## Usage : godot --headless --path . --script res://tools/draft_map.gd [-- --preview=<chemin.png>]

const MapDataScript := preload("res://scripts/world/map_data.gd")
const W := 120
const H := 100
const OUT := "res://data/maps/prototype.txt"

var g: Array[PackedStringArray] = []


func _init() -> void:
	for y in H:
		var row := PackedStringArray()
		row.resize(W)
		row.fill("T")
		g.append(row)
	_paint()
	_write()
	var map = MapDataScript.load_from_file(OUT)
	print(map.reachability_report())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="):
			map.save_preview(arg.trim_prefix("--preview="))
	quit()


func _paint() -> void:
	var river := [Vector2(71, -2), Vector2(72, 8), Vector2(74, 18), Vector2(77, 28), Vector2(79, 38),
		Vector2(80, 48), Vector2(79, 58), Vector2(77, 66), Vector2(72, 73), Vector2(64, 78), Vector2(56, 81)]

	# Clairières, vallées et prairies (le reste est forêt dense).
	blob(58, 55, 13, 10, ".")                                   # campement
	stroke([Vector2(58, 50), Vector2(57, 38), Vector2(58, 28)], 9, ".")
	blob(58, 20, 13, 9, ".", "", 1.3)                           # colline nord
	stroke(river, 11, ".")                                      # berges de la rivière
	blob(98, 22, 20, 16, ".", "", 2.1)                          # hautes terres nord-est
	blob(98, 62, 18, 14, ".", "", 0.7)                          # grande prairie est
	blob(46, 84, 22, 12, ".", "", 2.6)                          # rives du lac
	stroke([Vector2(50, 54), Vector2(40, 50), Vector2(30, 44), Vector2(23, 39)], 6, ".")
	blob(21, 38, 8, 6, ".", "", 0.4)                            # clairière ouest (menhir)
	stroke([Vector2(21, 33), Vector2(22, 26), Vector2(25, 20)], 5, ".")
	blob(27, 15, 10, 7, ".", "", 1.9)                           # étang caché nord-ouest
	stroke([Vector2(50, 60), Vector2(40, 64), Vector2(30, 68), Vector2(22, 72)], 5, ".")
	blob(19, 73, 10, 8, ".", "", 3.1)                           # éperon rocheux sud-ouest
	stroke([Vector2(57, 58), Vector2(54, 67), Vector2(50, 74)], 7, ".")
	stroke([Vector2(96, 70), Vector2(94, 80)], 8, ".")
	blob(90, 88, 15, 8, ".", "", 1.1)                           # prairie sud-est

	# Fleurs et sable.
	blob(102, 64, 9, 6, "\"", ".", 0.2)
	blob(52, 63, 4, 3, "\"", ".")
	blob(64, 23, 4, 3, "\"", ".")
	blob(23, 40, 3, 2, "\"", ".")
	blob(86, 88, 5, 3, "\"", ".")
	blob(45, 80, 16, 4, "s", ".\"", 0.9, 0.12)

	# Bosquets qui structurent les grandes prairies.
	blob(91, 67, 2.5, 2, "T", ".\"", 0.5)
	blob(110, 57, 3, 2.2, "T", ".\"", 1.5)
	blob(84, 15, 3, 3, "T", ".\"", 2.5)
	blob(30, 89, 3, 2, "T", ".\"", 0.8)
	blob(104, 83, 3, 2, "T", ".\"", 1.2)

	# Eau.
	stroke(river, 3.2, "~")
	blob(46, 85, 13, 6, "~", "", 0.5, 0.12)
	blob(27, 15, 4, 2.5, "~", "", 0.0, 0.1)

	# Reliefs : plateaux, faces de falaise calculées, escaliers.
	# Bord sud aplati : une longue façade de falaise lisible plutôt qu'une suite de gradins.
	blob(58, 17, 7.5, 4.5, "#", ".\"", 1.0, 0.1)
	_flatten_south(48, 68, 20)
	blob(100, 18, 13, 8, "#", ".\"", 0.3, 0.14)
	_flatten_south(86, 115, 24)
	blob(16, 70, 5.5, 3.5, "#", ".", 2.0, 0.1)
	_flatten_south(9, 24, 72)
	_faces()
	_stairs(57, 2, 18)
	_stairs(99, 2, 22)
	_stairs(16, 2, 70)

	# Chemins (ponts automatiques sur l'eau).
	var on_ground := ".\"sT"
	stroke(_pts([53, 55, 46, 54, 40, 51, 36, 47, 31, 45, 26, 42, 23, 40]), 2, ":", on_ground)
	stroke(_pts([58, 52, 57, 46, 55, 41, 56, 35, 58, 30, 58, 24]), 2, ":", on_ground)
	stroke(_pts([56, 36, 62, 33, 68, 31, 74, 30, 79, 30, 84, 32, 88, 35, 91, 39]), 2, ":", on_ground, true)
	stroke(_pts([62, 55, 68, 56, 74, 55, 80, 56, 86, 58, 92, 59, 97, 61]), 2, ":", on_ground, true)
	stroke(_pts([86, 58, 87, 50, 89, 44, 92, 39, 96, 33, 99, 28]), 2, ":", on_ground)
	stroke(_pts([57, 59, 56, 63, 53, 67, 52, 71, 50, 75]), 2, ":", on_ground)
	stroke(_pts([52, 59, 46, 61, 40, 64, 34, 66, 28, 70, 22, 73, 17, 76]), 2, ":", on_ground)
	stroke(_pts([97, 61, 97, 66, 95, 72, 94, 78, 92, 85]), 2, ":", on_ground)
	blob(58, 55, 6, 4, ":", ".\"", 0.0, 0.1)                   # sol battu du campement

	# Campement (placé à la main).
	put(58, 55, "F")
	put(54, 53, "h"); put(63, 53, "h"); put(53, 58, "h")
	put(58, 58, "@")
	put(61, 58, "I"); put(64, 56, "k"); put(63, 58, "c"); put(64, 59, "c"); put(51, 55, "w")
	put(56, 56, "l"); put(60, 54, "l"); put(50, 52, "r"); put(66, 57, "r")
	for p in [Vector2i(47, 57), Vector2i(68, 51), Vector2i(66, 63), Vector2i(49, 49), Vector2i(62, 47)]:
		put(p.x, p.y, "t")

	# Repères et points de vue.
	put(60, 15, "M"); put(104, 13, "M"); put(20, 36, "M"); put(32, 13, "M")
	for p in [Vector2i(93, 14), Vector2i(109, 20), Vector2i(96, 22), Vector2i(14, 69)]:
		put(p.x, p.y, "R")
	for p in [Vector2i(90, 13), Vector2i(110, 15), Vector2i(106, 23), Vector2i(94, 19), Vector2i(53, 17), Vector2i(19, 69)]:
		put(p.x, p.y, "p")
	for p in [Vector2i(90, 52), Vector2i(108, 56), Vector2i(104, 72), Vector2i(86, 70), Vector2i(84, 86),
			Vector2i(26, 75), Vector2i(36, 85), Vector2i(64, 88), Vector2i(24, 18), Vector2i(66, 20)]:
		put(p.x, p.y, "t")
	for p in [Vector2i(112, 60), Vector2i(85, 26), Vector2i(115, 32)]:
		put(p.x, p.y, "p")
	put(98, 90, "R"); put(100, 86, "r"); put(110, 66, "R")

	_decorate()
	for y in H:
		for x in W:
			if (x < 2 or y < 2 or x >= W - 2 or y >= H - 2) and g[y][x] != "~":
				g[y][x] = "T"


## Bordures vivantes : buissons en lisière, roseaux au bord de l'eau, rochers au pied des falaises.
func _decorate() -> void:
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var c: String = g[y][x]
			var r := _h(x, y)
			if c == "." and _near(x, y, ":@F", 1) == 0:
				if _near(x, y, "T", 1) > 0:
					if r < 0.09:
						g[y][x] = "b"
					elif r < 0.12:
						g[y][x] = "t"
				elif _near(x, y, "~", 1) > 0 and r < 0.2:
					g[y][x] = "n"
				elif _near(x, y, "v", 1) > 0 and r < 0.12:
					g[y][x] = "r"
				elif r < 0.012:
					g[y][x] = "b"
			elif c == "#" and _near(x, y, "^", 2) == 0:
				if r < 0.04:
					g[y][x] = "r"
				elif r < 0.06:
					g[y][x] = "p"
			elif c == "~" and _near(x, y, "~", 2) == 24 and r < 0.06:
				g[y][x] = "o"


## Rabote le plateau sous `y_cut` et prolonge jusqu'à cette ligne les colonnes qui s'arrêtent juste avant.
func _flatten_south(x0: int, x1: int, y_cut: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y_cut + 1, H):
			if g[y][x] == "#":
				g[y][x] = "."
		if g[y_cut - 1][x] == "#" and g[y_cut - 2][x] == "#":
			g[y_cut][x] = "#"


func _faces() -> void:
	for y in H - 1:
		for x in W:
			if g[y][x] == "#" and g[y + 1][x] != "#":
				for k in [1, 2]:
					if y + k < H and g[y + k][x] != "#":
						g[y + k][x] = "v"


## Remplace les deux tuiles de face sous le bord du plateau par un escalier, sur `width` colonnes.
func _stairs(x0: int, width: int, from_y: int) -> void:
	for x in range(x0, x0 + width):
		for y in range(from_y, H - 2):
			if g[y][x] == "v":
				g[y][x] = "^"
				g[y + 1][x] = "^"
				if g[y + 2][x] in ["T", "v"]:
					g[y + 2][x] = "."
				break


# --- Primitives de dessin ----------------------------------------------------

func put(x: int, y: int, ch: String, only := "") -> void:
	if x >= 0 and y >= 0 and x < W and y < H and (only == "" or g[y][x] in only):
		g[y][x] = ch


## Ellipse aux bords irréguliers (ondulation fixe, sans hasard).
func blob(cx: float, cy: float, rx: float, ry: float, ch: String, only := "", phase := 0.0, amp := 0.18) -> void:
	for y in range(int(cy - ry * 1.3) - 1, int(cy + ry * 1.3) + 2):
		for x in range(int(cx - rx * 1.3) - 1, int(cx + rx * 1.3) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var a := atan2(dy, dx)
			var r := 1.0 + amp * (0.6 * sin(3.0 * a + phase) + 0.4 * sin(5.0 * a + 2.0 * phase))
			if dx * dx + dy * dy <= r * r:
				put(x, y, ch, only)


func stroke(points: Array, width: float, ch: String, only := "", bridge := false) -> void:
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * width
		var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * width
		for y in range(int(lo.y), int(hi.y) + 1):
			for x in range(int(lo.x), int(hi.x) + 1):
				var p := Vector2(x + 0.5, y + 0.5)
				if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) > width * 0.5:
					continue
				if bridge and x >= 0 and y >= 0 and x < W and y < H and g[y][x] == "~":
					g[y][x] = "="
				else:
					put(x, y, ch, only)


func _pts(flat: Array) -> Array:
	var out := []
	for i in range(0, flat.size(), 2):
		out.append(Vector2(flat[i], flat[i + 1]))
	return out


func _near(x: int, y: int, chars: String, radius: int) -> int:
	var count := 0
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if (dx != 0 or dy != 0) and x + dx >= 0 and y + dy >= 0 and x + dx < W and y + dy < H:
				if g[y + dy][x + dx] in chars:
					count += 1
	return count


static func _h(x: int, y: int) -> float:
	var n := (x * 73856093) ^ (y * 19349663) ^ 5381
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xFFFF) / 65535.0


func _write() -> void:
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	for row in g:
		f.store_line("".join(row))
	f.close()
