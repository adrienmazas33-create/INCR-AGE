class_name EnemyCamp
extends Node
## Camp ennemi capturable (lot 3) : le camp du clan rival sur le grand plateau nord-est.
## - ENNEMI : ses défenseurs (lanceurs, voir EnemySpawner.CAMP_DEFENDERS) sont présents ; bannière violette.
## - LIBÉRÉ : tous les défenseurs sont à terre ; la bannière tombe et un repère doré pulse au centre.
## - CAPTURÉ : le héros a rejoint le repère ; bannière dorée, rayons, arpège et bandeau, une seule fois.
## La capture est définitive et enregistrée aussitôt ; ses défenseurs ne réapparaissent plus.
## Avant la capture, la règle reste celle des repaires : un défenseur abattu réapparaît au bout de 45 s
## hors de vue, et une partie fermée retrouve tous ses défenseurs (les ennemis ne sont pas enregistrés).
## Le décor est dessiné, sans collision : il ne bloque aucun passage.

enum State { ENEMY, LIBERATED, CAPTURED }

## Camps connus (identifiants enregistrés dans la sauvegarde).
const KNOWN := ["plateau_ne"]
const ID := "plateau_ne"
## Case du repère central, et rayon autour de lui où le héros déclenche la capture.
const CENTER := Vector2i(99, 15)
const CAPTURE_RADIUS := 18.0
## Piquets et foyer éteint autour du centre (décalages en pixels).
const STAKES: Array[Vector2] = [Vector2(-70, 34), Vector2(84, 30), Vector2(-46, -70), Vector2(66, -66), Vector2(-96, -12)]
const FIRE_PIT := Vector2(36, 20)
const GOLD := Color8(255, 214, 90)
const RIVAL := Color8(108, 88, 116)
const RIVAL_DARK := Color8(52, 40, 58)
const BONE := Color8(226, 220, 200)
const WOOD := Color8(122, 86, 56)
const WOOD_DARK := Color8(59, 42, 34)
const STONE := Color8(139, 130, 124)
const STONE_DARK := Color8(82, 74, 82)
const SHADOW := Color(26 / 255.0, 26 / 255.0, 46 / 255.0, 0.35)

## Captures déclenchées pendant la partie (outil de test : jamais plus d'une).
static var captures := 0

var state := State.ENEMY

var _spawner: EnemySpawner
var _hero: Hero
var _hud: Hud
var _center := Vector2.ZERO
var _ground := Node2D.new()
var _pole := Node2D.new()
var _time := 0.0


## `ground_parent` : couche dessinée sous les personnages ; `entities` : couche triée en profondeur.
func setup(spawner: EnemySpawner, hero: Hero, hud: Hud, ground_parent: Node2D, entities: Node2D) -> void:
	_spawner = spawner
	_hero = hero
	_hud = hud
	_center = Vector2(CENTER * TileIds.SIZE) + Vector2(16, 24)
	_ground.position = _center
	_ground.draw.connect(_draw_ground)
	ground_parent.add_child(_ground)
	_pole.position = _center
	_pole.draw.connect(_draw_pole)
	entities.add_child(_pole)
	# Camp déjà pris dans la sauvegarde : affiché tel quel, sans rejouer la conquête.
	state = State.CAPTURED if GameState.is_camp_captured(ID) else State.ENEMY


func center() -> Vector2:
	return _center


func _process(delta: float) -> void:
	_time += delta
	if state == State.CAPTURED:
		return
	var alive := _spawner.camp_defenders_alive(ID)
	var next := State.LIBERATED if alive == 0 else State.ENEMY
	if next != state:
		state = next
		if state == State.LIBERATED:
			_hud.announce("CAMP LIBERE")
		_pole.queue_redraw()
	if state == State.LIBERATED:
		_ground.queue_redraw()
		_pole.queue_redraw()
		if _hero.is_alive() and _hero.global_position.distance_to(_center) <= CAPTURE_RADIUS:
			_capture()


