extends Node2D
## Point d'entrée : assemble le monde, le héros et la caméra ; raccourcis de confort du prototype.

const HERO := preload("res://scenes/characters/hero.tscn")

@onready var _world: World = $World
@onready var _camera: GameCamera = $GameCamera


func _ready() -> void:
	var hero := HERO.instantiate() as Hero
	hero.position = _world.spawn_position
	_world.add_entity(hero)
	_camera.target = hero
	_camera.set_bounds(_world.bounds)
	_camera.snap_to_target()
	DevCapture.attach_if_requested(self, hero, _camera)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	elif event.is_action_pressed("quit"):
		get_tree().quit()
