class_name SlingStone
extends Node2D
## Pierre lancée, en légère cloche au-dessus de son ombre. Deux modes :
## - **suivie** (frondeur allié, `launch`) : elle suit sa cible ; les dégâts tombent une fois, à
##   l'arrivée sur la cible encore debout ; une cible tombée ou disparue en vol ne cause aucune erreur ;
## - **position figée** (lanceur ennemi, `launch_at`) : elle file vers l'endroit visé au moment du lancer,
##   sans suivre personne, plus lentement ; elle ne blesse que la première unité du groupe visé qu'elle
##   rencontre en vol (une seule fois), et retombe sans dégâts à l'arrivée : on peut l'esquiver.
## Dans les deux cas, elle s'arrête sur un décor solide (Targeting.shot_blocker : l'eau ne l'arrête pas)
## sans infliger de dégâts. Durée de vie bornée.

const SPEED := 240.0
const MAX_LIFE := 1.0
## Distance de contact, au-delà du rayon du corps de la cible.
const HIT_RADIUS := 4.0
## Hauteur de vol au départ et à l'arrivée (main, poitrine), et hauteur supplémentaire de la cloche.
const HEIGHT := 10.0
const ARC := 7.0
const STONE := [Color8(42, 32, 28), Color8(139, 130, 124), Color8(207, 196, 178)]
const SHADOW := Color(26 / 255.0, 26 / 255.0, 46 / 255.0, 0.35)
## Repère de l'endroit visé par une pierre ennemie (le rouge est réservé au danger).
const DANGER := Color8(226, 64, 52)

## Bilan de l'outil de test : pierres alliées arrivées, pierres arrêtées par un obstacle, dégâts du
## dernier tir allié ; pierres ennemies lancées, ayant touché, retombées sans toucher.
static var landed := 0
static var blocked := 0
static var last_damage := 0.0
static var enemy_thrown := 0
static var enemy_hits := 0
static var enemy_missed := 0

var _target: Combatant
var _attack: AutoAttack
var _hit_group := &""
var _speed := SPEED
var _max_life := MAX_LIFE
var _damage := 0.0
var _knockback := 0.0
var _from := Vector2.ZERO
var _aim := Vector2.ZERO
var _total := 1.0
var _life := 0.0


## Pierre suivie (frondeur allié).
static func launch(shooter: Combatant, target: Combatant, damage: float, attack: AutoAttack) -> void:
	var stone := _create(shooter, target.global_position, damage)
	stone._target = target
	stone._attack = attack
	_add(stone, shooter)


## Pierre vers une position figée, qui ne blesse que les membres de `group` rencontrés en vol.
static func launch_at(shooter: Combatant, aim: Vector2, damage: float, group: StringName, speed: float) -> void:
	var stone := _create(shooter, aim, damage)
	stone._hit_group = group
	stone._speed = speed
	stone._max_life = stone._total / speed + 0.3
	enemy_thrown += 1
	_add(stone, shooter)
	CombatFx.ring(aim + Vector2(0, -2), 6.0, DANGER)


static func _create(shooter: Combatant, aim: Vector2, damage: float) -> SlingStone:
	var stone := SlingStone.new()
	stone._damage = damage
	stone._knockback = shooter.stats.knockback
	stone._from = shooter.global_position
	stone._aim = aim
	stone._total = maxf(shooter.global_position.distance_to(aim), 1.0)
	stone.position = shooter.global_position
	return stone


## Couche des effets du monde (au-dessus des personnages), à défaut le parent du tireur.
static func _add(stone: SlingStone, shooter: Combatant) -> void:
	var layer: Node = CombatFx.layer if is_instance_valid(CombatFx.layer) else shooter.get_parent()
	layer.add_child(stone)


func _physics_process(delta: float) -> void:
	_life += delta
	if _life > _max_life:
		queue_free()
		return
	var alive := _hit_group == &"" and is_instance_valid(_target) and _target.is_alive()
	if alive:
		_aim = _target.global_position
	var next := position + (_aim - position).limit_length(_speed * delta)
	var stop: Variant = Targeting.shot_blocker(self, position, next)
	if stop != null:
		blocked += 1
		CombatFx.sparkle(stop + Vector2(0, -HEIGHT + 3.0), STONE[1])
		queue_free()
		return
	position = next
	if _hit_group != &"":
		_fly_at_position()
		return
	if alive and position.distance_to(_target.global_position) <= HIT_RADIUS + _target.stats.body_radius:
		landed += 1
		last_damage = _damage
		_target.receive_hit(_damage, _from, _knockback)
		if is_instance_valid(_attack):
			_attack.hits += 1
		CombatFx.impact(_target.global_position + Vector2(0, -8), false, not _target.is_alive())
		queue_free()
		return
	if not alive and position.distance_to(_aim) < 1.0:
		queue_free()
		return
	queue_redraw()


## Pierre ennemie : touche la première unité visée rencontrée, sinon retombe à l'endroit visé.
func _fly_at_position() -> void:
	for node in get_tree().get_nodes_in_group(_hit_group):
		var unit := node as Combatant
		if unit and unit.is_alive() and position.distance_to(unit.global_position) <= HIT_RADIUS + unit.stats.body_radius:
			enemy_hits += 1
			unit.receive_hit(_damage, _from, _knockback)
			queue_free()
			return
	if position.distance_to(_aim) < 1.0:
		enemy_missed += 1
		CombatFx.puff(position)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_from.distance_to(position) / _total, 0.0, 1.0)
	var lift := HEIGHT * (1.0 - t * 0.7 if _hit_group != &"" else 1.0) + sin(PI * t) * ARC
	draw_rect(Rect2(-1, -1, 3, 2), SHADOW)
	var top := Vector2(-1, -lift - 1)
	draw_rect(Rect2(top - Vector2(1, 1), Vector2(5, 5)), STONE[0])
	draw_rect(Rect2(top, Vector2(3, 3)), STONE[1])
	draw_rect(Rect2(top, Vector2(1, 1)), STONE[2])
