class_name Upgrades
## Catalogue des améliorations achetées au feu de camp : coûts progressifs et effets.
## Les niveaux sont stockés dans GameState.upgrades (enregistrés par SaveGame).
## Lot G4 : chaque stade du campement débloque une ligne (TRIBU : FRAPPE, VILLAGE : RECOLTE), le
## VILLAGE fixe le grand objectif de l'âge (AGE DES METAUX, en plusieurs étapes), et la courbe est
## allongée (FORCE et VIGUEUR montent plus haut).

## Lignes d'amélioration, dans l'ordre du panneau (touches 1 à 6) ; toutes comptent dans la prospérité.
const ORDER := ["recruit", "damage", "magnet", "vigor", "skill", "harvest"]
## Grand objectif de l'âge : dernière ligne du panneau (touche 7), hors prospérité.
const AGE := "age"
## name : texte affiché (police pixel, majuscules sans accent) ; icon : image dans upgrade_icons.png
## (0 à 3) ou motif dessiné par CampPanelRow (texte) ; stage : stade du campement qui débloque la ligne ;
## cost : ressource -> [base, croissance] ; knowledge : [niveau à partir duquel du savoir est exigé,
## quantité à ce niveau, hausse par niveau suivant].
const DEFS := {
	"recruit": {"name": "RECRUE", "icon": 0, "max": 5, "stage": 1,
		"cost": {"food": [5.0, 1.35], "materials": [1.0, 1.5]}},
	"damage": {"name": "FORCE", "icon": 1, "max": 8, "stage": 1,
		"cost": {"food": [2.0, 1.4], "materials": [3.0, 1.45]}, "knowledge": [2, 1, 1]},
	"magnet": {"name": "AIMANT", "icon": 2, "max": 4, "stage": 1,
		"cost": {"food": [2.0, 1.3], "materials": [2.0, 1.5]}},
	"vigor": {"name": "VIGUEUR", "icon": 3, "max": 6, "stage": 1,
		"cost": {"food": [4.0, 1.4], "materials": [2.0, 1.45]}, "knowledge": [2, 1, 0]},
	"skill": {"name": "FRAPPE", "icon": "skill", "max": 4, "stage": 2,
		"cost": {"food": [6.0, 1.5], "materials": [6.0, 1.5]}, "knowledge": [0, 1, 1]},
	"harvest": {"name": "RECOLTE", "icon": "harvest", "max": 3, "stage": 3,
		"cost": {"food": [8.0, 1.6], "materials": [8.0, 1.6]}, "knowledge": [0, 2, 1]},
	"age": {"name": "AGE DES METAUX", "icon": "age", "max": 3, "stage": 3,
		"cost": {"food": [60.0, 1.5], "materials": [60.0, 1.5]}, "knowledge": [0, 6, 4]},
}

## Prospérité requise pour chaque stade du campement, et noms affichés.
const CAMP_THRESHOLDS := [0, 3, 8]
const CAMP_NAMES := ["CAMPEMENT", "TRIBU", "VILLAGE"]

const BASE_COMPANIONS := 3
const BASE_MAGNET := 96.0
const MAGNET_PER_LEVEL := 24.0
const DAMAGE_PER_LEVEL := 0.15
const HEALTH_PER_LEVEL := 0.15
## FRAPPE : recharge de la compétence du héros, réduite à chaque niveau (6 s, puis 3 s au maximum).
const SKILL_COOLDOWN := 6.0
const SKILL_COOLDOWN_PER_LEVEL := 0.75
## RECOLTE : ressources en plus par cueillette, et repousse raccourcie, par niveau.
const HARVEST_BONUS_PER_LEVEL := 1
const HARVEST_REGROW_PER_LEVEL := 0.2


static func level(id: String) -> int:
	return GameState.upgrades.get(id, 0)


static func is_maxed(id: String) -> bool:
	return level(id) >= DEFS[id]["max"]


## Vrai si le stade actuel du campement a débloqué la ligne.
static func is_unlocked(id: String) -> bool:
	return camp_stage() >= DEFS[id]["stage"]


## Coût du prochain niveau : ressource -> quantité.
static func cost(id: String) -> Dictionary:
	var def: Dictionary = DEFS[id]
	var n := level(id)
	var out := {}
	for kind in def["cost"]:
		var curve: Array = def["cost"][kind]
		out[kind] = ceili(curve[0] * pow(curve[1], n) - 0.001)
	if def.has("knowledge") and n >= def["knowledge"][0]:
		out["knowledge"] = def["knowledge"][1] + def["knowledge"][2] * (n - def["knowledge"][0])
	return out


static func can_buy(id: String) -> bool:
	return is_unlocked(id) and not is_maxed(id) and GameState.can_afford(cost(id))


## Achète le niveau suivant si possible ; renvoie vrai en cas de succès.
static func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	GameState.spend(cost(id))
	GameState.set_upgrade(id, level(id) + 1)
	return true


static func any_affordable() -> bool:
	for id in ORDER + [AGE]:
		if can_buy(id):
			return true
	return false


## Prospérité : nombre total de niveaux achetés (hors objectif de l'âge). Le campement évolue avec elle.
static func prosperity() -> int:
	var total := 0
	for id in ORDER:
		total += level(id)
	return total


## Vrai quand toutes les étapes de l'objectif de l'âge sont faites : la tribu est prête pour l'âge suivant.
static func age_ready() -> bool:
	return is_maxed(AGE)

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


static func skill_cooldown() -> float:
	return SKILL_COOLDOWN - SKILL_COOLDOWN_PER_LEVEL * level("skill")


static func harvest_bonus() -> int:
	return HARVEST_BONUS_PER_LEVEL * level("harvest")


## Facteur appliqué au temps de repousse des baies et du silex.
static func harvest_regrow_factor() -> float:
	return 1.0 - HARVEST_REGROW_PER_LEVEL * level("harvest")
