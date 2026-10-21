class_name HeroMarker
extends Node2D
## Marqueur discret sous les pieds du héros : anneau ovale doré en pixels, à peine visible quand il est
## seul, plus net dès que des compagnons ou des ennemis l'entourent. En combat seulement, un petit chevron
## doré apparaît aussi au-dessus de sa tête, par-dessus la mêlée (l'anneau peut être caché par les troupes
## devant lui). Ni lueur ni animation permanente.

const GOLD := Color8(255, 214, 90)
const DARK := Color8(118, 78, 36)
## Demi-axes de l'anneau, en pixels (vue 3/4 : ovale aplati).
const RX := 11
const RY := 4
const ALPHA_ALONE := 0.4
const ALPHA_CROWD := 0.95
## Unités (alliés ou ennemis) à moins de cette distance au-delà desquelles le héros est « entouré ».
const CROWD_RADIUS := 48.0
const CROWD_COUNT := 2
const CHECK_EVERY := 0.25
## Un ennemi à moins de cette distance : combat, le chevron s'affiche.
const FIGHT_RADIUS := 96.0
## Hauteur du chevron, juste au-dessus de la barre de vie.
const PIP_Y := -35

var _target := ALPHA_ALONE
var _fighting := false
var _check := 0.0
var _pip := Node2D.new()


func _ready() -> void:
	modulate.a = ALPHA_ALONE
	# Au-dessus des personnages et des barres de vie (z 4).
	_pip.z_index = 5
	_pip.position = Vector2(0, PIP_Y + 1)
	_pip.modulate.a = 0.0
	_pip.draw.connect(_draw_pip)
	add_child(_pip)


func _process(delta: float) -> void:
	var hero := get_parent() as Combatant
	visible = hero.is_alive()
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_fighting = _count(hero, &"enemies", FIGHT_RADIUS) > 0
		var crowd := _count(hero, &"party_members", CROWD_RADIUS) + _count(hero, &"enemies", CROWD_RADIUS)
		_target = ALPHA_CROWD if _fighting or crowd >= CROWD_COUNT else ALPHA_ALONE
	modulate.a = move_toward(modulate.a, _target, 3.0 * delta)
	_pip.modulate.a = move_toward(_pip.modulate.a, 1.0 if _fighting else 0.0, 4.0 * delta)


func _count(hero: Node2D, group: StringName, radius: float) -> int:
	var n := 0
	for unit: Node2D in get_tree().get_nodes_in_group(group):
		if unit != hero and unit.global_position.distance_squared_to(hero.global_position) < radius * radius:
			n += 1
	return n


func _draw() -> void:
	var pixels := {}
	for i in 64:
		var a := TAU * i / 64.0
		pixels[Vector2i(roundi(cos(a) * RX), roundi(sin(a) * RY))] = true
	# Liseré brun un pixel plus bas : l'anneau se lit sur l'herbe comme sur la terre battue.
	for p: Vector2i in pixels:
		draw_rect(Rect2(Vector2(p) + Vector2(0, 1), Vector2.ONE), DARK)
	for p: Vector2i in pixels:
		draw_rect(Rect2(Vector2(p), Vector2.ONE), GOLD)


## Chevron pointé vers le bas (5 x 3 pixels), cerné de brun pour rester lisible sur tous les fonds.
func _draw_pip() -> void:
	var gold: Array[Vector2i] = [Vector2i(-2, -1), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1),
		Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	for p in gold:
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			_pip.draw_rect(Rect2(Vector2(p + d), Vector2.ONE), DARK)
	for p in gold:
		_pip.draw_rect(Rect2(Vector2(p), Vector2.ONE), GOLD)
