class_name RangedAttack
extends AutoAttack
## Tir à la fronde : même interface que l'attaque de mêlée (le groupe et l'unité n'y voient pas de
## différence). Pas de tir sans vue directe sur la cible. Le geste d'élan précède le départ d'une pierre
## visible (SlingStone) ; les dégâts tombent à son arrivée, une seule fois, avec l'amélioration FORCE.


func try_attack(target: Combatant) -> void:
	if target == null or _cooldown > 0.0 or _windup >= 0.0 or not in_range(target):
		return
	if not Targeting.has_sight(unit, unit.global_position, target.global_position):
		return
	_target = target
	_windup = unit.stats.attack_windup
	unit.lunge((target.global_position - unit.global_position).normalized())


func _impact() -> void:
	_cooldown = unit.stats.attack_cooldown
	if not unit.is_alive() or not is_instance_valid(_target) or not _target.is_alive():
		return
	SlingStone.launch(unit, _target, unit.stats.damage * Upgrades.damage_multiplier(), self)
