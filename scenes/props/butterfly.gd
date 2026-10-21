extends Node2D
## Papillon décoratif : tourne lentement autour de son point d'origine en battant des ailes.

const TEXTURE := preload("res://assets/art/fx/butterfly.png")
const COLORS := [Color8(250, 240, 200), Color8(246, 200, 90), Color8(240, 150, 190), Color8(170, 200, 250)]

## Graine déterministe fournie par le placeur (variations de couleur et de trajectoire).
var variant_seed := 0

var _sprite: Sprite2D
var _home := Vector2.ZERO
var _time := 0.0
var _speed := Vector2.ONE


func _ready() -> void:
	# Déplacé hors du rythme physique : pas d'interpolation physique.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	z_index = 2
	_home = position
	_time = float(variant_seed % 1000)
	_speed = Vector2(0.35 + (variant_seed % 7) * 0.05, 0.5 + (variant_seed % 5) * 0.06)
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.hframes = 2
	_sprite.modulate = COLORS[variant_seed % COLORS.size()]
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	position = _home + Vector2(sin(_time * _speed.x) * 26.0, sin(_time * _speed.y) * 14.0 - 12.0)
	_sprite.frame = int(_time * 7.0) % 2
