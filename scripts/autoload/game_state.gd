extends Node
## État de la partie : ressources abstraites de la bible (vivres, matériaux, savoir).
## Point d'appui de la future sauvegarde (rien n'est encore enregistré sur disque).

signal resource_changed(kind: String, total: int)

const KINDS := ["food", "materials", "knowledge"]

var resources := {"food": 0, "materials": 0, "knowledge": 0}


func add(kind: String, amount := 1) -> void:
	resources[kind] = resources.get(kind, 0) + amount
	resource_changed.emit(kind, resources[kind])


func summary() -> String:
	return "vivres %d, matériaux %d, savoir %d" % [resources["food"], resources["materials"], resources["knowledge"]]
