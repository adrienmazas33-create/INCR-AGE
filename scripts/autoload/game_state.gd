extends Node
## État de la partie : ressources abstraites de la bible (vivres, matériaux, savoir) et niveaux
## d'amélioration. Point d'appui de la future sauvegarde (rien n'est encore enregistré sur disque).

signal resource_changed(kind: String, total: int)
signal upgrade_bought(id: String, level: int)

const KINDS := ["food", "materials", "knowledge"]

var resources := {"food": 0, "materials": 0, "knowledge": 0}
## Amélioration -> niveau acheté (voir Upgrades).
var upgrades := {}


func add(kind: String, amount := 1) -> void:
	resources[kind] = resources.get(kind, 0) + amount
	resource_changed.emit(kind, resources[kind])


func can_afford(cost: Dictionary) -> bool:
	for kind in cost:
		if resources.get(kind, 0) < cost[kind]:
			return false
	return true


func spend(cost: Dictionary) -> void:
	for kind in cost:
		add(kind, -cost[kind])


func set_upgrade(id: String, new_level: int) -> void:
	upgrades[id] = new_level
	upgrade_bought.emit(id, new_level)


func summary() -> String:
	return "vivres %d, matériaux %d, savoir %d ; améliorations %s" % [resources["food"], resources["materials"],
		resources["knowledge"], upgrades]
