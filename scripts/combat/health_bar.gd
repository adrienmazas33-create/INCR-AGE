class_name HealthBar
extends Node2D
## Petite barre de vie au-dessus d'une unité, visible seulement quand elle est entamée.

const WIDTH := 16
const PARTY_COLOR := Color8(118, 214, 92)
const HERO_COLOR := Color8(246, 206, 82)
const ENEMY_COLOR := Color8(232, 84, 62)

var health: Health
var color := PARTY_COLOR


func _ready() -> void:
	z_index = 4
	health.changed.connect(queue_redraw)


func _draw() -> void:
	var r := health.ratio()
	if r >= 1.0 or r <= 0.0:
		return
	var x0 := -WIDTH / 2.0
	draw_rect(Rect2(x0 - 1, -1, WIDTH + 2, 4), Color8(30, 20, 18))
	draw_rect(Rect2(x0, 0, WIDTH, 2), Color8(74, 52, 46))
	draw_rect(Rect2(x0, 0, ceilf(WIDTH * r), 2), color)
