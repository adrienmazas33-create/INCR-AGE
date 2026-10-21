class_name AudioPanel
extends Control
## Petit panneau des volumes : musique, effets, nature. Un curseur et une case de coupure par
## catégorie ; réglages conservés au redémarrage (AudioManager, user://settings.cfg).
## S'ouvre et se ferme par la touche V ou le petit bouton à note de musique en bas à droite.

const BUSES: Array[StringName] = [AudioManager.MUSIC, AudioManager.SFX, AudioManager.AMBIENCE]
const NAMES := ["MUSIQUE", "EFFETS", "NATURE"]
const BOX_SIZE := Vector2(170, 84)
const BUTTON_SIZE := Vector2(15, 15)
const MARGIN := 6.0
const HEADER := 14.0
const ROW_Y := [30.0, 48.0, 66.0]
## Curseur et case de coupure, en coordonnées du panneau.
const TRACK_X := 64.0
const TRACK_W := 74.0
const TOGGLE_X := 148.0
const GOLD := Color8(255, 214, 90)
const MUTED := Color8(120, 110, 100)

var _button := Control.new()
var _box := Control.new()
var _dragging := -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c: Control in [_button, _box]:
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(c)
	_button.size = BUTTON_SIZE
	_button.tooltip_text = "Volumes (V)"
	_button.draw.connect(_draw_button)
	_button.gui_input.connect(_on_button_input)
	_box.size = BOX_SIZE
	_box.visible = false
	_box.draw.connect(_draw_box)
	_box.gui_input.connect(_on_box_input)
	var title := PixelText.new()
	title.text = "SON"
	title.position = Vector2(BOX_SIZE.x * 0.5, 10)
	_box.add_child(title)
	for i in NAMES.size():
		var label := PixelText.new()
		label.text = NAMES[i]
		label.align = 0.0
		label.position = Vector2(10, ROW_Y[i])
		_box.add_child(label)


func _process(_delta: float) -> void:
	var screen := get_viewport_rect().size
	_button.position = (screen - BUTTON_SIZE - Vector2(MARGIN, MARGIN)).round()
	_box.position = (screen - BOX_SIZE - Vector2(MARGIN, MARGIN * 2.0 + BUTTON_SIZE.y)).round()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_V:
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	_box.visible = not _box.visible
	_dragging = -1
	_button.queue_redraw()


func _on_button_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_toggle()
		_button.accept_event()


func _on_box_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT:
		if click.pressed:
			for i in BUSES.size():
				if absf(click.position.y - ROW_Y[i]) <= 6.0:
					if click.position.x >= TOGGLE_X - 2.0:
						AudioManager.set_muted(BUSES[i], not AudioManager.is_muted(BUSES[i]))
					elif click.position.x >= TRACK_X - 4.0:
						_dragging = i
						_slide(click.position.x, false)
		elif _dragging >= 0:
			# Le fichier de réglages n'est écrit qu'au relâchement.
			_slide(click.position.x, true)
			_dragging = -1
		_box.queue_redraw()
		_box.accept_event()
	elif event is InputEventMouseMotion and _dragging >= 0:
		_slide((event as InputEventMouseMotion).position.x, false)
		_box.queue_redraw()
		_box.accept_event()


func _slide(x: float, persist: bool) -> void:
	var value := snappedf(clampf((x - TRACK_X) / TRACK_W, 0.0, 1.0), 0.05)
	AudioManager.set_volume(BUSES[_dragging], value, persist)


func _draw_button() -> void:
	UiFrame.paint(_button, Rect2(Vector2.ZERO, BUTTON_SIZE))
	# Croche dorée : tête, hampe, crochet.
	var col := GOLD if _box.visible else UiFrame.STUD
	for p: Vector2i in [Vector2i(5, 9), Vector2i(6, 9), Vector2i(5, 10), Vector2i(6, 10), Vector2i(4, 10),
			Vector2i(7, 4), Vector2i(7, 5), Vector2i(7, 6), Vector2i(7, 7), Vector2i(7, 8), Vector2i(7, 9),
			Vector2i(8, 4), Vector2i(9, 5), Vector2i(9, 6)]:
		_button.draw_rect(Rect2(Vector2(p), Vector2.ONE), col)


func _draw_box() -> void:
	UiFrame.paint(_box, Rect2(Vector2.ZERO, BOX_SIZE), HEADER)
	for i in BUSES.size():
		var muted := AudioManager.is_muted(BUSES[i])
		var value := AudioManager.get_volume(BUSES[i])
		var y: float = ROW_Y[i]
		var col := MUTED if muted else GOLD
		# Curseur : rainure sombre, remplissage, petite poignée claire.
		_box.draw_rect(Rect2(TRACK_X - 1.0, y - 2.0, TRACK_W + 2.0, 5.0), UiFrame.OUTER)
		_box.draw_rect(Rect2(TRACK_X, y - 1.0, roundf(TRACK_W * value), 3.0), col)
		_box.draw_rect(Rect2(roundf(TRACK_X + TRACK_W * value) - 1.0, y - 3.0, 3.0, 7.0), UiFrame.STUD)
		# Case de coupure : pleine quand le son est actif, croix quand il est coupé.
		_box.draw_rect(Rect2(TOGGLE_X, y - 4.0, 9.0, 9.0), UiFrame.OUTER)
		_box.draw_rect(Rect2(TOGGLE_X + 1.0, y - 3.0, 7.0, 7.0), UiFrame.LEATHER_DARK)
		if muted:
			for k in 5:
				_box.draw_rect(Rect2(TOGGLE_X + 2.0 + k, y - 2.0 + k, 1.0, 1.0), MUTED)
				_box.draw_rect(Rect2(TOGGLE_X + 6.0 - k, y - 2.0 + k, 1.0, 1.0), MUTED)
		else:
			_box.draw_rect(Rect2(TOGGLE_X + 2.0, y - 2.0, 5.0, 5.0), GOLD)
