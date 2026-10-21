class_name Ambience
extends Node
## Ambiances de nature et pas du héros (audio, lot B).
## - Prairie : vent doux et oiseaux épars, en fond partout.
## - Eau : murmure qui monte quand le héros approche d'une rivière ou du lac.
## - Pas : un son tous les STRIDE pixels parcourus, selon le sol sous le héros.
## Purement sonore : aucune règle de jeu.

const STRIDE := 21.0
const CHECK_EVERY := 0.3
## Rayon (en cases) dans lequel l'eau proche est entendue.
const WATER_RADIUS := 5
const MEADOW_DB := -21.0
const WATER_MAX_DB := -15.0
const SILENT_DB := -50.0
## Vitesse des fondus de volume (dB par seconde).
const FADE := 12.0
const STEPS := {
	MapData.Ground.GRASS: &"step_grass", MapData.Ground.MEADOW: &"step_grass",
	MapData.Ground.PATH: &"step_dirt", MapData.Ground.SAND: &"step_dirt",
	MapData.Ground.BRIDGE: &"step_wood",
	MapData.Ground.PLATEAU: &"step_stone", MapData.Ground.STAIRS: &"step_stone",
}

var _hero: Hero
var _map: MapData
var _meadow := AudioStreamPlayer.new()
var _water := AudioStreamPlayer.new()
var _meadow_db := SILENT_DB
var _water_db := SILENT_DB
var _check := 0.0
var _last := Vector2.ZERO
var _walked := 0.0


func setup(hero: Hero, map: MapData) -> void:
	_hero = hero
	_map = map
	_last = hero.global_position
	for p: AudioStreamPlayer in [_meadow, _water]:
		p.bus = AudioManager.AMBIENCE
		p.volume_db = SILENT_DB
		add_child(p)
	_meadow.stream = AudioManager.loop_stream(AudioManager.MEADOW_LOOP)
	_water.stream = AudioManager.loop_stream(AudioManager.WATER_LOOP)
	_meadow.play()
	_water.play()


func _process(delta: float) -> void:
	if _hero == null:
		return
	_steps()
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		var closeness := _water_closeness()
		_water_db = lerpf(SILENT_DB, WATER_MAX_DB, sqrt(closeness)) if closeness > 0.0 else SILENT_DB
		_meadow_db = MEADOW_DB
	# Fondus progressifs : rien ne s'allume ni ne se coupe d'un coup (ni au lancement).
	_meadow.volume_db = move_toward(_meadow.volume_db, _meadow_db, FADE * 0.5 * delta)
	_water.volume_db = move_toward(_water.volume_db, _water_db, FADE * delta)


func _steps() -> void:
	var pos := _hero.global_position
	var moved := pos.distance_to(_last)
	_last = pos
	# Téléportation (relève au camp, replacement) : pas de pas.
	if moved > 40.0 or not _hero.is_alive():
		return
	_walked += moved
	if _walked < STRIDE:
		return
	_walked = 0.0
	var id: StringName = STEPS.get(_map.ground_at(Vector2i(pos / TileIds.SIZE)), &"step_grass")
	AudioManager.play(id, pos)


## 0 (pas d'eau dans le rayon) à 1 (eau tout contre le héros).
func _water_closeness() -> float:
	var c := Vector2i(_hero.global_position / TileIds.SIZE)
	var best := INF
	for y in range(-WATER_RADIUS, WATER_RADIUS + 1):
		for x in range(-WATER_RADIUS, WATER_RADIUS + 1):
			var n := c + Vector2i(x, y)
			if _map.in_bounds(n) and _map.ground_at(n) == MapData.Ground.WATER:
				best = minf(best, Vector2(x, y).length())
	return 0.0 if best == INF else clampf(1.0 - (best - 1.0) / WATER_RADIUS, 0.0, 1.0)


## Bilan pour l'outil de test : volumes courants des ambiances.
func debug_summary() -> String:
	return "prairie %.0f dB, eau %.0f dB" % [_meadow.volume_db, _water.volume_db]
