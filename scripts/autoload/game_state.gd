extends Node
## État de la partie : ressources abstraites de la bible (vivres, matériaux, savoir) et niveaux
## d'amélioration. Point d'appui de la future sauvegarde (rien n'est encore enregistré sur disque).

signal resource_changed(kind: String, total: int)
signal upgrade_bought(id: String, level: int)
## Rôle d'un compagnon changé au camp, ou rôle de la prochaine recrue choisi.
signal roles_changed

const KINDS := ["food", "materials", "knowledge"]
## Rôles des compagnons : combattant à la lance (rôle historique) ou frondeur.
const ROLES := ["spear", "sling"]
const DEFAULT_ROLE := "spear"

var resources := {"food": 0, "materials": 0, "knowledge": 0}
## Amélioration -> niveau acheté (voir Upgrades).
var upgrades := {}
## Rôle de chaque compagnon, dans l'ordre du groupe (même nombre que de compagnons).
var roles: Array[String] = []
## Rôle donné à la prochaine recrue.
var next_recruit_role := DEFAULT_ROLE


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
	return "vivres %d, matériaux %d, savoir %d ; améliorations %s ; rôles %s" % [resources["food"], resources["materials"],
		resources["knowledge"], upgrades, roles]


func set_role(index: int, role: String) -> void:
	if index >= 0 and index < roles.size() and role in ROLES:
		roles[index] = role
		roles_changed.emit()


func set_next_recruit_role(role: String) -> void:
	if role in ROLES:
		next_recruit_role = role
		roles_changed.emit()


## Rôles alignés sur le nombre de compagnons : complétés par le rôle par défaut, ou raccourcis.
func fit_roles(count: int) -> void:
	while roles.size() < count:
		roles.append(DEFAULT_ROLE)
	roles.resize(count)
