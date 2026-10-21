class_name CampCompass
extends Node2D
## Indicateur de direction du campement : quand le feu de camp sort de l'écran, un petit médaillon
## (flamme) glisse le long du bord, une flèche dorée pointe vers le camp et la distance s'affiche
## en tuiles. Il s'efface dès que le camp revient dans le champ. Purement visuel.

## Marge entre le bord de l'écran et le médaillon.
const EDGE := 16.0
## Zone réservée au compteur de ressources (coin haut droit) : le médaillon passe en dessous.
const COUNTER_ZONE := Vector2(64, 56)
const FADE_SPEED := 6.0
## La flèche s'oriente selon 16 directions : une rotation libre abîmerait le rendu pixel.
const DIRECTIONS := 16
const GOLD := Color8(255, 214, 90)
const RADIUS := 7.0

var _hero: Node2D
var _camp := Vector2.ZERO
var _distance := PixelText.new()
var _alpha := 0.0
var _angle := 0.0


func setup(hero: Node2D, camp: Vector2) -> void:
	_hero = hero
	_camp = camp


func _ready() -> void:
	add_child(_distance)
	modulate.a = 0.0


func _process(delta: float) -> void:
	if _hero == null:
		return
	var vp := get_viewport()
	var screen := vp.get_visible_rect()
	# Position du feu à l'écran (mêmes coordonnées logiques que l'interface).
	var camp_on_screen := vp.get_canvas_transform() * (_camp + Vector2(0, -8))
	var visible_now := screen.grow(-4.0).has_point(camp_on_screen)
	_alpha = move_toward(_alpha, 0.0 if visible_now else 1.0, FADE_SPEED * delta)
	modulate.a = _alpha
	if _alpha <= 0.0:
		return
	var center := screen.get_center()
	var dir := (camp_on_screen - center).normalized()
	_angle = snappedf(dir.angle(), TAU / DIRECTIONS)
	position = _edge_point(screen, center, Vector2.from_angle(_angle)).round()
	_distance.text = str(roundi(_hero.global_position.distance_to(_camp) / TileIds.SIZE))
	# Distance du côté opposé à la flèche, pour ne jamais la chevaucher.
	_distance.position = (-Vector2.from_angle(_angle) * (RADIUS + 7.0)).round()
	queue_redraw()


## Point où la demi-droite partant du centre touche le cadre intérieur (bords moins la marge),
## en évitant le compteur de ressources.
func _edge_point(screen: Rect2, center: Vector2, dir: Vector2) -> Vector2:
	var inner := screen.grow(-EDGE - RADIUS)
	var t := INF
	if dir.x > 0.001:
		t = minf(t, (inner.end.x - center.x) / dir.x)
	elif dir.x < -0.001:
		t = minf(t, (inner.position.x - center.x) / dir.x)
	if dir.y > 0.001:
		t = minf(t, (inner.end.y - center.y) / dir.y)
	elif dir.y < -0.001:
		t = minf(t, (inner.position.y - center.y) / dir.y)
	var p := center + dir * t
	if p.x > screen.end.x - COUNTER_ZONE.x and p.y < screen.position.y + COUNTER_ZONE.y:
		p.y = screen.position.y + COUNTER_ZONE.y + RADIUS
	return p


func _draw() -> void:
	# Flèche dorée orientée vers le camp, posée contre le médaillon.
	var tip := Vector2.from_angle(_angle) * (RADIUS + 7.0)
	var side := Vector2.from_angle(_angle + PI * 0.5) * 3.5
	var base := Vector2.from_angle(_angle) * (RADIUS + 1.0)
	var arrow := PackedVector2Array([tip, base + side, base - side])
	draw_colored_polygon(PackedVector2Array([tip * 1.15, (base + side * 1.4), (base - side * 1.4)]), UiFrame.OUTER)
	draw_colored_polygon(arrow, GOLD)
	# Médaillon : cuir sombre cerclé de bois, petite flamme au centre.
	draw_circle(Vector2.ZERO, RADIUS + 1.0, UiFrame.OUTER)
	draw_circle(Vector2.ZERO, RADIUS, UiFrame.WOOD)
	draw_circle(Vector2.ZERO, RADIUS - 2.0, UiFrame.LEATHER_DARK)
	for p in [[Vector2i(-1, 1), Color8(240, 112, 40)], [Vector2i(0, 1), Color8(255, 196, 70)], [Vector2i(1, 1), Color8(240, 112, 40)],
			[Vector2i(0, 0), Color8(255, 196, 70)], [Vector2i(-1, 0), Color8(242, 112, 40)], [Vector2i(0, -1), Color8(255, 244, 190)],
			[Vector2i(0, -2), Color8(255, 196, 70)], [Vector2i(1, -1), Color8(240, 112, 40)]]:
		draw_rect(Rect2(Vector2(p[0]) - Vector2(0.5, 0.5), Vector2.ONE), p[1])
