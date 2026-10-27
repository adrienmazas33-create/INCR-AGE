class_name EnemySpawner
extends Node
## Place les ennemis aux repaires marqués sur la carte et les fait réapparaître lentement,
## jamais sous les yeux du joueur.
## Les rencontres de lanceurs de pierres sont des repaires fixes définis ici (la carte n'est pas modifiée).

const THROWER := preload("res://scenes/enemies/stone_thrower.tscn")
## Rencontre fixe de lanceur (case) : un lanceur isolé dans la prairie fleurie au pied de la colline
## nord (pour découvrir son attaque), loin des repaires de sangliers et de la sortie du camp.
const THROWER_DENS: Array[Vector2i] = [Vector2i(64, 23)]
## Défenseurs des camps ennemis capturables (lanceurs) : camp -> cases. Tant que le camp n'est pas pris,
## ils réapparaissent comme les autres ennemis ; une fois le camp capturé, plus jamais.
const CAMP_DEFENDERS := {"plateau_ne": [Vector2i(96, 14), Vector2i(104, 12)]}

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
	for camp: String in CAMP_DEFENDERS:
		for c: Vector2i in CAMP_DEFENDERS[camp]:
			var den := {"pos": Vector2(c * TileIds.SIZE) + Vector2(16, 24), "variant": "thrower", "unit": null, "timer": 0.0, "camp": camp}
			_dens.append(den)
			if not GameState.is_camp_captured(camp):
				_spawn(den)
	for c in THROWER_DENS:
		var den := {"pos": Vector2(c * TileIds.SIZE) + Vector2(16, 24), "variant": "thrower", "unit": null, "timer": 0.0}
		_dens.append(den)
		_spawn(den)


func _process(delta: float) -> void:
	for den in _dens:
		if is_instance_valid(den["unit"]) or GameState.is_camp_captured(den.get("camp", "")):
			continue
		den["timer"] -= delta
		if den["timer"] <= 0.0 and _hero.global_position.distance_to(den["pos"]) > RESPAWN_MIN_DISTANCE:
			_spawn(den)


func _spawn(den: Dictionary) -> void:
	if den["variant"] == "thrower":
		var thrower := THROWER.instantiate() as StoneThrower
		thrower.position = den["pos"]
		_track(den, thrower)
		return
	var v: Dictionary = VARIANTS[den["variant"]]
	var boar := BOAR.instantiate() as Boar
	boar.stats = v["stats"]
	boar.get_node("Sprite").texture = v["skin"]
	boar.position = den["pos"]
	_track(den, boar)


func _track(den: Dictionary, unit: Node2D) -> void:
	_world.add_entity(unit)
	den["unit"] = unit
	den["timer"] = RESPAWN_DELAY
	unit.tree_exited.connect(func(): den["timer"] = RESPAWN_DELAY)


## Défenseurs encore debout d'un camp (0 : camp libéré, ou capturé).
func camp_defenders_alive(camp: String) -> int:
	var n := 0
	for den in _dens:
		if den.get("camp", "") == camp and is_instance_valid(den["unit"]) and (den["unit"] as Combatant).is_alive():
			n += 1
	return n


## Cases des défenseurs d'un camp (outil de test).
func camp_defenders(camp: String) -> Array:
	var out := []
	for den in _dens:
		if den.get("camp", "") == camp and is_instance_valid(den["unit"]):
			out.append(den["unit"])
	return out
