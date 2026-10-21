class_name Hud
extends CanvasLayer
## Interface minimale : compteur des ressources en haut à droite, panneau du feu de camp (visible
## seulement près du feu) et voile noir pour les transitions (retour au camp).

const ICONS := preload("res://assets/art/fx/pickups.png")
## Ressource et image d'icône dans l'atlas du butin.
const ROWS := [["food", 0], ["materials", 1], ["knowledge", 3]]
const MARGIN := Vector2(6, 6)
const ROW_HEIGHT := 12.0
const BUMP_TIME := 0.25
const GAIN_COLOR := Color8(255, 214, 90)
const SPEND_COLOR := Color8(244, 100, 84)

var _panel := Node2D.new()
var _labels := {}
var _bumps := {}
var _bump_colors := {}
var _veil := ColorRect.new()


func _ready() -> void:
	layer = 10
	var back := ColorRect.new()
	back.color = Color(0.07, 0.05, 0.05, 0.45)
	back.position = Vector2(-44, -7)
	back.size = Vector2(46, ROWS.size() * ROW_HEIGHT + 2)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(back)
	for i in ROWS.size():
		var icon := Sprite2D.new()
		icon.texture = ICONS
		icon.hframes = 4
		icon.frame = ROWS[i][1]
		icon.position = Vector2(-7, i * ROW_HEIGHT)
		_panel.add_child(icon)
		var label := PixelText.new()
		label.align = 1.0
		label.position = Vector2(-15, i * ROW_HEIGHT)
		_panel.add_child(label)
		_labels[ROWS[i][0]] = label
		_bumps[ROWS[i][0]] = 0.0
	add_child(_panel)
	_veil.color = Color(0.03, 0.02, 0.03, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_veil)
	GameState.resource_changed.connect(_on_resource_changed)
	for kind in _labels:
		_labels[kind].text = str(GameState.resources[kind])


## Ajoute un panneau sous le voile de transition.
func add_panel(panel: Control) -> void:
	add_child(panel)
	move_child(panel, _veil.get_index())


func fade_to(alpha: float, duration: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(_veil, "color:a", alpha, duration)
	return tween


func _on_resource_changed(kind: String, total: int) -> void:
	# Doré quand le compteur monte, rouge quand une dépense le fait baisser.
	_bump_colors[kind] = SPEND_COLOR if total < int(_labels[kind].text) else GAIN_COLOR
	_labels[kind].text = str(total)
	_bumps[kind] = BUMP_TIME


func _process(delta: float) -> void:
	_panel.position = Vector2(get_viewport().get_visible_rect().size.x - MARGIN.x, MARGIN.y + 4)
	for i in ROWS.size():
		var kind: String = ROWS[i][0]
		_bumps[kind] = maxf(_bumps[kind] - delta, 0.0)
		var t: float = _bumps[kind] / BUMP_TIME
		# Petit saut et éclat coloré à chaque changement du compteur.
		_labels[kind].position.y = i * ROW_HEIGHT - roundf(t * 2.0)
		_labels[kind].modulate = Color.WHITE.lerp(_bump_colors.get(kind, GAIN_COLOR), t)
