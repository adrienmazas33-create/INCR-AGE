class_name AutoAttack
extends Node
## Attaque de mêlée automatique. L'unité lui propose une cible à chaque tour ; si la cible est
## à portée et l'arme prête, le geste démarre (arc visible), puis l'impact tombe après un court délai.
## Une cible sortie de portée entre-temps esquive le coup : le placement compte.
## Les compétences actives du héros (plus tard) seront des composants voisins de celui-ci.

## Tolérance de portée à l'impact, pour ne pas rater une cible qui recule d'un pixel.
const IMPACT_TOLERANCE := 8.0

var unit: Combatant
## Coups portés (statistique de contrôle).
var hits := 0

var _cooldown := 0.0
var _windup := -1.0
var _target: Combatant


func is_swinging() -> bool:
	return _windup >= 0.0


func in_range(target: Combatant) -> bool:
	return unit.edge_distance(target) <= unit.stats.attack_range


func try_attack(target: Combatant) -> void:
	if target == null or _cooldown > 0.0 or _windup >= 0.0 or not in_range(target):
		return
	_target = target
	_windup = unit.stats.attack_windup
	var dir := (target.global_position - unit.global_position).normalized()
	unit.lunge(dir)
	CombatFx.slash(unit.global_position + Vector2(0, -10) + dir * 8.0, dir)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _windup < 0.0:
		return
	_windup -= delta
	if _windup < 0.0:
		_impact()


func _impact() -> void:
	_cooldown = unit.stats.attack_cooldown
	if not unit.is_alive() or not is_instance_valid(_target) or not _target.is_alive():
		return
	if unit.edge_distance(_target) > unit.stats.attack_range + IMPACT_TOLERANCE:
		return
	_target.receive_hit(unit.stats.damage, unit.global_position, unit.stats.knockback)
	hits += 1
	CombatFx.impact(_target.global_position + Vector2(0, -8), unit.is_in_group("hero"), not _target.is_alive())
