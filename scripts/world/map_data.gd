class_name MapData
extends RefCounted
## Carte ASCII du monde : lecture, légende et requêtes par cellule.
## La légende complète est documentée dans data/maps/README.md.

enum Ground { GRASS, MEADOW, PATH, SAND, WATER, FOREST, PLATEAU, FACE, STAIRS, BRIDGE }

const GROUND_CHARS := {
	".": Ground.GRASS, "\"": Ground.MEADOW, ":": Ground.PATH, "s": Ground.SAND,
	"~": Ground.WATER, "o": Ground.WATER, "T": Ground.FOREST, "#": Ground.PLATEAU,
	"v": Ground.FACE, "^": Ground.STAIRS, "=": Ground.BRIDGE,
}
## Décors qui bloquent le passage (collision propre à chaque objet).
const SOLID_PROPS := "tpbrRhFclwkMI"
const SPAWN := "@"

var width := 0
var height := 0
var _rows := PackedStringArray()
var _ground := PackedByteArray()


static func load_from_file(path: String) -> MapData:
	var map := MapData.new()
	for line in FileAccess.get_file_as_string(path).split("\n", false):
		line = line.strip_edges(false, true)
		if not line.is_empty():
			map._rows.append(line)
	map.height = map._rows.size()
	map.width = map._rows[0].length() if map.height > 0 else 0
	map._compute_ground()
	return map


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func char_at(c: Vector2i) -> String:
	if not in_bounds(c) or c.x >= _rows[c.y].length():
		return "T"
	return _rows[c.y][c.x]


func ground_at(c: Vector2i) -> Ground:
	if not in_bounds(c):
		return Ground.FOREST
	return _ground[c.y * width + c.x] as Ground


func find_char(ch: String) -> Vector2i:
	for y in height:
		var x := _rows[y].find(ch)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


## Masque 8 bits (voir TileIds) des voisins dont le sol appartient à `kinds`. Hors carte = identique.
func neighbor_mask(c: Vector2i, kinds: Array) -> int:
	var mask := 0
	var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
		Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]
	for i in 8:
		var n: Vector2i = c + dirs[i]
		if not in_bounds(n) or ground_at(n) in kinds:
			mask |= 1 << i
	return mask


func is_cell_blocked(c: Vector2i) -> bool:
	var g := ground_at(c)
	return g == Ground.WATER or g == Ground.FOREST or g == Ground.FACE or char_at(c) in SOLID_PROPS


## Passage d'une cellule à sa voisine : on ne change de niveau que par un escalier.
func can_step(from: Vector2i, to: Vector2i) -> bool:
	if not in_bounds(to) or is_cell_blocked(to):
		return false
	var a := ground_at(from) == Ground.PLATEAU
	var b := ground_at(to) == Ground.PLATEAU
	if a and not b:
		return ground_at(to) == Ground.STAIRS and to.y == from.y + 1
	if b and not a:
		return ground_at(from) == Ground.STAIRS and to.y == from.y - 1
	return true


## Vérifie que toutes les cellules praticables sont accessibles depuis le point d'apparition.
func reachability_report() -> String:
	var start := find_char(SPAWN)
	if start.x < 0:
		return "ERREUR : aucun point d'apparition '@'."
	var seen := {}
	var total := 0
	for y in height:
		for x in width:
			if not is_cell_blocked(Vector2i(x, y)):
				total += 1
	var reached := _flood(start, seen).size()
	var pockets := []
	for y in height:
		for x in width:
			var c := Vector2i(x, y)
			if not is_cell_blocked(c) and not seen.has(c):
				var part := _flood(c, seen)
				pockets.append("%d cellule(s) vers %s" % [part.size(), c])
	var text := "Carte %dx%d : %d/%d cellules praticables accessibles depuis %s." % [width, height, reached, total, start]
	if not pockets.is_empty():
		text += "\nZones isolées : " + ", ".join(pockets.slice(0, 12))
	return text


func _flood(start: Vector2i, seen: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var stack: Array[Vector2i] = [start]
	seen[start] = true
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		out.append(c)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not seen.has(n) and can_step(c, n):
				seen[n] = true
				stack.append(n)
	return out


## Aperçu 4 px par cellule (outil de conception).
func save_preview(path: String) -> void:
	var colors := {
		Ground.GRASS: Color8(92, 156, 64), Ground.MEADOW: Color8(140, 186, 90), Ground.PATH: Color8(178, 128, 78),
		Ground.SAND: Color8(228, 204, 144), Ground.WATER: Color8(56, 120, 180), Ground.FOREST: Color8(34, 70, 40),
		Ground.PLATEAU: Color8(150, 170, 100), Ground.FACE: Color8(110, 98, 96), Ground.STAIRS: Color8(170, 160, 150),
		Ground.BRIDGE: Color8(140, 92, 52),
	}
	var img := Image.create_empty(width * 4, height * 4, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var c := Vector2i(x, y)
			img.fill_rect(Rect2i(x * 4, y * 4, 4, 4), colors[ground_at(c)])
			var ch := char_at(c)
			if ch in SOLID_PROPS or ch == "n":
				img.fill_rect(Rect2i(x * 4 + 1, y * 4 + 1, 2, 2), Color8(20, 20, 20) if ch != "h" else Color.ORANGE)
			elif ch == SPAWN:
				img.fill_rect(Rect2i(x * 4, y * 4, 4, 4), Color.RED)
	img.save_png(path)


func _compute_ground() -> void:
	_ground.resize(width * height)
	var props := []
	for y in height:
		for x in width:
			var ch := char_at(Vector2i(x, y))
			if GROUND_CHARS.has(ch):
				_ground[y * width + x] = GROUND_CHARS[ch]
			else:
				_ground[y * width + x] = Ground.GRASS
				props.append(Vector2i(x, y))
	# Sous un décor, le sol reprend le type majoritaire des voisins praticables.
	for c in props:
		var votes := {}
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ch := char_at(c + d)
			if GROUND_CHARS.has(ch):
				var g: Ground = GROUND_CHARS[ch]
				if g in [Ground.GRASS, Ground.MEADOW, Ground.PATH, Ground.SAND, Ground.PLATEAU]:
					votes[g] = votes.get(g, 0) + 1
		var best := Ground.GRASS
		for g in votes:
			if votes[g] > votes.get(best, 0):
				best = g
		_ground[c.y * width + c.x] = best
