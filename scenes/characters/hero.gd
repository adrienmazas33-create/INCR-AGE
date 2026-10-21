class_name Hero
extends CharacterBody2D
## Héros jouable : déplacement 8 directions réactif ; l'animation est confiée à CharacterSprite.

@export var max_speed := 100.0
## Accélération et freinage élevés : contrôle précis, sans glissade.
@export var acceleration := 1500.0
@export var deceleration := 2200.0

@onready var _sprite: CharacterSprite = $Sprite


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		# Virage franc : on ne conserve que la composante de vitesse dans la nouvelle direction.
		if velocity.dot(input) < 0.0:
			velocity = velocity.project(input.orthogonal())
		velocity = velocity.move_toward(input * max_speed, acceleration * delta)
		_sprite.face(input)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	move_and_slide()


func _process(delta: float) -> void:
	_sprite.animate(velocity, max_speed, delta)
