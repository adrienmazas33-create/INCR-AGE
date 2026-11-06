class_name Exploration
extends Node
## Récompenses d'exploration (lot G3).
## - Lieux à découvrir, une seule fois : pierres levées, anciens foyers, ossements de mammouth. Le héros
##   qui s'en approche les découvre : bandeau, éclat, et une récompense qui jaillit au sol (ramassée par
##   l'aimant du groupe, comme le butin), plus riche au loin (zones de DangerZones). Découvertes
##   enregistrées ; tant qu'un lieu n'est pas découvert, une étincelle dorée le signale de temps en temps.
## - Ressources à récolter en passant : baies sur certains buissons, éclats de silex sur certains
##   rochers. Le héros qui les frôle les cueille (le butin jaillit), puis elles repoussent lentement.
##   Leur état n'est pas enregistré : tout est mûr au lancement.

signal berries_changed(cell: Vector2i, ripe: bool)

const LANDMARK := preload("res://scenes/props/landmark.gd")
const HARVEST := preload("res://scenes/props/harvest_spot.gd")
const PICKUP := preload("res://scenes/loot/pickup.gd")

## Lieux : identifiant (enregistré) -> nature et case. Posés sur des clairières dégagées, dans chaque zone.
const LANDMARKS := {
	"menhir_ouest": {"kind": "menhir", "cell": Vector2i(24, 68)},
	"foyer_sud": {"kind": "hearth", "cell": Vector2i(64, 84)},
	"menhir_nord": {"kind": "menhir", "cell": Vector2i(80, 20)},
	"os_ouest": {"kind": "bones", "cell": Vector2i(16, 40)},
	"foyer_sudest": {"kind": "hearth", "cell": Vector2i(84, 92)},
	"os_est": {"kind": "bones", "cell": Vector2i(112, 64)},
	"menhir_plateau": {"kind": "menhir", "cell": Vector2i(104, 32)},
}
const NAMES := {"menhir": "PIERRE LEVEE", "hearth": "ANCIEN FOYER", "bones": "OSSEMENTS DE MAMMOUTH"}
## Récompense par nature et par zone (proches, sauvages, hostiles).
const REWARDS := {
	"menhir": {"knowledge": [1, 2, 3]},
	"hearth": {"food": [3, 5, 8], "knowledge": [1, 1, 2]},
	"bones": {"materials": [3, 5, 8], "knowledge": [1, 1, 2]},
}
## Distance (px) à laquelle le héros découvre un lieu, et cueille une ressource.
const DISCOVER_RADIUS := 40.0
const HARVEST_RADIUS := 26.0
## Récolte : ressource, quantité par zone, temps de repousse (s).
const BERRIES := {"kind": "food", "amount": [1, 2, 2], "regrow": 90.0}
const FLINT := {"kind": "materials", "amount": [1, 2, 2], "regrow": 120.0}
const T := TileIds.SIZE

## Récoltes faites pendant la partie (outil de test).
static var harvests := 0

var _hero: Hero
var _hud: Hud
var _entities: Node2D
## id -> nœud du lieu.
var _landmarks := {}
## Ressources : [{cell, def, node, timer, zone}].
var _spots: Array[Dictionary] = []


## Buissons à baies : les mêmes que la voie C dessine avec des baies (ZoneTemoin).
static func is_berry_bush(c: Vector2i) -> bool:
	return ZoneTemoin.hash_cell(c) % 3 == 0


## Rochers à silex : un sur deux.
static func is_flint_rock(c: Vector2i) -> bool:
	return PropSpawner.hash_cell(c) % 2 == 0


func setup(map: MapData, hero: Hero, hud: Hud, entities: Node2D) -> void:
	_hero = hero
	_hud = hud
	_entities = entities
	for id: String in LANDMARKS:
		var def: Dictionary = LANDMARKS[id]
		var node := LANDMARK.new()
		node.kind = def["kind"]
		node.position = Vector2(def["cell"] * T) + Vector2(T * 0.5, T * 0.75)
		node.discovered = id in GameState.discoveries
		entities.add_child(node)
		_landmarks[id] = node
	for c in map.find_all("b"):
		if is_berry_bush(c):
			_add_spot(c, BERRIES, "berries", PropSpawner.prop_position(c, "b"))
	for c in map.find_all("r"):
		if is_flint_rock(c):
			_add_spot(c, FLINT, "flint", PropSpawner.prop_position(c, "r"))


