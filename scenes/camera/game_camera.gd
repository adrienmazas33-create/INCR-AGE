class_name GameCamera
extends Camera2D
## Caméra de suivi : rattrapage exponentiel ferme (pas d'effet « flottant »), léger regard
## vers l'avant, zoom molette par paliers « pixel parfait », arrêt net aux bords de la carte.
## Mise à jour au rythme physique : l'interpolation physique la lisse comme le héros.

@export var follow_rate := 10.0
@export var look_ahead := 12.0
@export var look_rate := 3.0
@export var zoom_rate := 9.0
## Bornes des paliers de zoom (1.0 = résolution logique 640 x 360).
@export var min_zoom := 0.3
@export var max_zoom := 1.6

var target: CharacterBody2D

var _bounds := Rect2()
var _levels: Array[float] = []
var _level := 0
var _zoom := 1.0
var _look := Vector2.ZERO


func _ready() -> void:
	get_window().size_changed.connect(_rebuild_levels)
	_rebuild_levels()
	_zoom = _levels[_level]
	zoom = Vector2.ONE * _zoom


func set_bounds(rect: Rect2) -> void:
	_bounds = rect


## Place immédiatement la caméra sur la cible, sans transition.
func snap_to_target() -> void:
	_zoom = _levels[_level]
	zoom = Vector2.ONE * _zoom
	_look = Vector2.ZERO
	global_position = _clamp(target.global_position)
	reset_physics_interpolation()


func set_level(index: int, instant := false) -> void:
	_level = clampi(index, 0, _levels.size() - 1)
	if instant:
		snap_to_target()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		set_level(_level + 1)
	elif event.is_action_pressed("zoom_out"):
		set_level(_level - 1)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var goal := _levels[_level]
	if absf(_zoom - goal) > 0.001:
		# Interpolation en échelle logarithmique : vitesse de zoom perçue constante.
		_zoom = exp(lerpf(log(_zoom), log(goal), 1.0 - exp(-zoom_rate * delta)))
	else:
		_zoom = goal
	zoom = Vector2.ONE * _zoom
	var heading := target.velocity / maxf(target.velocity.length(), 1.0) * minf(target.velocity.length() / 60.0, 1.0)
	_look = _look.lerp(heading * look_ahead, 1.0 - exp(-look_rate * delta))
	var desired := target.global_position + _look
	global_position = _clamp(global_position.lerp(desired, 1.0 - exp(-follow_rate * delta)))


func _clamp(p: Vector2) -> Vector2:
	if not _bounds.has_area():
		return p
	var half := get_viewport_rect().size * 0.5 / _zoom
	var lo := _bounds.position + half
	var hi := _bounds.end - half
	return Vector2(
		_bounds.get_center().x if lo.x > hi.x else clampf(p.x, lo.x, hi.x),
		_bounds.get_center().y if lo.y > hi.y else clampf(p.y, lo.y, hi.y))


## Paliers où un pixel du jeu couvre un nombre entier de pixels écran (aucune déformation).
func _rebuild_levels() -> void:
	var base := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	var win := Vector2(get_window().size)
	if win.x <= 0.0 or win.y <= 0.0:
		return
	var scale := minf(win.x / base.x, win.y / base.y)
	var current := _levels[_level] if not _levels.is_empty() else 1.0
	_levels.clear()
	for pixels in range(1, 13):
		var z := pixels / scale
		if z >= min_zoom - 0.001 and z <= max_zoom + 0.001:
			_levels.append(z)
	if _levels.is_empty():
		_levels.append(1.0)
	_level = 0
	for i in _levels.size():
		if absf(_levels[i] - current) < absf(_levels[_level] - current):
			_level = i
