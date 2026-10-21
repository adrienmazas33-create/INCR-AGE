class_name World
extends Node2D
## Monde du prototype : construit terrain, collisions et décors depuis la carte ASCII.
## Les personnages (héros, plus tard soldats et ennemis) s'ajoutent via add_entity()
## pour être triés en profondeur avec les décors.

@export_file("*.txt") var map_path := "res://data/maps/prototype.txt"

@onready var _ground: TileMapLayer = $Ground
@onready var _water: TileMapLayer = $Water
@onready var _overlay: TileMapLayer = $Overlay
@onready var _collision: StaticBody2D = $Collision
@onready var _entities: Node2D = $Entities
## Couche des effets de combat, au-dessus des personnages.
@onready var effects: Node2D = $Effects

var map: MapData
## Limites du monde en pixels.
var bounds := Rect2()
var spawn_position := Vector2.ZERO
## Position du feu de camp (panneau des améliorations, recrues).
var camp_position := Vector2.ZERO


func _ready() -> void:
	map = MapData.load_from_file(map_path)
	TerrainBuilder.new(map).build(_ground, _water, _overlay, _collision)
	PropSpawner.new(map).spawn(_entities)
	bounds = Rect2(Vector2.ZERO, Vector2(map.width, map.height) * TileIds.SIZE)
	spawn_position = Vector2(map.find_char(MapData.SPAWN) * TileIds.SIZE) + Vector2(TileIds.SIZE * 0.5, TileIds.SIZE * 0.75)
	camp_position = Vector2(map.find_char("F") * TileIds.SIZE) + Vector2(TileIds.SIZE * 0.5, TileIds.SIZE * 0.75)
	if not GameSettings.ambient_effects:
		_water.material = null


## Conteneur trié en profondeur (décors ajoutés en cours de partie).
func entity_layer() -> Node2D:
	return _entities


func add_entity(node: Node2D) -> void:
	_entities.add_child(node)
