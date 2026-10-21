extends Node2D
## Feu de camp : flammes en 4 images, halo qui vacille doucement, fumée légère.
## Le village prospère (lot 3B) le remplace par un grand feu central (enlarge()).

const FPS := 8.0
const BIG_SHEET := preload("res://assets/art/fx/campfire_big.png")

@onready var _flames: Sprite2D = $Flames
@onready var _glow: Sprite2D = $Glow
@onready var _smoke: CPUParticles2D = $Smoke

var _time := 0.0
var _glow_size := 1.0


func _ready() -> void:
	if not GameSettings.ambient_effects:
		_smoke.emitting = false
		_glow.hide()


func _process(delta: float) -> void:
	_time += delta
	_flames.frame = int(_time * FPS) % _flames.hframes
	if not GameSettings.ambient_effects:
		return
	var flicker := 0.85 + 0.1 * sin(_time * 7.3) + 0.05 * sin(_time * 17.1)
	_glow.modulate.a = flicker
	_glow.scale = Vector2.ONE * _glow_size * (0.96 + 0.06 * flicker)


## Grand feu central : flammes plus hautes, couronne plus large, halo et fumée plus généreux.
func enlarge() -> void:
	_flames.texture = BIG_SHEET
	_flames.offset = Vector2(-24, -34)
	_glow_size = 1.5
	_glow.position = Vector2(0, -2)
	_smoke.amount = 10
	_smoke.position = Vector2(0, -24)
	($Body/Shape.shape as CircleShape2D).radius = 15.0
