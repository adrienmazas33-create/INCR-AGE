class_name CampPanelRow
extends Control
## Ligne du panneau du camp : touche, icône, nom, niveau, coût. Cliquable ou touchable.

signal pressed

const ICONS := preload("res://assets/art/fx/upgrade_icons.png")
const RESOURCE_ICONS := preload("res://assets/art/fx/pickups.png")
const RESOURCE_FRAME := {"food": 0, "materials": 1, "knowledge": 3}
const HOVER := Color8(86, 60, 44)
const KEY_BOX := Color8(30, 20, 17)
const PIP_ON := Color8(255, 214, 90)
const PIP_OFF := Color8(70, 50, 40)
const GOLD := Color8(255, 214, 90)
const RED := Color8(244, 100, 84)
const COST_Y := 18.0
const FEEDBACK_TIME := 0.35

var id := ""
var key := 1

var _content := Node2D.new()
var _name := PixelText.new()
var _level := PixelText.new()
var _cost: Array[Node2D] = []
var _hover := false
var _flash := 0.0
var _flash_color := GOLD
var _shake := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	add_child(_content)
	var digit := PixelText.new()
	digit.text = str(key)
	digit.position = Vector2(8, 8)
	digit.modulate = Color8(220, 200, 170)
	_content.add_child(digit)
	var icon := Sprite2D.new()
	icon.texture = ICONS
	icon.hframes = 4
	icon.frame = Upgrades.DEFS[id]["icon"]
	icon.position = Vector2(22, 12)
	_content.add_child(icon)
	_name.align = 0.0
	_name.position = Vector2(33, 7)
	_name.text = Upgrades.DEFS[id]["name"]
	_content.add_child(_name)
	_level.align = 1.0
	_level.position = Vector2(size.x - 3, 7)
	_content.add_child(_level)


## Remet à jour niveau, coût et couleurs selon les ressources actuelles.
func refresh() -> void:
	for n in _cost:
		n.queue_free()
	_cost.clear()
	var maxed := Upgrades.is_maxed(id)
	_level.text = "%d/%d" % [Upgrades.companion_count(), Upgrades.BASE_COMPANIONS + Upgrades.DEFS[id]["max"]] if id == "recruit" else ""
	modulate.a = 1.0 if maxed or Upgrades.can_buy(id) else 0.62
	if maxed:
		var done := PixelText.new()
		done.align = 0.0
		done.text = "MAX"
		done.modulate = GOLD
		done.position = Vector2(33, COST_Y)
		_add_cost(done)
	else:
		var x := 33.0
		var cost := Upgrades.cost(id)
		for kind in GameState.KINDS:
			if not cost.has(kind):
				continue
			var icon := Sprite2D.new()
			icon.texture = RESOURCE_ICONS
			icon.hframes = 4
			icon.frame = RESOURCE_FRAME[kind]
			icon.position = Vector2(x + 6, COST_Y)
			_add_cost(icon)
			var amount := PixelText.new()
			amount.align = 0.0
			amount.text = str(cost[kind])
			amount.modulate = Color.WHITE if GameState.resources[kind] >= cost[kind] else RED
			amount.position = Vector2(x + 13, COST_Y)
			_add_cost(amount)
			x += 13.0 + amount.text_width() + 5.0
	queue_redraw()


func feedback(success: bool) -> void:
	_flash = FEEDBACK_TIME
	_flash_color = GOLD if success else RED
	if not success:
		_shake = FEEDBACK_TIME


func _set_hover(on: bool) -> void:
	_hover = on
	queue_redraw()


func _add_cost(node: Node2D) -> void:
	_content.add_child(node)
	_cost.append(node)


func _gui_input(event: InputEvent) -> void:
	var tap: bool = event is InputEventScreenTouch and event.pressed
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if tap or click:
		pressed.emit()
		accept_event()


func _process(delta: float) -> void:
	if _flash <= 0.0 and _shake <= 0.0:
		return
	_flash = maxf(_flash - delta, 0.0)
	_shake = maxf(_shake - delta, 0.0)
	_content.position.x = (1.0 if int(_shake * 40.0) % 2 else -1.0) if _shake > 0.0 else 0.0
	queue_redraw()


func _draw() -> void:
	if _hover:
		draw_rect(Rect2(Vector2.ZERO, size), HOVER)
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(_flash_color, 0.35 * _flash / FEEDBACK_TIME))
	draw_rect(Rect2(3, 3, 10, 10), KEY_BOX)
	var maximum: int = Upgrades.DEFS[id]["max"]
	if id != "recruit":
		var lvl := Upgrades.level(id)
		for k in maximum:
			var x := size.x - 4.0 - (maximum - k) * 5.0
			draw_rect(Rect2(x, 4, 4, 4), PIP_ON if k < lvl else PIP_OFF)
