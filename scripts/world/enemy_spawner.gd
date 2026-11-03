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
## Champions (lot G1) : grands sangliers de repaires choisis, un par zone lointaine (DangerZones) :
## terres sauvages au nord-ouest, terres hostiles à l'est.
const CHAMPION_DENS: Array[Vector2i] = [Vector2i(29, 19), Vector2i(108, 70)]

var _world: World
var _hero: Node2D
## Repaires : {pos, variant, unit, timer, zone, champion} (camp pour les défenseurs d'un camp).
var _dens: Array[Dictionary] = []


func setup(world: World, hero: Node2D) -> void:
	_world = world
	_hero = hero
	for ch in VARIANTS:
		for c in world.map.find_all(ch):
			var den := {"pos": Vector2(c * TileIds.SIZE) + Vector2(16, 24), "variant": ch, "unit": null, "timer": 0.0,
				"champion": c in CHAMPION_DENS}
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


## Ennemi du repaire, renforcé selon sa zone (DangerZones) ; un champion porte son signe.
func _spawn(den: Dictionary) -> void:
	var zone := DangerZones.zone_at(den["pos"])
	var champion: bool = den.get("champion", false)
	var unit: Combatant
	if den["variant"] == "thrower":
		unit = THROWER.instantiate() as StoneThrower
	else:
		var v: Dictionary = VARIANTS[den["variant"]]
		unit = BOAR.instantiate() as Boar
		unit.stats = v["stats"]
		unit.get_node("Sprite").texture = v["skin"]
	unit.stats = DangerZones.scaled(unit.stats, zone, champion)
	unit.position = den["pos"]
	if champion:
		var mark := ChampionMark.new()
		mark.height = unit.bar_height + 4.0
		unit.add_child(mark)
	_track(den, unit)


func _track(den: Dictionary, unit: Node2D) -> void:
	_world.add_entity(unit)
	den["unit"] = unit
	var delay := DangerZones.CHAMPION_RESPAWN if den.get("champion", false) else RESPAWN_DELAY
	den["timer"] = delay
	unit.tree_exited.connect(func(): den["timer"] = delay)


## Ennemis debout par zone, et champions debout (outil de test).
func zone_summary() -> String:
	var per_zone := [0, 0, 0]
	var champions := 0
	for den in _dens:
		if is_instance_valid(den["unit"]) and (den["unit"] as Combatant).is_alive():
			per_zone[DangerZones.zone_at(den["pos"])] += 1
			champions += 1 if den.get("champion", false) else 0
	return "ennemis debout par zone %s, %d champion(s) debout" % [per_zone, champions]


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
