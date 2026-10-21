class_name HealthBar
extends Node2D
## Petite barre de vie au-dessus d'une unité. Pour ne pas encombrer un groupe nombreux, elle n'apparaît
## que juste après un coup reçu, ou tant que la vie est sous la moitié.

const WIDTH := 16
const PARTY_COLOR := Color8(118, 214, 92)
const HERO_COLOR := Color8(246, 206, 82)
const ENEMY_COLOR := Color8(232, 84, 62)
## Durée d'affichage après un coup reçu, et seuil de vie sous lequel la barre reste visible.
const SHOW_AFTER_HIT := 2.5
const LOW_RATIO := 0.5

var health: Health
var color := PARTY_COLOR

var _shown := false


func _ready() -> void:
	z_index = 4
	health.changed.connect(queue_redraw)


func _process(_delta: float) -> void:
	var r := health.ratio()
	var shown := r > 0.0 and r < 1.0 and (health.since_damage() < SHOW_AFTER_HIT or r < LOW_RATIO)
	if shown != _shown:
		_shown = shown
		queue_redraw()


func _draw() -> void:
	if not _shown:
		return
	var r := health.ratio()
	var x0 := -WIDTH / 2.0
	draw_rect(Rect2(x0 - 1, -1, WIDTH + 2, 4), Color8(30, 20, 18))
	draw_rect(Rect2(x0, 0, WIDTH, 2), Color8(74, 52, 46))
	draw_rect(Rect2(x0, 0, ceilf(WIDTH * r), 2), color)
	# Liseré clair sur la partie pleine : la barre se lit mieux sur l'herbe.
	draw_rect(Rect2(x0, 0, ceilf(WIDTH * r), 1), color.lightened(0.35))
