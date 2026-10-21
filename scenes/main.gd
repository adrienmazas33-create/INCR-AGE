extends Node2D
## Point d'entrée : assemble le monde, le groupe du héros, les ennemis, la caméra, l'interface,
## les améliorations et l'évolution du camp ; restaure la sauvegarde ; gère le retour au camp quand
## le héros tombe.

const HERO := preload("res://scenes/characters/hero.tscn")

@onready var _world: World = $World
@onready var _camera: GameCamera = $GameCamera

var _hero: Hero
var _party: Party
var _hud: Hud


func _ready() -> void:
	# La sauvegarde est restaurée en premier : groupe et camp se construisent d'après les améliorations.
	var saved_position: Variant = SaveGame.restore()
	_hero = HERO.instantiate() as Hero
	_hero.position = saved_position if _is_valid_hero_cell(saved_position) else _world.spawn_position
	_world.add_entity(_hero)
	_party = Party.new()
	_party.name = "Party"
	add_child(_party)
	_party.setup(_hero, _world, Upgrades.companion_count())
	var spawner := EnemySpawner.new()
	spawner.name = "EnemySpawner"
	add_child(spawner)
	spawner.setup(_world, _hero)
	_hud = Hud.new()
	add_child(_hud)
	var panel := CampPanel.new()
	panel.setup(_hero, _world.camp_position)
	_hud.add_panel(panel)
	var compass := CampCompass.new()
	compass.setup(_hero, _world.camp_position)
	_hud.add_panel(compass)
	var effects := UpgradeEffects.new()
	effects.name = "UpgradeEffects"
	add_child(effects)
	effects.setup(_party, _world.camp_position, _world.effects)
	var village := CampVillage.new()
	village.name = "CampVillage"
	add_child(village)
	village.setup(_world, _hud)
	CombatFx.layer = _world.effects
	CombatFx.camera = _camera
	_camera.target = _hero
	_camera.set_bounds(_world.bounds)
	_camera.snap_to_target()
	_hero.knocked_out.connect(_on_hero_down)
	SaveGame.hero_position_provider = func() -> Variant: return _hero.global_position if _hero.is_alive() else null
	SaveGame.start()
	_check_hero_not_stuck.call_deferred()
	DevCapture.attach_if_requested(self, _hero, _camera)


## Position enregistrée acceptée seulement dans la carte, sur une case praticable.
func _is_valid_hero_cell(pos: Variant) -> bool:
	if not pos is Vector2 or not _world.bounds.has_point(pos):
		return false
	return not _world.map.is_cell_blocked(Vector2i(pos / TileIds.SIZE))


## Après une physique à jour (bâtiments du camp compris) : un héros restauré dans un obstacle
## est ramené au point d'apparition (le groupe le suit d'un bloc).
func _check_hero_not_stuck() -> void:
	await get_tree().physics_frame
	var query := PhysicsPointQueryParameters2D.new()
	query.position = _hero.global_position + Vector2(0, -3)
	query.collision_mask = 1
	if not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty():
		push_warning("Position du héros restaurée dans un obstacle : retour au point d'apparition.")
		_hero.global_position = _world.spawn_position
		_hero.reset_physics_interpolation()
		_camera.snap_to_target()


## Le héros tombe : courte pause, fondu, et tout le groupe se relève au campement, sans rien perdre.
func _on_hero_down() -> void:
	await get_tree().create_timer(1.2).timeout
	await _hud.fade_to(1.0, 0.35).finished
	_hero.revive_at(_world.spawn_position)
	for f in _party.followers:
		f.revive_full()
	get_tree().call_group(&"enemies", "reset_aggro")
	_camera.snap_to_target()
	SaveGame.save_now()
	await get_tree().create_timer(0.3).timeout
	_hud.fade_to(0.0, 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	elif event.is_action_pressed("quit"):
		SaveGame.save_now()
		get_tree().quit()
