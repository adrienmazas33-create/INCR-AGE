class_name Upgrades
## Catalogue des améliorations achetées au feu de camp : coûts progressifs et effets.
## Les niveaux sont stockés dans GameState.upgrades (repris tel quel par la future sauvegarde).

const ORDER := ["recruit", "damage", "magnet", "vigor"]
## name : texte affiché (police pixel, majuscules sans accent) ; icon : image dans upgrade_icons.png ;
## cost : ressource -> [base, croissance] ; knowledge_from : niveau à partir duquel du savoir est exigé.
const DEFS := {
	"recruit": {"name": "RECRUE", "icon": 0, "max": 5,
		"cost": {"food": [5.0, 1.35], "materials": [1.0, 1.5]}, "knowledge_from": 99},
	"damage": {"name": "FORCE", "icon": 1, "max": 5,
		"cost": {"food": [2.0, 1.4], "materials": [3.0, 1.45]}, "knowledge_from": 2},
	"magnet": {"name": "AIMANT", "icon": 2, "max": 4,
		"cost": {"food": [2.0, 1.3], "materials": [2.0, 1.5]}, "knowledge_from": 99},
	"vigor": {"name": "VIGUEUR", "icon": 3, "max": 4,
		"cost": {"food": [4.0, 1.4], "materials": [2.0, 1.45]}, "knowledge_from": 2},
}

## Prospérité requise pour chaque stade du campement, et noms affichés.
const CAMP_THRESHOLDS := [0, 3, 8]
const CAMP_NAMES := ["CAMPEMENT", "TRIBU", "VILLAGE"]

const BASE_COMPANIONS := 3
const BASE_MAGNET := 96.0
const MAGNET_PER_LEVEL := 24.0
const DAMAGE_PER_LEVEL := 0.15
const HEALTH_PER_LEVEL := 0.15


static func level(id: String) -> int:
	return GameState.upgrades.get(id, 0)


static func is_maxed(id: String) -> bool:
	return level(id) >= DEFS[id]["max"]


## Coût du prochain niveau : ressource -> quantité.
static func cost(id: String) -> Dictionary:
	var def: Dictionary = DEFS[id]
	var n := level(id)
	var out := {}
	for kind in def["cost"]:
		var curve: Array = def["cost"][kind]
		out[kind] = ceili(curve[0] * pow(curve[1], n) - 0.001)
	if n >= def["knowledge_from"]:
		out["knowledge"] = 1 if id == "vigor" else n - 1
	return out


static func can_buy(id: String) -> bool:
	return not is_maxed(id) and GameState.can_afford(cost(id))


## Achète le niveau suivant si possible ; renvoie vrai en cas de succès.
static func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	GameState.spend(cost(id))
	GameState.set_upgrade(id, level(id) + 1)
	return true


static func any_affordable() -> bool:
	for id in ORDER:
		if can_buy(id):
			return true
	return false


## Prospérité : nombre total de niveaux achetés. Le campement évolue avec elle (lot 3B).
static func prosperity() -> int:
	var total := 0
	for id in ORDER:
		total += level(id)
	return total


## Stade du campement : 1 campement, 2 tribu, 3 village.
static func camp_stage() -> int:
	var stage := 1
	for i in CAMP_THRESHOLDS.size():
		if prosperity() >= CAMP_THRESHOLDS[i]:
			stage = i + 1
	return stage


## Progression (0 à 1) vers le stade suivant ; 1 au dernier stade.
static func camp_progress() -> float:
	var stage := camp_stage()
	if stage >= CAMP_THRESHOLDS.size():
		return 1.0
	var lo: int = CAMP_THRESHOLDS[stage - 1]
	var hi: int = CAMP_THRESHOLDS[stage]
	return float(prosperity() - lo) / (hi - lo)


static func companion_count() -> int:
	return BASE_COMPANIONS + level("recruit")


static func damage_multiplier() -> float:
	return 1.0 + DAMAGE_PER_LEVEL * level("damage")


static func health_multiplier() -> float:
	return 1.0 + HEALTH_PER_LEVEL * level("vigor")


static func magnet_radius() -> float:
	return BASE_MAGNET + MAGNET_PER_LEVEL * level("magnet")
