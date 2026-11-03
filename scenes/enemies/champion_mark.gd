class_name ChampionMark
extends Node2D
## Signe d'un champion (lot G1) : un cercle rouge sombre au sol, et au-dessus de la tête un petit
## crâne cornu, cerné de noir, qui flotte doucement. Visible de loin, sans rien cacher du combat.
## Disparaît avec l'ennemi (enfant de son nœud).

const DANGER := Color8(226, 64, 52)
const DARK := Color8(58, 24, 30)
const BONE := Color8(236, 226, 200)
## Crâne cornu, 9 x 7 pixels (« b » os, « d » contour, « r » orbites rouges).
const SKULL := [
	"d.......d",
	"bd.ddd.db",
	".dbbbbbd.",
	".dbrbrbd.",
	".dbbbbbd.",
	"..dbdbd..",
	"...ddd...",
]

## Hauteur du crâne au-dessus des pieds, et demi-axes du cercle au sol.
var height := 40.0
var ring := Vector2(16, 6)
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.55 + 0.25 * sin(_time * 3.0)
	for i in 40:
		var a := TAU * i / 40.0
		draw_rect(Rect2(Vector2(cos(a) * ring.x, sin(a) * ring.y).round(), Vector2.ONE), Color(DANGER, pulse))
	var top := Vector2(-4, -height - 7 + roundf(sin(_time * 2.0)))
	for y in SKULL.size():
		var row: String = SKULL[y]
		for x in row.length():
			var c: Color
			match row[x]:
				"b": c = BONE
				"d": c = DARK
				"r": c = DANGER
				_: continue
			draw_rect(Rect2(top + Vector2(x, y), Vector2.ONE), c)
