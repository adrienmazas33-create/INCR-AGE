class_name Hero
extends CharacterBody2D
## Héros jouable : déplacement 8 directions réactif, animations de repos et de marche
## sur trois orientations (face, dos, profil retourné pour la gauche).

enum Facing { DOWN, UP, SIDE }

@export var max_speed := 100.0
## Accélération et freinage élevés : contrôle précis, sans glissade.
@export var acceleration := 1500.0
@export var deceleration := 2200.0

const IDLE_FRAMES := [0, 1]
const WALK_FRAMES := [2, 3, 4, 5]
const IDLE_FPS := 2.0
const WALK_FPS := 9.0

@onready var _sprite: Sprite2D = $Sprite

var _facing := Facing.DOWN
var _anim_time := 0.0
var _walking := false


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		# Virage franc : on ne conserve que la composante de vitesse dans la nouvelle direction.
		if velocity.dot(input) < 0.0:
			velocity = velocity.project(input.orthogonal())
		velocity = velocity.move_toward(input * max_speed, acceleration * delta)
		_update_facing(input)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	move_and_slide()


func _process(delta: float) -> void:
	var walking := velocity.length() > 12.0
	if walking != _walking:
		_walking = walking
		_anim_time = 0.0
	var frames: Array = WALK_FRAMES if walking else IDLE_FRAMES
	_anim_time += delta * (WALK_FPS * clampf(velocity.length() / max_speed, 0.6, 1.0) if walking else IDLE_FPS)
	_sprite.frame = _facing * _sprite.hframes + frames[int(_anim_time) % frames.size()]


func _update_facing(input: Vector2) -> void:
	# Diagonales : le profil l'emporte, il lit mieux la direction de marche.
	if absf(input.x) >= absf(input.y) * 0.7:
		_facing = Facing.SIDE
		_sprite.flip_h = input.x < 0.0
	else:
		_facing = Facing.DOWN if input.y > 0.0 else Facing.UP
