extends Node2D
## Villageois du campement : décor animé, sans collision ni combat. Il va et vient entre quelques
## points du camp et s'arrête un moment à chacun, tourné vers le feu.

const SPEED := 40.0
const SHADOW := preload("res://assets/art/fx/shadow.png")

## Points de passage (positions monde), parcourus en boucle.
var waypoints: Array[Vector2] = []
var fire := Vector2.ZERO
var skin: Texture2D

var _sprite := CharacterSprite.new()
var _target := 0
var _pause := 0.0
var _velocity := Vector2.ZERO


func _ready() -> void:
	# Déplacé hors du rythme physique : pas d'interpolation physique.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var shadow := Sprite2D.new()
	shadow.texture = SHADOW
	shadow.position = Vector2(0, -1)
	add_child(shadow)
	_sprite.texture = skin
	_sprite.hframes = 6
	_sprite.vframes = 3
	_sprite.offset = Vector2(0, -14)
	add_child(_sprite)
	_sprite.offset_phase(randf() * 2.0)
	_pause = randf_range(0.5, 2.0)


func _process(delta: float) -> void:
	_velocity = Vector2.ZERO
	if _pause > 0.0:
		_pause -= delta
		_sprite.face(fire - position)
	elif not waypoints.is_empty():
		var goal := waypoints[_target]
		if position.distance_to(goal) < 2.0:
			_target = (_target + 1) % waypoints.size()
			_pause = randf_range(2.0, 4.5)
		else:
			_velocity = position.direction_to(goal) * SPEED
			position = position.move_toward(goal, SPEED * delta)
			_sprite.face(_velocity)
	_sprite.animate(_velocity, 100.0, delta)
