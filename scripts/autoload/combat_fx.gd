extends Node
## Retours du combat, appelables de partout : arcs de coup, étincelles, poussière, chiffres de dégâts,
## micro-pause d'impact, secousse de caméra, rayons et éclat des moments forts. Réglages dans GameSettings.

const ONE_SHOT := preload("res://scenes/fx/one_shot_fx.gd")
const DAMAGE_NUMBER := preload("res://scenes/fx/damage_number.gd")
const RING := preload("res://scenes/fx/ring_fx.gd")
## Chargées à la demande : un autoload est compilé avant l'import des images sur un clone neuf.
const SLASH := "res://assets/art/fx/slash.png"
const SPARK := "res://assets/art/fx/spark.png"
const PUFF := "res://assets/art/fx/puff.png"
const POOF := "res://assets/art/fx/poof.png"
const RAYS := "res://assets/art/fx/rays.png"
## Teinte de l'arc de coup du héros (accent or de la direction artistique).
const HERO_TINT := Color8(255, 210, 110)

## Couche d'effets du monde (au-dessus des personnages) et caméra, fournies par la scène principale.
var layer: Node2D
var camera: GameCamera

var _stop_token := 0


## Arc du geste, orienté selon l'une des 8 directions (une rotation libre abîmerait le pixel art).
func slash(pos: Vector2, dir: Vector2, tint := Color.WHITE) -> void:
	var fx := _spawn(SLASH, 3, 20.0, pos)
	if fx:
		fx.rotation = snappedf(dir.angle(), PI / 4.0)
		fx.modulate = tint


func impact(pos: Vector2, by_hero: bool, kill: bool) -> void:
	_spawn(SPARK, 4, 28.0, pos)
	if kill:
		hit_stop(0.07)
		shake(2.0)
	elif by_hero:
		hit_stop(0.035)


## Coup reçu par le groupe : plus marqué quand c'est le héros.
func party_hit(pos: Vector2, is_hero: bool) -> void:
	_spawn(SPARK, 4, 28.0, pos)
	if is_hero:
		hit_stop(0.05)
		shake(3.0)
	else:
		shake(1.0)


## Nuage de mort d'un ennemi.
func poof(pos: Vector2) -> void:
	_spawn(POOF, 5, 14.0, pos)


## Rayons de lumière qui s'ouvrent, tournent un peu et s'effacent (moments forts, moins d'une seconde).
func rays(pos: Vector2, size := 1.0) -> void:
	if layer == null:
		return
	var fx := Sprite2D.new()
	fx.texture = load(RAYS)
	fx.position = pos
	fx.z_index = 4
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = mat
	fx.scale = Vector2.ONE * size * 0.5
	layer.add_child(fx)
	var tween := fx.create_tween().set_parallel()
	tween.tween_property(fx, "scale", Vector2.ONE * size, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(fx, "rotation", 0.5, 0.9)
	tween.tween_property(fx, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tween.chain().tween_callback(fx.queue_free)


## Bref éclat lumineux de tout l'écran (changement de stade du camp).
func flash_screen(strength := 0.22) -> void:
	if not GameSettings.screen_shake:
		return
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	var rect := ColorRect.new()
	rect.color = Color(1.0, 0.95, 0.8, strength)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	add_child(canvas)
	var tween := rect.create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.45)
	tween.tween_callback(canvas.queue_free)


func puff(pos: Vector2) -> void:
	_spawn(PUFF, 3, 14.0, pos)


## Petite étincelle colorée (achat d'amélioration).
func sparkle(pos: Vector2, color: Color) -> void:
	var fx := _spawn(SPARK, 3, 12.0, pos)
	if fx:
		fx.modulate = color


## Gerbe d'étincelles et poussière (apparition d'une recrue).
func burst(pos: Vector2, color: Color) -> void:
	puff(pos + Vector2(0, 8))
	for i in 5:
		sparkle(pos + Vector2.from_angle(TAU * i / 5.0) * 10.0, color)


func ring(pos: Vector2, radius: float, color: Color) -> void:
	if layer == null:
		return
	var fx := RING.new()
	fx.position = pos
	fx.radius = radius
	fx.color = color
	layer.add_child(fx)


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
