extends Node2D
## Butin au sol : jaillit, rebondit, puis file vers le membre du groupe le plus proche (aimant).

const TEXTURE := preload("res://assets/art/fx/pickups.png")
## Image de l'atlas par ressource (les matériaux alternent peau et os).
const FRAMES := {"food": [0], "materials": [1, 2], "knowledge": [3]}
const MAGNET_RADIUS := 96.0
const MAGNET_DELAY := 0.45
const GRAVITY := 520.0
const MAX_SPEED := 340.0

var kind := "food"

var _sprite := Sprite2D.new()
var _vel := Vector2.ZERO
var _z := 0.0
var _vz := 0.0
var _age := 0.0
var _speed := 0.0
var _bounced := false


func launch(resource_kind: String, ground_velocity: Vector2, up_speed: float) -> void:
	kind = resource_kind
	_vel = ground_velocity
	_vz = up_speed
	var frames: Array = FRAMES[kind]
	_sprite.texture = TEXTURE
	_sprite.hframes = 4
	_sprite.frame = frames[randi() % frames.size()]


func _ready() -> void:
	add_child(_sprite)
	if kind == "knowledge":
		z_index = 1


func _process(delta: float) -> void:
	_age += delta
	if _z > 0.0 or _vz > 0.0:
		_vz -= GRAVITY * delta
		_z += _vz * delta
		position += _vel * delta
		if _z <= 0.0:
			_z = 0.0
			if not _bounced:
				_bounced = true
				_vz = -_vz * 0.35
				_vel *= 0.4
			else:
				_vz = 0.0
	if _age > MAGNET_DELAY:
		var collector := _nearest_collector()
		if collector:
			_speed = minf(_speed + 900.0 * delta, MAX_SPEED)
			var aim := collector.global_position + Vector2(0, -8)
			global_position = global_position.move_toward(aim, _speed * delta)
			_z = move_toward(_z, 0.0, 60.0 * delta)
			if global_position.distance_to(aim) < 5.0:
				GameState.add(kind)
				queue_free()
				return
		else:
			_speed = 0.0
	# Petit flottement au sol pour attirer l'œil.
	var bob := 0.0 if _z > 0.0 else roundf(sin(_age * 5.0) * 0.6)
	_sprite.position = Vector2(0, -6.0 - _z - bob).round()


func _nearest_collector() -> Node2D:
	var best: Node2D = null
	var best_d := MAGNET_RADIUS
	for m in get_tree().get_nodes_in_group(&"party_members"):
		var d := global_position.distance_to(m.global_position)
		if d < best_d:
			best = m
			best_d = d
	return best
