class_name PropSpawner
extends RefCounted
## Place les décors de la carte dans le conteneur trié en Y : arbres, rochers, campement,
## roseaux et quelques papillons. Toutes les variations sont déterministes (hachage de cellule).

const ATLAS_TEXTURE := preload("res://assets/art/props.png")
const ATLAS_INDEX := "res://assets/art/props.json"
const CAMPFIRE := preload("res://scenes/props/campfire.tscn")
const BUTTERFLY := preload("res://scenes/props/butterfly.gd")
const T := TileIds.SIZE

## Caractère de carte -> sprites possibles, emprise de collision au pied (zéro = traversable),
## décalage aléatoire maximal (px).
const PROPS := {
	"t": {"sprites": ["tree_0", "tree_1", "tree_2"], "foot": Vector2(10, 6), "jitter": 5},
	"p": {"sprites": ["pine_0", "pine_1"], "foot": Vector2(8, 6), "jitter": 5},
	"b": {"sprites": ["bush_0", "bush_1"], "foot": Vector2(18, 6), "jitter": 4},
	"r": {"sprites": ["rock_small"], "foot": Vector2(14, 6), "jitter": 4},
	"R": {"sprites": ["rock_large"], "foot": Vector2(30, 10), "jitter": 2},
	"h": {"sprites": ["hut_0", "hut_1"], "foot": Vector2(50, 14), "jitter": 0},
	"c": {"sprites": ["crate"], "foot": Vector2(16, 8), "jitter": 2},
	"l": {"sprites": ["log"], "foot": Vector2(26, 6), "jitter": 2},
	"w": {"sprites": ["woodpile"], "foot": Vector2(24, 8), "jitter": 0},
	"k": {"sprites": ["rack"], "foot": Vector2(26, 4), "jitter": 0},
	"M": {"sprites": ["menhir"], "foot": Vector2(12, 6), "jitter": 0},
	"I": {"sprites": ["totem"], "foot": Vector2(10, 6), "jitter": 0},
	"n": {"sprites": ["reeds_0", "reeds_1"], "foot": Vector2.ZERO, "jitter": 6},
}
const FOREST_SPRITES := ["tree_0", "tree_2", "tree_0", "tree_1", "pine_0", "pine_1"]
const MAX_BUTTERFLIES := 14

var _map: MapData
var _atlas: Dictionary


func _init(map: MapData) -> void:
	_map = map
	_atlas = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_INDEX))


func spawn(entities: Node2D) -> void:
	_spawn_forest(entities)
	var butterflies := 0
	for y in _map.height:
		for x in _map.width:
			var c := Vector2i(x, y)
			var ch := _map.char_at(c)
			var anchor := Vector2(c * T) + Vector2(T * 0.5, T * 0.75)
			if PROPS.has(ch):
				_spawn_prop(entities, PROPS[ch], c, anchor)
			elif ch == "F":
				var fire := CAMPFIRE.instantiate()
				fire.position = anchor
				entities.add_child(fire)
			elif _map.ground_at(c) == MapData.Ground.MEADOW and GameSettings.ambient_effects \
					and butterflies < MAX_BUTTERFLIES and _rand(c, 9) < 0.035:
				var fly := BUTTERFLY.new()
				fly.position = anchor
				fly.variant_seed = _hash(c)
				entities.add_child(fly)
				butterflies += 1


func _spawn_prop(parent: Node2D, def: Dictionary, c: Vector2i, anchor: Vector2) -> void:
	var sprites: Array = def["sprites"]
	var jitter: float = def["jitter"]
	var pos := anchor + Vector2(_rand(c, 1) - 0.5, _rand(c, 2) - 0.5) * 2.0 * jitter
	var sprite := _make_sprite(sprites[_hash(c) % sprites.size()])
	sprite.flip_h = _rand(c, 3) < 0.5 and def["foot"].x < 40
	var foot: Vector2 = def["foot"]
	if foot == Vector2.ZERO:
		sprite.position = pos
		parent.add_child(sprite)
		return
	var body := StaticBody2D.new()
	body.position = pos
	var shape := RectangleShape2D.new()
	shape.size = foot
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -foot.y * 0.5)
	body.add_child(sprite)
	body.add_child(col)
	parent.add_child(body)


## Forêt dense : une rangée de la carte = un nœud trié en Y contenant ses arbres
## (moins de nœuds à trier, et des lots de dessin plus gros).
func _spawn_forest(entities: Node2D) -> void:
	for y in _map.height:
		var trees := []
		for x in _map.width:
			var c := Vector2i(x, y)
			if _map.ground_at(c) != MapData.Ground.FOREST:
				continue
			var edge := _forest_depth(c) <= 1
			# Rangées décalées en quinconce : couvert plus serré, sans grille visible.
			var stagger := 8.0 if y % 2 else -8.0
			var offset := Vector2(x * T + T * 0.5 + stagger + (_rand(c, 5) - 0.5) * 10.0, (_rand(c, 6) - 0.5) * 10.0)
			trees.append([offset, c, edge])
		if trees.is_empty():
			continue
		trees.sort_custom(func(a, b): return a[0].y < b[0].y)
		var row := Node2D.new()
		row.name = "ForestRow%d" % y
		row.position = Vector2(0, y * T + T * 0.75)
		for t in trees:
			var c: Vector2i = t[1]
			var sprite := _make_sprite(FOREST_SPRITES[_hash(c) % FOREST_SPRITES.size()])
			sprite.position = t[0]
			sprite.flip_h = _rand(c, 7) < 0.5
			# Les arbres du cœur de la forêt sont un peu plus sombres : profondeur.
			var shade := 1.0 if t[2] else 0.82 + _rand(c, 8) * 0.1
			sprite.modulate = Color(shade, shade, shade)
			row.add_child(sprite)
		entities.add_child(row)


func _forest_depth(c: Vector2i) -> int:
	for r in [1, 2]:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if _map.in_bounds(c + Vector2i(dx, dy)) and _map.ground_at(c + Vector2i(dx, dy)) != MapData.Ground.FOREST:
					return r
	return 3


func _make_sprite(sprite_name: String) -> Sprite2D:
	var info: Dictionary = _atlas[sprite_name]
	var r: Array = info["rect"]
	var pivot: Array = info["pivot"]
	var sprite := Sprite2D.new()
	sprite.texture = ATLAS_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(r[0], r[1], r[2], r[3])
	sprite.centered = false
	sprite.offset = -Vector2(pivot[0], pivot[1])
	return sprite


static func _hash(c: Vector2i, salt := 0) -> int:
	var n := (c.x * 73856093) ^ (c.y * 19349663) ^ (salt * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	return (n ^ (n >> 16)) & 0x7FFFFFFF


static func _rand(c: Vector2i, salt: int) -> float:
	return float(_hash(c, salt) & 0xFFFF) / 65535.0
