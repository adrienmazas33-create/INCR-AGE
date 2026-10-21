extends Node
## Son du jeu : trois bus réglables séparément (Musique, Effets, Ambiance), un petit catalogue de
## bruitages joués sans saturation, et un lecteur de musique prêt pour la future boucle d'exploration.
## Les bruitages viennent de tools/generate_sfx.gd (sons originaux) ; les remplacer par d'autres
## fichiers ne demande que de changer les chemins du catalogue.

const MUSIC := &"Music"
const SFX := &"SFX"
const AMBIENCE := &"Ambience"
const SETTINGS_PATH := "user://settings.cfg"
## Volumes par défaut (0 à 1) ; enregistrés dans settings.cfg, à part de la sauvegarde de partie.
const DEFAULT_VOLUMES := {MUSIC: 0.6, SFX: 0.7, AMBIENCE: 0.7}

## Bruitages : [fichier, volume en dB, variation de hauteur (±), lectures simultanées max,
## intervalle minimal entre deux départs en secondes]. Les deux derniers évitent les empilements. Niveaux revus
## à la baisse après écoute (nature discrète, pas subtils, marge d'environ 6 dB pour la future musique).
const SOUNDS := {
	&"hit": ["res://assets/audio/sfx/hit.wav", -11.0, 0.12, 2, 0.06],
	&"pickup": ["res://assets/audio/sfx/pickup.wav", -15.0, 0.05, 2, 0.08],
	&"buy": ["res://assets/audio/sfx/buy.wav", -13.0, 0.0, 1, 0.25],
	&"boar_grunt": ["res://assets/audio/sfx/boar_grunt.wav", -13.0, 0.1, 2, 0.4],
	&"boar_down": ["res://assets/audio/sfx/boar_down.wav", -12.0, 0.08, 2, 0.1],
	&"camp_stage": ["res://assets/audio/sfx/camp_stage.wav", -10.0, 0.0, 1, 1.0],
	# Pas du héros : discrets, sous les autres bruitages.
	&"step_grass": ["res://assets/audio/sfx/step_grass.wav", -25.0, 0.1, 2, 0.08],
	&"step_dirt": ["res://assets/audio/sfx/step_dirt.wav", -25.0, 0.1, 2, 0.08],
	&"step_wood": ["res://assets/audio/sfx/step_wood.wav", -23.0, 0.08, 2, 0.08],
	&"step_stone": ["res://assets/audio/sfx/step_stone.wav", -26.0, 0.1, 2, 0.08],
}
const FIRE_LOOP := "res://assets/audio/sfx/fire_loop.wav"
const MEADOW_LOOP := "res://assets/audio/sfx/meadow_loop.wav"
const WATER_LOOP := "res://assets/audio/sfx/water_loop.wav"
const POOL_SIZE := 12
## Distance (pixels) au-delà de laquelle un bruitage placé dans le monde n'est plus entendu.
const HEARING := 560.0

var _streams := {}
var _world_players: Array[AudioStreamPlayer2D] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _last_start := {}
var _music := AudioStreamPlayer.new()
var _volumes := DEFAULT_VOLUMES.duplicate()
var _muted := {}
## Nombre de bruitages joués et refusés (anti-empilement) : bilan de l'outil de test.
var played := 0
var skipped := 0
var counts := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: StringName in [MUSIC, SFX, AMBIENCE]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, &"Master")
	for id: StringName in SOUNDS:
		_streams[id] = load(SOUNDS[id][0])
	for i in POOL_SIZE:
		var p := AudioStreamPlayer2D.new()
		p.bus = SFX
		p.max_distance = HEARING
		add_child(p)
		_world_players.append(p)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = SFX
		add_child(p)
		_ui_players.append(p)
	_music.bus = MUSIC
	add_child(_music)
	# Sécurité : un limiteur doux sur la sortie empêche toute saturation si plusieurs sons coïncident.
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, limiter)
	_load_settings()
	GameState.upgrade_bought.connect(func(_id: String, _level: int) -> void: play(&"buy"))


## Joue un bruitage du catalogue ; `at` : position dans le monde (le son s'atténue avec la distance
## à la caméra), ou rien pour un son d'interface.
func play(id: StringName, at: Variant = null) -> void:
	var def: Array = SOUNDS[id]
	var now := Time.get_ticks_msec() / 1000.0
	var stream: AudioStream = _streams[id]
	var pool: Array = _world_players if at is Vector2 else _ui_players
	var busy := 0
	var free_player: Node = null
	for p in pool:
		if p.playing:
			busy += 1 if p.stream == stream else 0
		elif free_player == null:
			free_player = p
	if now - _last_start.get(id, -10.0) < def[4] or busy >= def[3] or free_player == null:
		skipped += 1
		return
	_last_start[id] = now
	played += 1
	counts[id] = counts.get(id, 0) + 1
	free_player.stream = stream
	free_player.volume_db = def[1]
	free_player.pitch_scale = 1.0 + randf_range(-def[2], def[2])
	if at is Vector2:
		(free_player as AudioStreamPlayer2D).global_position = at
	free_player.play()


## Lecteur d'ambiance en boucle (crépitement du feu), à placer dans le monde par l'appelant.
func make_fire_crackle() -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	p.stream = loop_stream(FIRE_LOOP)
	p.bus = AMBIENCE
	p.volume_db = -17.0
	p.max_distance = 300.0
	p.autoplay = true
	return p


## Son en boucle sans couture (ambiances) ; les fichiers sont générés pour boucler exactement.
func loop_stream(path: String) -> AudioStreamWAV:
	var stream := load(path) as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	return stream


## Musique (prévue : boucle d'exploration originale). Fondu sortant de l'ancienne, entrant de la nouvelle.
func play_music(stream: AudioStream, fade := 1.5) -> void:
	var tween := create_tween()
	if _music.playing:
		tween.tween_property(_music, "volume_db", -40.0, fade * 0.5)
	tween.tween_callback(func() -> void:
		_music.stream = stream
		_music.volume_db = -40.0
		if stream:
			_music.play())
	tween.tween_property(_music, "volume_db", 0.0, fade)


## Volume d'une catégorie (0 à 1), enregistré.
func set_volume(bus: StringName, linear: float) -> void:
	_volumes[bus] = clampf(linear, 0.0, 1.0)
	_apply(bus)
	_save_settings()


func set_muted(bus: StringName, muted: bool) -> void:
	_muted[bus] = muted
	_apply(bus)
	_save_settings()


func _apply(bus: StringName) -> void:
	var i := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(_volumes[bus], 0.0001)))
	AudioServer.set_bus_mute(i, _muted.get(bus, false) or _volumes[bus] <= 0.0)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var ok := cfg.load(SETTINGS_PATH) == OK
	for bus: StringName in DEFAULT_VOLUMES:
		if ok:
			_volumes[bus] = clampf(float(cfg.get_value("audio", String(bus), DEFAULT_VOLUMES[bus])), 0.0, 1.0)
			_muted[bus] = bool(cfg.get_value("audio", String(bus) + "_muted", false))
		_apply(bus)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	for bus: StringName in DEFAULT_VOLUMES:
		cfg.set_value("audio", String(bus), _volumes[bus])
		cfg.set_value("audio", String(bus) + "_muted", _muted.get(bus, false))
	cfg.save(SETTINGS_PATH)
