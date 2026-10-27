class_name SlingStone
extends Node2D
## Pierre lancée à la fronde : vole vers sa cible (qu'elle suit si celle-ci bouge), en légère cloche
## au-dessus de son ombre. Elle s'arrête sur tout obstacle du monde (bâtiment, falaise, arbre, eau,
## comme les vues directes du combat) sans infliger de dégâts. Les dégâts ne tombent qu'une fois, à
## l'arrivée sur une cible encore debout ; une cible tombée ou disparue en vol ne cause aucune erreur :
## la pierre finit sa course et disparaît. Durée de vie bornée.

const SPEED := 240.0
const MAX_LIFE := 1.0
## Distance de contact, au-delà du rayon du corps de la cible.
const HIT_RADIUS := 4.0
## Hauteur de vol au départ et à l'arrivée (main, poitrine), et hauteur supplémentaire de la cloche.
const HEIGHT := 10.0
const ARC := 7.0
const WORLD_MASK := 1
const STONE := [Color8(42, 32, 28), Color8(139, 130, 124), Color8(207, 196, 178)]
const SHADOW := Color(26 / 255.0, 26 / 255.0, 46 / 255.0, 0.35)

## Bilan de l'outil de test : pierres arrivées et pierres arrêtées par un obstacle.
static var landed := 0
static var blocked := 0
## Dégâts de la dernière pierre arrivée (améliorations comprises), pour l'outil de test.
static var last_damage := 0.0

var _target: Combatant
var _attack: AutoAttack
var _damage := 0.0
var _knockback := 0.0
var _from := Vector2.ZERO
var _aim := Vector2.ZERO
var _total := 1.0
var _life := 0.0


static func launch(shooter: Combatant, target: Combatant, damage: float, attack: AutoAttack) -> void:
	var stone := SlingStone.new()
	stone._target = target
	stone._attack = attack
	stone._damage = damage
	stone._knockback = shooter.stats.knockback
	stone._from = shooter.global_position
	stone._aim = target.global_position
	stone._total = maxf(shooter.global_position.distance_to(target.global_position), 1.0)
	stone.position = shooter.global_position
	# Couche des effets du monde (au-dessus des personnages), à défaut le parent du tireur.
	var layer: Node = CombatFx.layer if is_instance_valid(CombatFx.layer) else shooter.get_parent()
	layer.add_child(stone)


func _physics_process(delta: float) -> void:
	_life += delta
	if _life > MAX_LIFE:
		queue_free()
		return
	var alive := is_instance_valid(_target) and _target.is_alive()
	if alive:
		_aim = _target.global_position
	var next := position + (_aim - position).limit_length(SPEED * delta)
	var query := PhysicsRayQueryParameters2D.create(position + Vector2(0, -3), next + Vector2(0, -3), WORLD_MASK)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		blocked += 1
		CombatFx.sparkle(hit["position"] + Vector2(0, -HEIGHT + 3.0), STONE[1])
		queue_free()
		return
	position = next
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


func _draw() -> void:
	var t := clampf(_from.distance_to(position) / _total, 0.0, 1.0)
	var lift := HEIGHT + sin(PI * t) * ARC
	draw_rect(Rect2(-1, -1, 3, 2), SHADOW)
	var top := Vector2(-1, -lift - 1)
	draw_rect(Rect2(top - Vector2(1, 1), Vector2(5, 5)), STONE[0])
	draw_rect(Rect2(top, Vector2(3, 3)), STONE[1])
	draw_rect(Rect2(top, Vector2(1, 1)), STONE[2])
