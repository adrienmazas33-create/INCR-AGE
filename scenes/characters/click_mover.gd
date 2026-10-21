class_name ClickMover
extends Node
## Déplacement à la souris : un clic gauche sur le sol envoie le héros à cet endroit par un chemin
## praticable. Un nouveau clic remplace le précédent ; une touche de déplacement l'interrompt aussitôt.
## Ce module ne fait que donner une direction au héros, comme le clavier : vitesse, combat automatique
## et suite des compagnons restent inchangés.

## Distance d'arrivée sur un point intermédiaire, puis sur la destination.
const PASS_RADIUS := 8.0
const ARRIVE_RADIUS := 3.0
## Sans rapprochement pendant ce délai, le chemin est recalculé (poussé par un sanglier, coincé).
const STUCK_TIME := 0.6
const MAX_REPLANS := 3
## Points du chemin examinés pour couper en ligne droite.
const LOOKAHEAD := 6

var _hero: Hero
var _grid: PathGrid
var _effects: Node2D
var _path := PackedVector2Array()
var _index := 0
var _goal := Vector2.ZERO
var _best := INF
var _stuck := 0.0
var _replans := 0


func setup(hero: Hero, grid: PathGrid, effects: Node2D) -> void:
	_hero = hero
	_grid = grid
	_effects = effects
	# Avant le héros, pour qu'il reçoive sa direction dans la même image.
	process_physics_priority = -1
	hero.knocked_out.connect(stop)


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	# Un clic sur l'interface (panneau du camp, même hors des boutons) n'est jamais un déplacement.
	if get_viewport().gui_get_hovered_control() != null:
		return
	get_viewport().set_input_as_handled()
	# Position tirée de l'événement (et non du curseur courant) : exacte aussi pour le toucher.
	go_to(_hero.get_canvas_transform().affine_inverse() * click.position)


## Envoie le héros vers `target` (pixels du monde). Faux si l'endroit est inaccessible.
func go_to(target: Vector2) -> bool:
	if not _hero.is_alive():
		return false
	_goal = target
	_replans = 0
	var ok := _plan()
	ClickMarker.spawn(_effects, target, ok)
	return ok


func is_moving() -> bool:
	return not _path.is_empty()


func stop() -> void:
	_path = PackedVector2Array()
	_hero.steer = Vector2.ZERO


func _plan() -> bool:
	_path = _grid.find_path(_hero.global_position, _goal, _hero.get_world_2d().direct_space_state)
	_index = 0
	_skip_ahead()
	if _path.is_empty():
		stop()
	return not _path.is_empty()


func _physics_process(delta: float) -> void:
	if _path.is_empty():
		return
	if not _hero.is_alive() or Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO:
		stop()
		return
	var last := _index == _path.size() - 1
	var to := _path[_index] - _hero.global_position
	if to.length() <= (ARRIVE_RADIUS if last else PASS_RADIUS):
		if last:
			stop()
			return
		_index += 1
		_skip_ahead()
		return
	if to.length() < _best - 0.5:
		_best = to.length()
		_stuck = 0.0
	else:
		_stuck += delta
	if _stuck > STUCK_TIME:
		# Tout près du but mais gêné par un décor : on considère qu'il est atteint.
		if last and to.length() < 12.0:
			stop()
			return
		_replans += 1
		if _replans > MAX_REPLANS:
			stop()
		else:
			_plan()
		return
	# Ralentissement à l'approche de la destination, pour s'arrêter net sans la dépasser.
	_hero.steer = to.normalized() * (clampf(to.length() / 12.0, 0.3, 1.0) if last else 1.0)


## Vise le point le plus lointain du chemin atteignable en ligne droite (sans zigzag case par case).
func _skip_ahead() -> void:
	_best = INF
	_stuck = 0.0
	for j in range(mini(_index + LOOKAHEAD, _path.size() - 1), _index, -1):
		if not _hero.test_move(Transform2D(0.0, _hero.global_position), _path[j] - _hero.global_position):
			_index = j
			return
