class_name ActiveSkill
extends Node
## Compétence active du héros (lot G2) : déclenchée par le joueur, puis en recharge. Base commune des
## compétences : chacune décrit seulement son effet dans _activate. Voisine de AutoAttack sur le héros.

## Le joueur a déclenché la compétence ; elle est de nouveau prête.
signal used
signal became_ready

## Nom affiché et recharge en secondes.
@export var display_name := ""
@export var cooldown := 6.0

var unit: Combatant
## Temps de recharge restant (0 : prête).
var remaining := 0.0
## Utilisations (statistique de contrôle).
var uses := 0


func is_ready() -> bool:
	return remaining <= 0.0


## Part de la recharge déjà écoulée (1 : prête), pour l'indicateur.
func charge() -> float:
	return 1.0 - clampf(remaining / cooldown, 0.0, 1.0)


## Déclenche la compétence si elle est prête et l'unité debout ; renvoie vrai en cas de succès.
func try_use() -> bool:
	if not is_ready() or unit == null or not unit.is_alive():
		return false
	remaining = cooldown
	uses += 1
	_activate()
	used.emit()
	return true


func _process(delta: float) -> void:
	if remaining <= 0.0:
		return
	remaining -= delta
	if remaining <= 0.0:
		remaining = 0.0
		became_ready.emit()


## Effet de la compétence (à définir par chaque compétence).
func _activate() -> void:
	pass
