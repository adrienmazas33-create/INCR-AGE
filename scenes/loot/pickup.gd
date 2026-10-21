extends Node2D
## Butin au sol : jaillit, rebondit, puis file vers le membre du groupe le plus proche (aimant).
## Passe artistique 1 : scintillement périodique, aura violette du savoir, éclats au ramassage.

const TEXTURE := preload("res://assets/art/fx/pickups.png")
## Image de l'atlas par ressource (les matériaux alternent peau et os).
const FRAMES := {"food": [0], "materials": [1, 2], "knowledge": [3]}
const MAGNET_DELAY := 0.45
const GRAVITY := 520.0
const MAX_SPEED := 340.0
const TWINKLE := preload("res://assets/art/fx/twinkle.png")
const AURA := preload("res://assets/art/fx/glow.png")
## Couleur des éclats au ramassage, par ressource.
const SPARKLE := {"food": Color8(255, 150, 130), "materials": Color8(240, 200, 140), "knowledge": Color8(190, 160, 255)}

var kind := "food"

var _sprite := Sprite2D.new()
var _vel := Vector2.ZERO
var _z := 0.0
var _vz := 0.0
var _age := 0.0
var _speed := 0.0
var _bounced := false
var _twinkle := Sprite2D.new()
var _aura: Sprite2D


func launch(resource_kind: String, ground_velocity: Vector2, up_speed: float) -> void:
	kind = resource_kind
	_vel = ground_velocity
	_vz = up_speed
	var frames: Array = FRAMES[kind]
	_sprite.texture = TEXTURE
	_sprite.hframes = 4
	_sprite.frame = frames[randi() % frames.size()]


func _ready() -> void:
	if kind == "knowledge":
		z_index = 1
		# Aura violette au sol : le savoir est rare, il doit se voir de loin.
		_aura = Sprite2D.new()
		_aura.texture = AURA
		_aura.scale = Vector2(0.32, 0.32)
		_aura.modulate = Color(0.7, 0.45, 1.0)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_aura.material = mat
		add_child(_aura)
	add_child(_sprite)
	_twinkle.texture = TWINKLE
	_twinkle.hframes = 2
	_twinkle.visible = false
	add_child(_twinkle)


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
				AudioManager.play(&"pickup", global_position)
				CombatFx.sparkle(global_position, SPARKLE[kind])
				queue_free()
				return
		else:
			_speed = 0.0
	# Petit flottement au sol pour attirer l'œil.
	var bob := 0.0 if _z > 0.0 else roundf(sin(_age * 5.0) * 0.6)
	_sprite.position = Vector2(0, -6.0 - _z - bob).round()
	# Scintillement : bref éclat toutes les 1,6 s environ (décalé selon la position).
	var phase := fmod(_age + absf(position.x) * 0.013, 1.6)
	_twinkle.visible = _z <= 0.0 and _speed == 0.0 and phase < 0.24
	_twinkle.frame = 1 if phase > 0.08 and phase < 0.16 else 0
	_twinkle.position = _sprite.position + Vector2(3, -4)
	if _aura:
		_aura.modulate.a = 0.6 + 0.3 * sin(_age * 4.0)


func _nearest_collector() -> Node2D:
	var best: Node2D = null
	var best_d := Upgrades.magnet_radius()
	for m in get_tree().get_nodes_in_group(&"party_members"):
		var d := global_position.distance_to(m.global_position)
		if d < best_d:
			best = m
			best_d = d
	return best
