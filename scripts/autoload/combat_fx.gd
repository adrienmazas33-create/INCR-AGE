extends Node
## Retours du combat, appelables de partout : arcs de coup, étincelles, poussière, chiffres de dégâts,
## micro-pause d'impact et secousse de caméra. Réglages dans GameSettings.

const ONE_SHOT := preload("res://scenes/fx/one_shot_fx.gd")
const DAMAGE_NUMBER := preload("res://scenes/fx/damage_number.gd")
## Chargées à la demande : un autoload est compilé avant l'import des images sur un clone neuf.
const SLASH := "res://assets/art/fx/slash.png"
const SPARK := "res://assets/art/fx/spark.png"
const PUFF := "res://assets/art/fx/puff.png"

## Couche d'effets du monde (au-dessus des personnages) et caméra, fournies par la scène principale.
var layer: Node2D
var camera: GameCamera

var _stop_token := 0


## Arc du geste, orienté selon l'une des 8 directions (une rotation libre abîmerait le pixel art).
func slash(pos: Vector2, dir: Vector2) -> void:
	var fx := _spawn(SLASH, 3, 20.0, pos)
	if fx:
		fx.rotation = snappedf(dir.angle(), PI / 4.0)


func impact(pos: Vector2, by_hero: bool, kill: bool) -> void:
	_spawn(SPARK, 3, 24.0, pos)
	if kill:
		hit_stop(0.07)
		shake(2.0)
	elif by_hero:
		hit_stop(0.035)


## Coup reçu par le groupe : plus marqué quand c'est le héros.
func party_hit(pos: Vector2, is_hero: bool) -> void:
	_spawn(SPARK, 3, 24.0, pos)
	if is_hero:
		hit_stop(0.05)
		shake(3.0)
	else:
		shake(1.0)


func puff(pos: Vector2) -> void:
	_spawn(PUFF, 3, 14.0, pos)


func damage_number(pos: Vector2, amount: float, taken_by_party: bool) -> void:
	if layer == null:
		return
	var n := DAMAGE_NUMBER.new()
	n.position = pos
	n.setup(str(roundi(amount)), Color8(255, 120, 100) if taken_by_party else Color8(255, 248, 230))
	layer.add_child(n)


## Micro-pause : le monde se fige une fraction de seconde pour donner du poids au coup.
func hit_stop(duration: float) -> void:
	if not GameSettings.hit_stop:
		return
	_stop_token += 1
	var token := _stop_token
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	if token == _stop_token:
		Engine.time_scale = 1.0


func shake(amount: float) -> void:
	if camera and GameSettings.screen_shake:
		camera.shake(amount)


func _spawn(texture_path: String, frames: int, fps: float, pos: Vector2) -> Sprite2D:
	if layer == null:
		return null
	var fx := ONE_SHOT.new()
	fx.setup(load(texture_path), frames, fps)
	fx.position = pos
	layer.add_child(fx)
	return fx
