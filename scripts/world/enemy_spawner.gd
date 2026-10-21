class_name EnemySpawner
extends Node
## Place les ennemis aux repaires marqués sur la carte et les fait réapparaître lentement,
## jamais sous les yeux du joueur.

const BOAR := preload("res://scenes/enemies/boar.tscn")
## Caractère de carte -> variante.
const VARIANTS := {
	"g": {"stats": preload("res://data/units/boar_young.tres"), "skin": preload("res://assets/art/boar_0.png")},
	"G": {"stats": preload("res://data/units/boar_big.tres"), "skin": preload("res://assets/art/boar_1.png")},
}
const RESPAWN_DELAY := 45.0
const RESPAWN_MIN_DISTANCE := 10.0 * 32.0

var _world: World
var _hero: Node2D
## Repaires : {pos, variant, unit, timer}.
var _dens: Array[Dictionary] = []


func setup(world: World, hero: Node2D) -> void:
	_world = world
	_hero = hero
	for ch in VARIANTS:
		for c in world.map.find_all(ch):
			var den := {"pos": Vector2(c * TileIds.SIZE) + Vector2(16, 24), "variant": ch, "unit": null, "timer": 0.0}
			_dens.append(den)
			_spawn(den)


func _process(delta: float) -> void:
	for den in _dens:
		if is_instance_valid(den["unit"]):
			continue
		den["timer"] -= delta
		if den["timer"] <= 0.0 and _hero.global_position.distance_to(den["pos"]) > RESPAWN_MIN_DISTANCE:
			_spawn(den)


func _spawn(den: Dictionary) -> void:
	var v: Dictionary = VARIANTS[den["variant"]]
	var boar := BOAR.instantiate() as Boar
	boar.stats = v["stats"]
	boar.get_node("Sprite").texture = v["skin"]
	boar.position = den["pos"]
	_world.add_entity(boar)
	den["unit"] = boar
	den["timer"] = RESPAWN_DELAY
	boar.tree_exited.connect(func(): den["timer"] = RESPAWN_DELAY)