func _add_spot(c: Vector2i, def: Dictionary, kind: String, pos: Vector2) -> void:
	var node := HARVEST.new()
	node.kind = kind
	# Dans les zones témoins, les buissons de la voie C portent déjà leurs baies : pas de calque.
	node.hidden_overlay = kind == "berries" and ZoneTemoin.covers(c)
	node.position = pos + Vector2(0, 1)
	_entities.add_child(node)
	_spots.append({"cell": c, "def": def, "node": node, "timer": 0.0, "zone": DangerZones.zone_at(pos)})


func _process(delta: float) -> void:
	if not _hero.is_alive():
		return
	var at := _hero.global_position
	for id: String in _landmarks:
		var node: Node2D = _landmarks[id]
		if not node.discovered and at.distance_to(node.position) <= DISCOVER_RADIUS:
			_discover(id, node)
	for spot in _spots:
		var node: Node2D = spot["node"]
		if not node.ripe:
			spot["timer"] -= delta
			if spot["timer"] <= 0.0:
				_set_ripe(spot, true)
		elif at.distance_to(node.position) <= HARVEST_RADIUS:
			_harvest(spot)


func _discover(id: String, node: Node2D) -> void:
	node.discovered = true
	var kind: String = node.kind
	var zone := DangerZones.zone_at(node.position)
	GameState.discover(id)
	_hud.announce(NAMES[kind])
	CombatFx.rays(node.position + Vector2(0, -14), 1.0)
	CombatFx.burst(node.position + Vector2(0, -12), CombatFx.HERO_TINT)
	AudioManager.play(&"buy", node.position)
	var reward: Dictionary = REWARDS[kind]
	for res: String in reward:
		_spill(node.position, res, reward[res][zone])


func _harvest(spot: Dictionary) -> void:
	var def: Dictionary = spot["def"]
	var node: Node2D = spot["node"]
	harvests += 1
	_set_ripe(spot, false)
	# Amélioration RECOLTE (lot G4) : cueillette plus riche, repousse plus rapide.
	spot["timer"] = def["regrow"] * Upgrades.harvest_regrow_factor()
	_spill(node.position, def["kind"], def["amount"][spot["zone"]] + Upgrades.harvest_bonus())
	CombatFx.puff(node.position)


func _set_ripe(spot: Dictionary, ripe: bool) -> void:
	var node: Node2D = spot["node"]
	node.ripe = ripe
	if node.kind == "berries":
		berries_changed.emit(spot["cell"], ripe)


## Récompense qui jaillit au sol, ramassée ensuite par l'aimant du groupe (même butin que les ennemis).
func _spill(at: Vector2, kind: String, count: int) -> void:
	for i in count:
		var p := PICKUP.new()
		p.position = at + Vector2(0, -2)
		p.launch(kind, Vector2.from_angle(TAU * (i + 0.5) / count + randf() * 0.6) * randf_range(28.0, 56.0), randf_range(110.0, 150.0))
		_entities.add_child(p)


## Lieux découverts, ressources mûres (outil de test).
func summary() -> String:
	var ripe := {"berries": [0, 0], "flint": [0, 0]}
	for spot in _spots:
		var node: Node2D = spot["node"]
		ripe[node.kind][1] += 1
		if node.ripe:
			ripe[node.kind][0] += 1
	return "%d/%d lieux découverts %s ; baies mûres %d/%d, silex %d/%d ; %d récolte(s)" % [GameState.discoveries.size(),
		LANDMARKS.size(), GameState.discoveries, ripe["berries"][0], ripe["berries"][1], ripe["flint"][0], ripe["flint"][1], harvests]
