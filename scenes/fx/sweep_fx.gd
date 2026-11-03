extends Node2D
## Effet de la frappe circulaire (lot G2) : un arc épais, blanc et or, fait le tour du héros en un
## éclair, laisse un cercle qui s'efface, et soulève quelques grains de poussière. En pixels entiers,
## sans flou.

const LIFETIME := 0.32
## Le balayage fait le tour pendant cette part de la durée, puis le cercle s'efface.
const SWEEP_PART := 0.55
const CORE := Color8(255, 248, 230)
const GOLD := Color8(255, 214, 90)
const EDGE := Color8(176, 124, 52)
const DUST := Color8(199, 162, 110)

var radius := 30.0
var _time := 0.0
var _dust: Array[Vector2] = []


func _ready() -> void:
	z_index = 5
	for i in 10:
		_dust.append(Vector2.from_angle(TAU * i / 10.0 + 0.3))


func _process(delta: float) -> void:
	_time += delta
	if _time >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _time / LIFETIME
	var sweep := minf(t / SWEEP_PART, 1.0)
	var fade := 1.0 if t < SWEEP_PART else 1.0 - (t - SWEEP_PART) / (1.0 - SWEEP_PART)
	# Cercle en vue de dessus (aplati), tracé point par point au pixel près.
	var steps := 72
	var head := sweep * steps
	for i in steps:
		var a := TAU * i / steps - PI * 0.5
		var p := Vector2(cos(a) * radius, sin(a) * radius * 0.55).round()
		var behind := head - i
		if behind < 0.0:
			continue
		# Tête de l'arc vive et épaisse, traîne qui s'amincit ; le cercle reste en filet doré.
		if behind < 10.0:
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 2)), Color(EDGE, fade))
			draw_rect(Rect2(p, Vector2(2, 1)), Color(CORE if behind < 4.0 else GOLD, fade))
		else:
			draw_rect(Rect2(p, Vector2(2, 1)), Color(GOLD, fade * 0.85))
	# Poussière soulevée qui s'écarte.
	for d in _dust:
		var p := (d * Vector2(radius * (0.6 + 0.5 * t), radius * 0.4 * (0.6 + 0.5 * t)) + Vector2(0, 6 - 4.0 * t)).round()
		draw_rect(Rect2(p, Vector2.ONE * (2.0 if t < 0.5 else 1.0)), Color(DUST, fade * 0.8))
