class_name CampPanel
extends Control
## Panneau du feu de camp : glisse depuis la gauche quand le héros approche du feu, se range quand
## il s'éloigne. Une ligne par amélioration ; achat par clic, toucher, ou touches 1 à 4.
## Le héros reste pilotable pendant ce temps : rien ne change dans les commandes de base.

const WIDTH := 136.0
const ROW_H := 26.0
const HEADER_H := 15.0
const MARGIN := 6.0
const OPEN_RADIUS := 88.0
const SLIDE_SPEED := 5.0
const BG := Color8(48, 33, 27, 236)
const BORDER_DARK := Color8(22, 14, 12)
const BORDER_LIGHT := Color8(132, 94, 62)
const TITLE := Color8(255, 214, 90)

var _hero: Hero
var _camp := Vector2.ZERO
var _rows: Array[CampPanelRow] = []
var _slide := 0.0


func setup(hero: Hero, camp: Vector2) -> void:
	_hero = hero
	_camp = camp


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	size = Vector2(WIDTH, HEADER_H + ROW_H * Upgrades.ORDER.size() + 3)
	var title := PixelText.new()
	title.text = "FEU DE CAMP"
	title.modulate = TITLE
	title.position = Vector2(WIDTH * 0.5, 8)
	add_child(title)
	for i in Upgrades.ORDER.size():
		var row := CampPanelRow.new()
		row.id = Upgrades.ORDER[i]
		row.key = i + 1
		row.position = Vector2(2, HEADER_H + i * ROW_H)
		row.size = Vector2(WIDTH - 4, ROW_H - 2)
		row.pressed.connect(_buy.bind(row))
		add_child(row)
		_rows.append(row)
	GameState.resource_changed.connect(func(_k, _t): _refresh())
	GameState.upgrade_bought.connect(func(_id, _l): _refresh())
	_refresh()
	visible = false


func is_open() -> bool:
	return _slide > 0.5


func _process(delta: float) -> void:
	var near := _hero != null and _hero.is_alive() and _hero.global_position.distance_to(_camp) < OPEN_RADIUS
	_slide = move_toward(_slide, 1.0 if near else 0.0, SLIDE_SPEED * delta)
	visible = _slide > 0.0
	var t := 1.0 - pow(1.0 - _slide, 3.0)
	position = Vector2(roundf(lerpf(-WIDTH - 4.0, MARGIN, t)), roundf((get_viewport_rect().size.y - size.y) * 0.5))


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	for i in _rows.size():
		if event.is_action_pressed("buy_%d" % (i + 1)):
			_buy(_rows[i])
			get_viewport().set_input_as_handled()


func _buy(row: CampPanelRow) -> void:
	row.feedback(Upgrades.buy(row.id))


func _refresh() -> void:
	for row in _rows:
		row.refresh()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	draw_rect(Rect2(Vector2.ZERO, size), BORDER_DARK, false, 1.0)
	draw_line(Vector2(1, 1), Vector2(size.x - 1, 1), BORDER_LIGHT)
	draw_line(Vector2(1, 1), Vector2(1, size.y - 1), BORDER_LIGHT)
	draw_line(Vector2(4, HEADER_H - 2), Vector2(size.x - 4, HEADER_H - 2), BORDER_LIGHT)
