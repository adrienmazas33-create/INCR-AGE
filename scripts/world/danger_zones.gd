class_name DangerZones
extends Node
## Difficulté géographique (lot G1) : trois cercles autour du feu de camp. Plus on s'éloigne, plus les
## ennemis sont solides et frappent fort, et plus leur butin est riche. Les terres proches ne changent
## pas (apprentissage). Un champion garde chacune des deux zones lointaines.
## Les ennemis reçoivent une copie renforcée de leurs caractéristiques à leur apparition
## (EnemySpawner) ; les fiches de data/units ne changent pas. Rien n'est enregistré.
## Un bandeau annonce le passage d'une zone à l'autre.

## Rayons des cercles, en cases depuis le feu : terres proches, sauvages, hostiles.
const RADII: Array[float] = [40.0, 50.0]
const NAMES := ["TERRES PROCHES", "TERRES SAUVAGES", "TERRES HOSTILES"]
## Multiplicateurs par zone : vie, dégâts, butin (vivres et matériaux), chance de savoir.
const HEALTH: Array[float] = [1.0, 1.6, 2.4]
const DAMAGE: Array[float] = [1.0, 1.3, 1.6]
const LOOT: Array[float] = [1.0, 1.5, 2.0]
const KNOWLEDGE: Array[float] = [1.0, 1.5, 2.0]
## Champion : en plus du renfort de sa zone ; savoir toujours lâché ; réapparition lente.
const CHAMPION_HEALTH := 1.8
const CHAMPION_DAMAGE := 1.0
const CHAMPION_LOOT := 2.0
const CHAMPION_RESPAWN := 180.0
## Marge (px) à franchir au-delà d'une limite avant d'annoncer le changement de zone.
const HYSTERESIS := 16.0

## Centre des cercles : le point d'apparition, au feu de camp (renseigné par la scène principale).
static var center := Vector2.ZERO

var _hero: Node2D
var _hud: Hud
var _zone := -1


static func zone_at(pos: Vector2) -> int:
	var d := pos.distance_to(center) / TileIds.SIZE
	var z := 0
	for r in RADII:
		if d >= r:
			z += 1
	return z


## Copie renforcée des caractéristiques d'un ennemi selon sa zone (et son rang de champion).
static func scaled(base: UnitStats, zone: int, champion := false) -> UnitStats:
	var s := base.duplicate() as UnitStats
	var loot := LOOT[zone] * (CHAMPION_LOOT if champion else 1.0)
	s.max_health = base.max_health * HEALTH[zone] * (CHAMPION_HEALTH if champion else 1.0)
	s.damage = base.damage * DAMAGE[zone] * (CHAMPION_DAMAGE if champion else 1.0)
	var drops := {}
	for kind in base.drops:
		var span: Array = base.drops[kind]
		drops[kind] = [roundi(span[0] * loot), ceili(span[1] * loot)]
	s.drops = drops
	s.knowledge_chance = 1.0 if champion else minf(base.knowledge_chance * KNOWLEDGE[zone], 1.0)
	return s


func setup(hero: Node2D, hud: Hud) -> void:
	_hero = hero
	_hud = hud
	_zone = zone_at(hero.global_position)


func _process(_delta: float) -> void:
	var d := _hero.global_position.distance_to(center) / TileIds.SIZE
	var z := zone_at(_hero.global_position)
	if z == _zone:
		return
	# On ne change de zone qu'une fois la limite franchie d'un demi-pas : pas d'annonces en rafale.
	var limit: float = RADII[mini(z, _zone)]
	if absf(d - limit) * TileIds.SIZE < HYSTERESIS:
		return
	_zone = z
	_hud.announce(NAMES[z])
