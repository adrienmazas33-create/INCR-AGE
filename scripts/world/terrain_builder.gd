class_name TerrainBuilder
extends RefCounted
## Construit le TileSet à partir des atlas générés, remplit les couches de tuiles
## et crée les collisions du terrain (eau, forêt, falaises, rebords de plateau).

const ART := "res://assets/art/"
const SRC_BASE := 0
const G := MapData.Ground
const T := TileIds.SIZE
## Épaisseur (px) du rebord rocheux infranchissable des plateaux.
const RIM := 5

## Types de sol considérés comme « identiques » pour chaque famille d'auto-tuiles.
const AUTO_KINDS := {
	TileIds.Auto.PATH: [G.PATH, G.BRIDGE, G.STAIRS],
	TileIds.Auto.SAND: [G.SAND, G.WATER, G.BRIDGE],
	TileIds.Auto.WATER: [G.WATER, G.BRIDGE],
	TileIds.Auto.FOREST: [G.FOREST, G.WATER, G.FACE],
	TileIds.Auto.PLATEAU: [G.PLATEAU],
}
const AUTO_FOR_GROUND := {
	G.PATH: TileIds.Auto.PATH, G.SAND: TileIds.Auto.SAND, G.FOREST: TileIds.Auto.FOREST, G.PLATEAU: TileIds.Auto.PLATEAU,
}

var _map: MapData


func _init(map: MapData) -> void:
	_map = map


func build(ground: TileMapLayer, water: TileMapLayer, overlay: TileMapLayer, body: StaticBody2D) -> void:
	var tileset := _make_tileset()
	for layer in [ground, water, overlay]:
		layer.tile_set = tileset
	for y in _map.height:
		for x in _map.width:
			var c := Vector2i(x, y)
			match _map.ground_at(c):
				G.WATER, G.BRIDGE:
					_auto(water, c, TileIds.Auto.WATER)
					if _map.ground_at(c) == G.BRIDGE:
						overlay.set_cell(c, SRC_BASE, _bridge_tile(c))
					elif _map.char_at(c) == "o":
						overlay.set_cell(c, SRC_BASE, TileIds.LILY_PADS[_hash(c) % 2])
				G.GRASS:
					ground.set_cell(c, SRC_BASE, _grass_tile(c, 0.04))
				G.MEADOW:
					ground.set_cell(c, SRC_BASE, _grass_tile(c, 0.6))
				G.FACE:
					ground.set_cell(c, SRC_BASE, _face_tile(c))
				G.STAIRS:
					var top := _map.ground_at(c + Vector2i.UP) == G.PLATEAU
					ground.set_cell(c, SRC_BASE, TileIds.STAIRS_TOP if top else TileIds.STAIRS_BOTTOM)
				var g:
					_auto(ground, c, AUTO_FOR_GROUND[g])
			# Ombre portée au pied des falaises.
			if _map.ground_at(c + Vector2i.UP) == G.FACE and not _map.ground_at(c) in [G.FACE, G.STAIRS, G.WATER]:
				overlay.set_cell(c, SRC_BASE, TileIds.CLIFF_SHADOW)
	_build_collision(body)


func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_source(_atlas("terrain.png", 8, 4), SRC_BASE)
	for kind in TileIds.AUTO_FILES:
		ts.add_source(_atlas(TileIds.AUTO_FILES[kind], 16, 16), 1 + kind)
	return ts


func _atlas(file: String, cols: int, rows: int) -> TileSetAtlasSource:
	var src := TileSetAtlasSource.new()
	src.texture = load(ART + file)
	src.texture_region_size = Vector2i(T, T)
	for y in rows:
		for x in cols:
			src.create_tile(Vector2i(x, y))
	return src


func _auto(layer: TileMapLayer, c: Vector2i, kind: int) -> void:
	layer.set_cell(c, 1 + kind, TileIds.mask_coords(_map.neighbor_mask(c, AUTO_KINDS[kind])))


func _grass_tile(c: Vector2i, flower_chance: float) -> Vector2i:
	var r := _hash(c)
	var roll := (r % 1000) / 1000.0
	if roll < flower_chance:
		return TileIds.GRASS_FLOWERS[(r / 1000) % TileIds.GRASS_FLOWERS.size()]
	if roll < flower_chance + 0.16:
		return TileIds.GRASS_DETAIL[(r / 1000) % TileIds.GRASS_DETAIL.size()]
	return TileIds.GRASS[(r / 1000) % TileIds.GRASS.size()]


func _face_tile(c: Vector2i) -> Vector2i:
	var variant := 0
	if _map.ground_at(c + Vector2i.LEFT) != G.FACE:
		variant |= 1
	if _map.ground_at(c + Vector2i.RIGHT) != G.FACE:
		variant |= 2
	var top := _map.ground_at(c + Vector2i.UP) == G.PLATEAU
	return Vector2i((TileIds.FACE_TOP_COL if top else TileIds.FACE_BOTTOM_COL) + variant, TileIds.FACE_TOP_ROW)


func _bridge_tile(c: Vector2i) -> Vector2i:
	var is_water := func(d: Vector2i) -> bool: return _map.ground_at(c + d) == G.WATER
	var vertical: bool = is_water.call(Vector2i.LEFT) or is_water.call(Vector2i.RIGHT)
	var rails := 0
	if vertical:
		rails = (1 if is_water.call(Vector2i.LEFT) else 0) | (2 if is_water.call(Vector2i.RIGHT) else 0)
	else:
		rails = (1 if is_water.call(Vector2i.UP) else 0) | (2 if is_water.call(Vector2i.DOWN) else 0)
	return Vector2i(rails + (4 if vertical else 0), TileIds.BRIDGE_ROW)


## Collisions : rangées de cellules pleines fusionnées en rectangles, plus les rebords de plateau.
func _build_collision(body: StaticBody2D) -> void:
	for y in _map.height:
		var x := 0
		while x < _map.width:
			if not _is_solid(Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < _map.width and _is_solid(Vector2i(x, y)):
				x += 1
			_add_rect(body, Rect2(start * T, y * T, (x - start) * T, T))
	for y in _map.height:
		for x in _map.width:
			var c := Vector2i(x, y)
			if _map.ground_at(c) != G.PLATEAU:
				continue
			var o := Vector2(c * T)
			if _map.ground_at(c + Vector2i.UP) != G.PLATEAU:
				_add_rect(body, Rect2(o, Vector2(T, RIM)))
			if _map.ground_at(c + Vector2i.LEFT) != G.PLATEAU:
				_add_rect(body, Rect2(o, Vector2(RIM, T)))
			if _map.ground_at(c + Vector2i.RIGHT) != G.PLATEAU:
				_add_rect(body, Rect2(o + Vector2(T - RIM, 0), Vector2(RIM, T)))
	# Murs invisibles autour de la carte.
	var size := Vector2(_map.width, _map.height) * T
	for r in [Rect2(-T, -T, size.x + 2 * T, T), Rect2(-T, size.y, size.x + 2 * T, T),
			Rect2(-T, 0, T, size.y), Rect2(size.x, 0, T, size.y)]:
		_add_rect(body, r)


func _is_solid(c: Vector2i) -> bool:
	return _map.ground_at(c) in [G.WATER, G.FOREST, G.FACE]


func _add_rect(body: StaticBody2D, r: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = r.get_center()
	body.add_child(col)


static func _hash(c: Vector2i) -> int:
	var n := (c.x * 73856093) ^ (c.y * 19349663)
	n = (n ^ (n >> 13)) * 1274126177
	return (n ^ (n >> 16)) & 0x7FFFFFFF
