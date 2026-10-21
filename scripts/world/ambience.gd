class_name Ambience
extends Node
## Ambiances de nature et pas du héros (audio, lot B).
## - Prairie : vent doux en boucle, en fond partout.
## - Oiseaux : un chant de temps en temps, tiré parmi quatre motifs, à intervalles irréguliers
##   (souvent 5 à 15 s, parfois un long silence), hauteur, volume et côté variés : aucune boucle reconnaissable.
## - Eau : murmure qui monte quand le héros approche d'une rivière ou du lac.
## - Pas : un son tous les STRIDE pixels parcourus, selon le sol sous le héros.
## Purement sonore : aucune règle de jeu.

const STRIDE := 21.0
const CHECK_EVERY := 0.3
## Rayon (en cases) dans lequel l'eau proche est entendue.
const WATER_RADIUS := 5
## Niveaux revus à la baisse (nature en arrière-plan, marge pour la future musique).
const MEADOW_DB := -29.0
const WATER_MAX_DB := -22.0
const BIRD_DB := -27.0
const BIRDS := ["res://assets/audio/sfx/bird_0.wav", "res://assets/audio/sfx/bird_1.wav",
	"res://assets/audio/sfx/bird_2.wav", "res://assets/audio/sfx/bird_3.wav"]
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
var _bird := AudioStreamPlayer2D.new()
var _bird_streams: Array[AudioStream] = []
var _last_bird := -1
var _next_bird := 3.0
## Chants joués (bilan de l'outil de test).
var birds_sung := 0


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
	for path in BIRDS:
		_bird_streams.append(load(path))
	_bird.bus = AudioManager.AMBIENCE
	_bird.max_distance = 600.0
	add_child(_bird)


func _process(delta: float) -> void:
	if _hero == null:
		return
	_steps()
	_next_bird -= delta
	if _next_bird <= 0.0:
		_sing()
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		var closeness := _water_closeness()
		_water_db = lerpf(SILENT_DB, WATER_MAX_DB, sqrt(closeness)) if closeness > 0.0 else SILENT_DB
		_meadow_db = MEADOW_DB
	# Fondus progressifs : rien ne s'allume ni ne se coupe d'un coup (ni au lancement).
	_meadow.volume_db = move_toward(_meadow.volume_db, _meadow_db, FADE * 0.5 * delta)
	_water.volume_db = move_toward(_water.volume_db, _water_db, FADE * delta)


func _sing() -> void:
	# Un motif différent du précédent, placé à gauche ou à droite, plus ou moins loin.
	var k := randi_range(0, BIRDS.size() - 2)
	if k >= _last_bird:
		k += 1
	_last_bird = k
	_bird.stream = _bird_streams[k]
	_bird.pitch_scale = randf_range(0.9, 1.12)
	_bird.volume_db = BIRD_DB + randf_range(-4.0, 2.0)
	_bird.global_position = _hero.global_position + Vector2(randf_range(-260.0, 260.0), randf_range(-160.0, 80.0))
	_bird.play()
	birds_sung += 1
	# Intervalle irrégulier, avec de temps en temps un vrai silence.
	_next_bird = randf_range(20.0, 35.0) if randf() < 0.25 else randf_range(5.0, 15.0)


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
	return "prairie %.0f dB, eau %.0f dB, %d chant(s) d'oiseau" % [_meadow.volume_db, _water.volume_db, birds_sung]
