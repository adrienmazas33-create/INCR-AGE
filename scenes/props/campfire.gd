extends Node2D
## Feu de camp : flammes en 4 images, halo qui vacille doucement, fumée légère.

const FPS := 8.0

@onready var _flames: Sprite2D = $Flames
@onready var _glow: Sprite2D = $Glow
@onready var _smoke: CPUParticles2D = $Smoke

var _time := 0.0


func _ready() -> void:
	if not GameSettings.ambient_effects:
		_smoke.emitting = false
		_glow.hide()
		set_process(false)


func _process(delta: float) -> void:
	_time += delta
	_flames.frame = int(_time * FPS) % _flames.hframes
	var flicker := 0.85 + 0.1 * sin(_time * 7.3) + 0.05 * sin(_time * 17.1)
	_glow.modulate.a = flicker
	_glow.scale = Vector2.ONE * (0.96 + 0.06 * flicker)
