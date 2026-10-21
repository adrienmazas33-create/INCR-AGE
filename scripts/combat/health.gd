class_name Health
extends Node
## Points de vie d'une unité, avec régénération après quelques secondes sans être touché.

signal changed
signal died

const REGEN_DELAY := 4.0

var max_health := 40.0
var current := 40.0
var regen_per_second := 0.0
var _since_damage := 999.0


func setup(maximum: float, regen: float) -> void:
	max_health = maximum
	current = maximum
	regen_per_second = regen


## Change la vie maximale en gardant la proportion actuelle (ou en remettant au maximum).
func set_maximum(maximum: float, fill := false) -> void:
	var r := ratio()
	max_health = maximum
	if not is_dead():
		current = maximum if fill else maximum * r
	changed.emit()


func is_dead() -> bool:
	return current <= 0.0


## Secondes écoulées depuis le dernier coup reçu.
func since_damage() -> float:
	return _since_damage


func ratio() -> float:
	return current / max_health


func take_damage(amount: float) -> void:
	if is_dead():
		return
	current = maxf(current - amount, 0.0)
	_since_damage = 0.0
	changed.emit()
	if is_dead():
		died.emit()


## Remet la vie à une fraction du maximum (relève après K.O. ou retour au camp).
func restore(fraction := 1.0) -> void:
	current = max_health * fraction
	_since_damage = 999.0
	changed.emit()


func heal(amount: float) -> void:
	if is_dead() or current >= max_health:
		return
	current = minf(current + amount, max_health)
	changed.emit()


func _process(delta: float) -> void:
	_since_damage += delta
	if regen_per_second > 0.0 and _since_damage > REGEN_DELAY:
		heal(regen_per_second * delta)
