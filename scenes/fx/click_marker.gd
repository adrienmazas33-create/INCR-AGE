class_name ClickMarker
extends Node2D
## Repère bref au point cliqué : losange doré qui se resserre, ou croix rouge si l'endroit est inaccessible.

const LIFE := 0.45
const GOLD := Color8(255, 214, 90)
const RED := Color8(226, 64, 52)
const SHADOW := Color(0.1, 0.06, 0.04, 0.6)

var ok := true
var _t := 0.0


static func spawn(parent: Node2D, at: Vector2, reachable: bool) -> void:
	var m := ClickMarker.new()
	m.ok = reachable
	m.position = at.round()
	parent.add_child(m)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	modulate.a = 1.0 - _t / LIFE
	queue_redraw()


func _draw() -> void:
	var pixels: Array[Vector2i] = []
	if ok:
		var r := roundi(lerpf(7.0, 3.0, _t / LIFE))
		for i in r + 1:
			pixels.append_array([Vector2i(i, r - i), Vector2i(-i, r - i), Vector2i(i, i - r), Vector2i(-i, i - r)])
	else:
		for i in range(-3, 4):
			pixels.append_array([Vector2i(i, i), Vector2i(i, -i)])
	for p in pixels:
		draw_rect(Rect2(Vector2(p) + Vector2(0, 1), Vector2.ONE), SHADOW)
	for p in pixels:
		draw_rect(Rect2(Vector2(p), Vector2.ONE), GOLD if ok else RED)