func _capture() -> void:
	state = State.CAPTURED
	captures += 1
	GameState.capture_camp(ID)
	CombatFx.rays(_center + Vector2(0, -16), 1.4)
	CombatFx.burst(_center + Vector2(0, -20), GOLD)
	AudioManager.play(&"buy")
	_hud.announce("CAMP CONQUIS")
	_ground.queue_redraw()
	_pole.queue_redraw()


func _px(ci: CanvasItem, p: Vector2, s: Vector2, c: Color) -> void:
	ci.draw_rect(Rect2(p.round(), s), c)


## Sol : piquets courts, foyer éteint ; repère doré qui pulse quand le camp est libéré.
func _draw_ground() -> void:
	for s in STAKES:
		_px(_ground, s + Vector2(-1, 0), Vector2(5, 2), SHADOW)
		_px(_ground, s + Vector2(-1, -12), Vector2(3, 12), WOOD_DARK)
		_px(_ground, s + Vector2(-1, -12), Vector2(2, 11), WOOD)
		_px(_ground, s + Vector2(-2, -14), Vector2(5, 2), BONE)
		_px(_ground, s + Vector2(-1, -15), Vector2(3, 1), BONE)
	for i in 8:
		var a := TAU * i / 8.0
		var p := FIRE_PIT + Vector2(cos(a) * 6.0, sin(a) * 3.0)
		_px(_ground, p, Vector2(2, 2), STONE_DARK)
		_px(_ground, p, Vector2(1, 1), STONE)
	_px(_ground, FIRE_PIT + Vector2(-3, -1), Vector2(6, 2), Color8(40, 34, 32))
	if state == State.LIBERATED:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		for i in 32:
			var a := TAU * i / 32.0
			var r := 14.0 + pulse * 3.0
			_px(_ground, Vector2(cos(a) * r, sin(a) * r * 0.45), Vector2(2, 1), Color(GOLD, 0.6 + 0.4 * pulse))


## Mât central (trié en profondeur) : bannière du clan rival, bannière tombée au sol, ou bannière dorée.
func _draw_pole() -> void:
	_px(_pole, Vector2(-2, -1), Vector2(6, 2), SHADOW)
	if state == State.LIBERATED:
		# Mât abattu : couché au sol, bannière froissée ; flèche dorée au-dessus du repère.
		_px(_pole, Vector2(-14, -3), Vector2(26, 2), WOOD_DARK)
		_px(_pole, Vector2(-14, -4), Vector2(26, 1), WOOD)
		_px(_pole, Vector2(8, -6), Vector2(8, 4), RIVAL_DARK)
		var bob := roundf(sin(_time * 4.0) * 2.0)
		for k in 4:
			_px(_pole, Vector2(-k * 2, -34 + k * 2 + bob), Vector2(k * 4 + 2, 2), GOLD)
		_px(_pole, Vector2(-2, -44 + bob), Vector2(5, 8), GOLD)
		return
	_px(_pole, Vector2(-1, -44), Vector2(3, 44), WOOD_DARK)
	_px(_pole, Vector2(-1, -44), Vector2(2, 43), WOOD)
	var cloth := GOLD if state == State.CAPTURED else RIVAL
	var edge := Color8(176, 124, 52) if state == State.CAPTURED else RIVAL_DARK
	_px(_pole, Vector2(2, -43), Vector2(18, 13), edge)
	_px(_pole, Vector2(2, -43), Vector2(17, 12), cloth)
	# Bas de la bannière en queue d'aronde.
	_px(_pole, Vector2(9, -31), Vector2(4, 2), edge)
	# Emblème : os croisés pour le clan rival, cercle (soleil) pour notre tribu.
	if state == State.CAPTURED:
		_px(_pole, Vector2(9, -40), Vector2(4, 6), Color8(255, 244, 190))
		_px(_pole, Vector2(8, -39), Vector2(6, 4), Color8(255, 244, 190))
	else:
		for k in 4:
			_px(_pole, Vector2(7 + k * 2, -40 + k * 2), Vector2(2, 2), BONE)
			_px(_pole, Vector2(13 - k * 2, -40 + k * 2), Vector2(2, 2), BONE)
