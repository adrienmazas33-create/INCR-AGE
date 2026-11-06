class_name CampPanelRow
extends Control
## Ligne du panneau du camp : touche, icône, nom, niveau, coût. Cliquable ou touchable.
## Une ligne encore verrouillée (lot G4) reste visible, grisée, avec le stade qui l'ouvrira.

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
const LOCKED := Color8(170, 150, 130)
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
	var art: Variant = Upgrades.DEFS[id]["icon"]
	if art is int:
		icon.texture = ICONS
		icon.hframes = 4
		icon.frame = art
	else:
		icon.texture = drawn_icon(art)
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
	var unlocked := Upgrades.is_unlocked(id)
	modulate.a = 1.0 if maxed or Upgrades.can_buy(id) else (0.62 if unlocked else 0.45)
	if not unlocked:
		var lock := PixelText.new()
		lock.align = 0.0
		lock.text = "STADE " + Upgrades.CAMP_NAMES[Upgrades.DEFS[id]["stage"] - 1]
		lock.modulate = LOCKED
		lock.position = Vector2(33, COST_Y)
		_add_cost(lock)
	elif maxed:
		var done := PixelText.new()
		done.align = 0.0
		done.text = "TRIBU PRETE" if id == Upgrades.AGE else "MAX"
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


## Icônes des lignes du lot G4, dessinées ici au pixel (cases 16 × 16, même contour que
## upgrade_icons.png) : FRAPPE (massue et tour), RECOLTE (baies et silex), AGE DES METAUX (lingot).
static var _drawn := {}


static func drawn_icon(kind: String) -> Texture2D:
	if _drawn.has(kind):
		return _drawn[kind]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	match kind:
		"skill":
			# Arc doré du tour sur soi, terminé par une pointe, autour d'une petite massue.
			for y in 16:
				for x in 16:
					var v := Vector2(x + 0.5 - 8.0, y + 0.5 - 8.0)
					var a := fposmod(v.angle(), TAU)
					if v.length() >= 5.3 and v.length() <= 6.8 and a > deg_to_rad(150):
						img.set_pixel(x, y, GOLD if a < deg_to_rad(300) else Color8(240, 170, 60))
			for p in [Vector2i(12, 8), Vector2i(13, 8), Vector2i(14, 8), Vector2i(15, 8), Vector2i(13, 9), Vector2i(14, 9), Vector2i(14, 10)]:
				img.set_pixelv(p, Color8(240, 170, 60))
			for i in 5:
				img.set_pixel(5 + i, 11 - i, Color8(128, 84, 48))
				img.set_pixel(6 + i, 11 - i, Color8(84, 52, 32))
			for y in range(4, 9):
				for x in range(8, 13):
					if Vector2(x + 0.5 - 10.0, y + 0.5 - 6.0).length() <= 2.3:
						img.set_pixel(x, y, Color8(168, 118, 70))
			img.set_pixel(9, 5, Color8(198, 152, 98))
		"harvest":
			# Grappe de baies et éclat de silex.
			for c in [Vector2(4.5, 9.5), Vector2(8.0, 10.5), Vector2(6.0, 6.5)]:
				for y in 16:
					for x in 16:
						var d: float = Vector2(x + 0.5, y + 0.5).distance_to(c)
						if d <= 2.4:
							img.set_pixel(x, y, Color8(196, 52, 66) if d > 1.0 or x > c.x else Color8(255, 150, 150))
			for p in [Vector2i(6, 3), Vector2i(7, 2), Vector2i(8, 2), Vector2i(7, 3)]:
				img.set_pixelv(p, Color8(107, 150, 72))
			for y in range(5, 14):
				var w := clampi(y - 4, 1, 3) if y < 9 else clampi(14 - y, 1, 3)
				for x in range(13 - w, 13 + w - 1):
					img.set_pixel(x, y, Color8(200, 214, 236) if x == 13 - w else Color8(84, 96, 124))
		"age":
			# Lingot de cuivre, promesse de l'âge des métaux.
			for y in range(6, 12):
				var inset := (11 - y) / 2
				for x in range(2 + inset, 14 - inset):
					var col := Color8(214, 124, 64)
					if y == 6 or x == 2 + inset:
						col = Color8(255, 190, 120)
					elif y == 11 or x == 13 - inset:
						col = Color8(150, 76, 40)
					img.set_pixel(x, y, col)
			img.set_pixel(5, 7, Color.WHITE)
			for p in [Vector2i(12, 2), Vector2i(12, 4), Vector2i(11, 3), Vector2i(13, 3)]:
				img.set_pixelv(p, GOLD)
	var src := img.duplicate() as Image
	for y in 16:
		for x in 16:
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < 16 and q.y < 16 and src.get_pixelv(q).a > 0.5:
					img.set_pixel(x, y, Color8(38, 22, 18))
					break
	_drawn[kind] = ImageTexture.create_from_image(img)
	return _drawn[kind]
