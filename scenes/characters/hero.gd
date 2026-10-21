class_name Hero
extends Combatant
## Héros jouable. Le joueur dirige ses déplacements ; le héros frappe seul l'ennemi le plus proche
## à portée de massue. Les futures compétences actives seront des composants voisins de AutoAttack.

## Accélération et freinage élevés : contrôle précis, sans glissade.
@export var acceleration := 1500.0
@export var deceleration := 2200.0

var attack := AutoAttack.new()

var _move := Vector2.ZERO


func _ready() -> void:
	super()
	attack.unit = self
	add_child(attack)


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down") if is_alive() else Vector2.ZERO
	if input != Vector2.ZERO:
		# Virage franc : on ne conserve que la composante de vitesse dans la nouvelle direction.
		if _move.dot(input) < 0.0:
			_move = _move.project(input.orthogonal())
		_move = _move.move_toward(input * stats.move_speed, acceleration * delta)
		_anim().face(input)
	else:
		_move = _move.move_toward(Vector2.ZERO, deceleration * delta)
	velocity = _move + consume_knockback(delta)
	move_and_slide()
	if is_alive():
		var foe := Targeting.nearest(self, &"enemies", stats.attack_range)
		attack.try_attack(foe)
		# Immobile, le héros se tourne vers ce qu'il frappe.
		if foe and input == Vector2.ZERO and attack.is_swinging():
			_anim().face(foe.global_position - global_position)


func _animate(delta: float) -> void:
	_anim().animate(_move, stats.move_speed, delta)


func _on_hit(from: Vector2) -> void:
	CombatFx.party_hit(global_position + Vector2(0, -10), true)


func _on_died() -> void:
	remove_from_group(&"party_members")
	_move = Vector2.ZERO
	sprite.rotation_degrees = 90.0
	sprite.modulate = Color(0.75, 0.7, 0.7)
	super()


## Relève au campement, pleine santé.
func revive_at(pos: Vector2) -> void:
	global_position = pos
	health.restore(1.0)
	sprite.rotation_degrees = 0.0
	sprite.modulate = Color.WHITE
	add_to_group(&"party_members")
	reset_physics_interpolation()


func _anim() -> CharacterSprite:
	return sprite as CharacterSprite
