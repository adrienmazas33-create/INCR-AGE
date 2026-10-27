class_name TroopStrip
extends Control
## Bande « TROUPE » du panneau du camp : une case par place du groupe (huit au plus).
## - Case d'un compagnon : son rôle (lance ou fronde) ; un clic le réaffecte (gratuit, réversible).
## - Première case libre : rôle de la prochaine recrue, en transparence ; un clic le change.
## Le panneau n'est ouvert qu'au camp : la réaffectation n'est possible que là.

const SLOT := 14.0
const STEP := 16.0
const SLOTS_Y := 13.0
const GOLD := Color8(255, 214, 90)
const WOOD := Color8(150, 106, 64)
const WOOD_DARK := Color8(96, 64, 38)
const STONE := Color8(173, 162, 150)
const STONE_DARK := Color8(109, 100, 102)
const TIP := Color8(210, 214, 222)
const HOVER := Color8(86, 60, 44)

var party: Party

var _hover := -1
var _flash := {}
var _tick := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void:
		_hover = -1
		queue_redraw())
	var title := PixelText.new()
	title.text = "TROUPE"
	title.align = 0.0
	title.modulate = GOLD
	title.position = Vector2(4, 5)
	add_child(title)
	var hint := PixelText.new()
	hint.text = "CLIC POUR CHANGER"
	hint.align = 1.0
	hint.modulate = Color8(170, 150, 120)
	hint.position = Vector2(size.x - 3, 5)
	add_child(hint)
	GameState.roles_changed.connect(queue_redraw)
	GameState.upgrade_bought.connect(func(_id: String, _level: int) -> void: queue_redraw())


static func max_slots() -> int:
	return Upgrades.BASE_COMPANIONS + Upgrades.DEFS["recruit"]["max"]


func _process(delta: float) -> void:
	for i: int in _flash.keys():
		_flash[i] -= delta
		if _flash[i] <= 0.0:
			_flash.erase(i)
	# Redessin régulier : un compagnon mis K.O. ou relevé change d'aspect dans sa case.
	_tick -= delta
	if not _flash.is_empty() or _tick <= 0.0:
		_tick = 0.5
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion:
		var h := _slot_at(motion.position)
		if h != _hover:
			_hover = h
			queue_redraw()
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var i := _slot_at(click.position)
		if party and i >= 0 and i < party.followers.size():
			party.switch_role(i)
			party.followers[i].glow(GOLD, 0.6)
			_flash[i] = 0.3
		elif party and i == party.followers.size() and i < max_slots():
			GameState.set_next_recruit_role("spear" if GameState.next_recruit_role == "sling" else "sling")
			_flash[i] = 0.3
		accept_event()
		queue_redraw()


func _slot_at(p: Vector2) -> int:
	var i := int(floor((p.x - 4.0) / STEP))
	if i < 0 or i >= max_slots() or p.y < SLOTS_Y or p.y > SLOTS_Y + SLOT or p.x - 4.0 - i * STEP > SLOT:
		return -1
	return i


func _draw() -> void:
	if party == null:
		return
	var count := party.followers.size()
	for i in max_slots():
		var r := Rect2(4.0 + i * STEP, SLOTS_Y, SLOT, SLOT)
		var next := i == count
		if i > count:
			draw_rect(r, Color(UiFrame.OUTER, 0.5), false)
			continue
		draw_rect(r, UiFrame.OUTER)
		draw_rect(r.grow(-1), GOLD if _flash.has(i) else (HOVER if _hover == i else UiFrame.LEATHER_DARK))
		var role := GameState.next_recruit_role if next else party.followers[i].role
		var alpha := 0.45 if next else (0.5 if not party.followers[i].is_alive() else 1.0)
		_icon(r.position + Vector2(4, 2), role, alpha)
		if next:
			# Petit « + » : place de la prochaine recrue.
			draw_rect(Rect2(r.position + Vector2(10, 9), Vector2(3, 1)), Color(GOLD, 0.8))
			draw_rect(Rect2(r.position + Vector2(11, 8), Vector2(1, 3)), Color(GOLD, 0.8))


## Pictogramme du rôle : lance (hampe et pointe de pierre) ou fronde (lanière et pierre).
func _icon(at: Vector2, role: String, alpha: float) -> void:
	if role == "sling":
		for p: Vector2i in [Vector2i(1, 1), Vector2i(2, 2), Vector2i(2, 3), Vector2i(3, 4), Vector2i(3, 5), Vector2i(4, 6)]:
			draw_rect(Rect2(at + Vector2(p), Vector2.ONE), Color(WOOD, alpha))
		draw_rect(Rect2(at + Vector2(3, 7), Vector2(3, 3)), Color(STONE_DARK, alpha))
		draw_rect(Rect2(at + Vector2(3, 7), Vector2(2, 2)), Color(STONE, alpha))
		draw_rect(Rect2(at + Vector2(0, 0), Vector2(2, 2)), Color(WOOD_DARK, alpha))
	else:
		draw_rect(Rect2(at + Vector2(3, 3), Vector2(1, 8)), Color(WOOD, alpha))
		draw_rect(Rect2(at + Vector2(4, 3), Vector2(1, 8)), Color(WOOD_DARK, alpha))
		draw_rect(Rect2(at + Vector2(3, 0), Vector2(2, 3)), Color(TIP, alpha))
		draw_rect(Rect2(at + Vector2(2, 2), Vector2(4, 1)), Color(TIP, alpha))
