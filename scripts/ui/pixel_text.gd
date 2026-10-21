class_name PixelText
extends Node2D
## Texte en chiffres pixel art (police générée assets/art/fx/digits.png), net à toute échelle entière.

## Chargée à la demande (voir CombatFx : un autoload en dépend avant l'import des images).
const FONT_PATH := "res://assets/art/fx/digits.png"
static var _font: Texture2D
const GLYPHS := "0123456789+-"
const CELL := Vector2(6, 8)
const ADVANCE := 5.0

@export var text := "":
	set(value):
		text = value
		queue_redraw()
## Ancrage horizontal : 0 = gauche, 0.5 = centre, 1 = droite.
@export var align := 0.5


func text_width() -> float:
	return text.length() * ADVANCE + 1.0


func _draw() -> void:
	if _font == null:
		_font = load(FONT_PATH)
	var x := floorf(-text_width() * align)
	for ch in text:
		var i := GLYPHS.find(ch)
		if i >= 0:
			draw_texture_rect_region(_font, Rect2(Vector2(x, -CELL.y * 0.5), CELL), Rect2(Vector2(i * CELL.x, 0), CELL))
		x += ADVANCE
