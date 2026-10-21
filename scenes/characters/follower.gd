class_name Follower
extends CharacterBody2D
## Allié qui accompagne le héros. Le groupe (Party) lui indique où aller ;
## l'allié s'y rend avec une arrivée douce et s'écarte de ses voisins.

## Un peu plus rapide que le héros pour pouvoir combler un retard.
@export var max_speed := 118.0
@export var acceleration := 1100.0
## Distance sous laquelle l'allié ralentit à l'approche de sa place.
@export var arrive_radius := 18.0

## Vitesse de référence de l'animation de marche (celle du héros).
const ANIM_SPEED := 100.0

var party: Party
var index := 0

@onready var _sprite: CharacterSprite = $Sprite

var _stuck_time := 0.0


func _ready() -> void:
	_sprite.offset_phase(index * 0.37)


func _physics_process(delta: float) -> void:
	var to := party.target_for(self) - global_position
	var dist := to.length()
	var desired := Vector2.ZERO
	if dist > 2.0:
		desired = to / dist * max_speed * clampf(dist / arrive_radius, 0.0, 1.0)
	desired += party.separation(self)
	velocity = velocity.move_toward(desired, acceleration * delta)
	var before := global_position
	move_and_slide()
	# Coincé : il veut avancer franchement mais ne progresse presque pas.
	var expected := desired.length() * delta
	if desired.length() > 40.0 and global_position.distance_to(before) < expected * 0.25:
		_stuck_time += delta
	else:
		_stuck_time = maxf(_stuck_time - delta * 2.0, 0.0)
	if party.should_regroup(self, _stuck_time):
		party.regroup(self)


func _process(delta: float) -> void:
	if velocity.length() > CharacterSprite.WALK_THRESHOLD:
		_sprite.face(velocity)
	elif party.hero_idle:
		_sprite.face(party.hero.global_position - global_position)
	_sprite.animate(velocity, ANIM_SPEED, delta)


## Replace l'allié sans transition (appelé par le groupe).
func teleport(to: Vector2) -> void:
	global_position = to
	velocity = Vector2.ZERO
	_stuck_time = 0.0
	reset_physics_interpolation()
