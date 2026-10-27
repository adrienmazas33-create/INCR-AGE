class_name CampPanel
extends Control
## Panneau du feu de camp : glisse depuis la gauche quand le héros approche du feu, se range quand
## il s'éloigne. Une ligne par amélioration ; achat par clic, toucher, ou touches 1 à 4.
## Sous les améliorations, la bande TROUPE : rôle de chaque compagnon et de la prochaine recrue.
## Le héros reste pilotable pendant ce temps : rien ne change dans les commandes de base.

const WIDTH := 140.0
const ROW_H := 26.0
## Haut du panneau (cadre et bandeau de titre) avant la première ligne.
const HEADER_H := 18.0
## Pied du panneau : stade du campement et progression vers le suivant.
const FOOTER_H := 15.0
## Bande TROUPE (titre et cases des compagnons).
const TROOP_H := 32.0
const BAR_WIDTH := 52.0
const MARGIN := 6.0
const OPEN_RADIUS := 88.0
const SLIDE_SPEED := 5.0
const TITLE := Color8(255, 214, 90)

var _hero: Hero
var _camp := Vector2.ZERO
var _rows: Array[CampPanelRow] = []
var _slide := 0.0
var _stage_label := PixelText.new()
var _party: Party


func setup(hero: Hero, camp: Vector2, party: Party = null) -> void:
	_hero = hero
	_camp = camp
	_party = party


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	size = Vector2(WIDTH, HEADER_H + ROW_H * Upgrades.ORDER.size() + TROOP_H + FOOTER_H + UiFrame.BORDER)
	_stage_label.align = 0.0
	_stage_label.modulate = TITLE
	_stage_label.position = Vector2(9, size.y - UiFrame.BORDER - FOOTER_H * 0.5)
	add_child(_stage_label)
	var title := PixelText.new()
	title.text = "FEU DE CAMP"
	title.modulate = TITLE
	title.position = Vector2(WIDTH * 0.5, 10)
	add_child(title)
	for i in Upgrades.ORDER.size():
		var row := CampPanelRow.new()
		row.id = Upgrades.ORDER[i]
		row.key = i + 1
		row.position = Vector2(UiFrame.BORDER, HEADER_H + i * ROW_H)
		row.size = Vector2(WIDTH - UiFrame.BORDER * 2.0, ROW_H - 2)
		row.pressed.connect(_buy.bind(row))
		add_child(row)
		_rows.append(row)
	var troop := TroopStrip.new()
	troop.party = _party
	troop.position = Vector2(UiFrame.BORDER, HEADER_H + Upgrades.ORDER.size() * ROW_H)
	troop.size = Vector2(WIDTH - UiFrame.BORDER * 2.0, TROOP_H - 2)
	add_child(troop)
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
	_stage_label.text = Upgrades.CAMP_NAMES[Upgrades.camp_stage() - 1]
	queue_redraw()
	for row in _rows:
		row.refresh()


func _draw() -> void:
	UiFrame.paint(self, Rect2(Vector2.ZERO, size), HEADER_H - UiFrame.BORDER - 2.0)
	# Pied : stade du campement et barre de progression vers le stade suivant.
	var foot_y := size.y - UiFrame.BORDER - FOOTER_H
	draw_rect(Rect2(UiFrame.BORDER, foot_y, size.x - UiFrame.BORDER * 2.0, 1), UiFrame.WOOD_DARK)
	var bar := Rect2(size.x - BAR_WIDTH - 9, foot_y + FOOTER_H * 0.5 - 2, BAR_WIDTH, 4)
	draw_rect(bar.grow(1), UiFrame.OUTER)
	draw_rect(bar, Color8(70, 50, 40))
	draw_rect(Rect2(bar.position, Vector2(roundf(BAR_WIDTH * Upgrades.camp_progress()), 4)), TITLE)
	draw_rect(Rect2(bar.position, Vector2(roundf(BAR_WIDTH * Upgrades.camp_progress()), 1)), TITLE.lightened(0.4))
