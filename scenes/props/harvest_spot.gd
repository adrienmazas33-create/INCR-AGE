extends Node2D
## Ressource à récolter (lot G3), dessinée par-dessus un décor de la carte : grappes de baies sur un
## buisson, éclats de silex au pied d'un rocher. Mûre, elle se voit ; cueillie, elle disparaît jusqu'à
## sa repousse (Exploration). Les buissons de la voie C portent eux-mêmes leurs baies (hidden_overlay).

## Baies : petites grappes rouges posées sur le feuillage (décalages depuis le pied du buisson).
const BERRY_SPOTS: Array[Vector2] = [Vector2(-6, -12), Vector2(3, -15), Vector2(6, -9), Vector2(-2, -7)]
const BERRY := Color8(196, 52, 66)
const BERRY_DARK := Color8(110, 24, 40)
const BERRY_LIGHT := Color8(255, 150, 150)
## Silex : trois éclats bleu-gris au pied du rocher, avec un reflet.
const FLINT_SPOTS: Array[Vector2] = [Vector2(-9, -2), Vector2(7, -1), Vector2(-3, 1)]
const FLINT := Color8(84, 96, 124)
const FLINT_DARK := Color8(42, 40, 58)
const FLINT_LIGHT := Color8(200, 214, 236)

var kind := "berries"
var hidden_overlay := false
var ripe := true:
	set(value):
		ripe = value
		queue_redraw()


func _draw() -> void:
	if not ripe or hidden_overlay:
		return
	if kind == "berries":
		for p in BERRY_SPOTS:
			draw_rect(Rect2(p + Vector2(-1, -1), Vector2(4, 3)), BERRY_DARK)
			draw_rect(Rect2(p, Vector2(2, 2)), BERRY)
			draw_rect(Rect2(p + Vector2(1, 1), Vector2(1, 1)), BERRY)
			draw_rect(Rect2(p, Vector2(1, 1)), BERRY_LIGHT)
	else:
		for p in FLINT_SPOTS:
			draw_rect(Rect2(p + Vector2(-1, -2), Vector2(6, 4)), FLINT_DARK)
			draw_rect(Rect2(p + Vector2(0, -1), Vector2(4, 2)), FLINT)
			draw_rect(Rect2(p + Vector2(1, -1), Vector2(2, 1)), FLINT_LIGHT)
