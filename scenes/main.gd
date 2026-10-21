extends Node2D
## Point d'entrée : assemble le monde, le groupe du héros, les ennemis, la caméra et l'interface ;
## gère le retour au camp quand le héros tombe ; raccourcis de confort du prototype.

const HERO := preload("res://scenes/characters/hero.tscn")

@onready var _world: World = $World
@onready var _camera: GameCamera = $GameCamera

var _hero: Hero
var _party: Party
var _hud: Hud


func _ready() -> void:
	_hero = HERO.instantiate() as Hero
	_hero.position = _world.spawn_position
	_world.add_entity(_hero)
	_party = Party.new()
	_party.name = "Party"
	add_child(_party)
	_party.setup(_hero, _world)
	var spawner := EnemySpawner.new()
	spawner.name = "EnemySpawner"
	add_child(spawner)
	spawner.setup(_world, _hero)
	_hud = Hud.new()
	add_child(_hud)
	CombatFx.layer = _world.effects
	CombatFx.camera = _camera
	_camera.target = _hero
	_camera.set_bounds(_world.bounds)
	_camera.snap_to_target()
	_hero.knocked_out.connect(_on_hero_down)
	DevCapture.attach_if_requested(self, _hero, _camera)


## Le héros tombe : courte pause, fondu, et tout le groupe se relève au campement, sans rien perdre.
func _on_hero_down() -> void:
	await get_tree().create_timer(1.2).timeout
	await _hud.fade_to(1.0, 0.35).finished
	_hero.revive_at(_world.spawn_position)
	for f in _party.followers:
		f.revive_full()
	get_tree().call_group(&"enemies", "reset_aggro")
	_camera.snap_to_target()
	await get_tree().create_timer(0.3).timeout
	_hud.fade_to(0.0, 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	elif event.is_action_pressed("quit"):
		get_tree().quit()
