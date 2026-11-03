class_name Hero
extends Combatant
## Héros jouable. Le joueur dirige ses déplacements ; le héros frappe seul l'ennemi le plus proche
## à portée de massue. Les futures compétences actives seront des composants voisins de AutoAttack.

## Accélération et freinage élevés : contrôle précis, sans glissade.
@export var acceleration := 1500.0
@export var deceleration := 2200.0

## Apparence à l'essai : héros PixelLab (planche de tools/pack_pixellab.gd), à sa taille réelle
## (46 à 50 px). Seul l'affichage change : collisions, vitesse, portée, combat et sauvegarde restent
## ceux du héros. Choisie par « -- --hero-skin=pixellab » ou basculée par F3 ; jamais enregistrée.
const PIXELLAB_SKIN := {
	"texture": preload("res://assets/art/hero_pixellab.png"), "hframes": 9, "vframes": 3,
	# Pieds à la rangée 56 d'une case de 68 : 34 - 56.
	"offset": Vector2(0, -22),
	"idle_frames": [0], "walk_frames": [1, 2, 3, 4, 5, 6, 7, 8], "idle_fps": 1.0, "walk_fps": 16.0,
	"bar_height": 54.0, "hit_y": -22.0, "ring": Vector2i(14, 5), "pip_y": -59, "shadow_scale": 1.6,
}

var attack := AutoAttack.new()

## Direction voulue par le déplacement à la souris (ClickMover), zéro sinon ; le clavier reste prioritaire.
var steer := Vector2.ZERO
var pixellab_skin := false

var _move := Vector2.ZERO
var _marker := HeroMarker.new()
## Apparence d'origine (relevée au lancement), pour revenir en arrière.
var _base_skin := {}
## Hauteur des étincelles quand le héros est touché (poitrine).
var _hit_y := -10.0


func _ready() -> void:
	super()
	attack.unit = self
	add_child(attack)
	# Marqueur au sol, dessiné sous le personnage (avant le sprite).
	_marker.position = Vector2(0, -1)
	add_child(_marker)
	move_child(_marker, sprite.get_index())
	var anim := _anim()
	_base_skin = {
		"texture": sprite.texture, "hframes": sprite.hframes, "vframes": sprite.vframes, "offset": sprite.offset,
		"idle_frames": anim.idle_frames.duplicate(), "walk_frames": anim.walk_frames.duplicate(), "idle_fps": anim.idle_fps, "walk_fps": anim.walk_fps,
		"bar_height": bar_height, "hit_y": -10.0, "ring": Vector2i(_marker.rx, _marker.ry), "pip_y": _marker.pip_y,
		"shadow_scale": 1.0,
	}
	if "--hero-skin=pixellab" in OS.get_cmdline_user_args():
		set_pixellab_skin(true)


## Bascule entre le sprite d'origine et le héros PixelLab.
func set_pixellab_skin(on: bool) -> void:
	pixellab_skin = on
	var skin: Dictionary = PIXELLAB_SKIN if on else _base_skin
	var anim := _anim()
	var facing := anim.facing
	sprite.frame = 0
	sprite.texture = skin["texture"]
	sprite.hframes = skin["hframes"]
	sprite.vframes = skin["vframes"]
	sprite.offset = skin["offset"]
	anim.idle_frames.assign(skin["idle_frames"])
	anim.walk_frames.assign(skin["walk_frames"])
	anim.idle_fps = skin["idle_fps"]
	anim.walk_fps = skin["walk_fps"]
	anim.facing = facing
	set_bar_height(skin["bar_height"])
	var ring: Vector2i = skin["ring"]
	_marker.resize(ring.x, ring.y, skin["pip_y"])
	get_node("Shadow").scale = Vector2.ONE * skin["shadow_scale"]
	_hit_y = skin["hit_y"]


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down") if is_alive() else Vector2.ZERO
	if input == Vector2.ZERO and is_alive():
		input = steer
	if input != Vector2.ZERO:
		# Virage franc : on ne conserve que la composante de vitesse dans la nouvelle direction.
		if _move.dot(input) < 0.0:
			_move = _move.project(input.orthogonal())
		_move = _move.move_toward(input * stats.move_speed, acceleration * delta)
		_anim().face(input)
	else:
		_move = _move.move_toward(Vector2.ZERO, deceleration * delta)
	velocity = _move + consume_knockback(delta)
	move_and_slide()
	if is_alive():
		var foe := Targeting.nearest(self, &"enemies", stats.attack_range)
		attack.try_attack(foe)
		# Immobile, le héros se tourne vers ce qu'il frappe.
		if foe and input == Vector2.ZERO and attack.is_swinging():
			_anim().face(foe.global_position - global_position)


func _animate(delta: float) -> void:
	_anim().animate(_move, stats.move_speed, delta)


func _on_hit(from: Vector2) -> void:
	CombatFx.party_hit(global_position + Vector2(0, _hit_y), true)


func _on_died() -> void:
	remove_from_group(&"party_members")
	_move = Vector2.ZERO
	steer = Vector2.ZERO
	sprite.rotation_degrees = 90.0
	sprite.modulate = Color(0.75, 0.7, 0.7)
	super()


## Relève au campement, pleine santé.
func revive_at(pos: Vector2) -> void:
	global_position = pos
	health.restore(1.0)
	sprite.rotation_degrees = 0.0
	sprite.modulate = Color.WHITE
	add_to_group(&"party_members")
	reset_physics_interpolation()


func _anim() -> CharacterSprite:
	return sprite as CharacterSprite
