class_name CampVillage
extends Node
## Évolution automatique du campement (lot 3B). Le joueur ne place rien : le camp grandit en trois
## stades selon la prospérité (niveaux d'amélioration achetés, voir Upgrades.camp_stage()).
## Chaque stade ajoute les éléments décrits ci-dessous, tous hors des chemins.

const VILLAGER := preload("res://scenes/characters/villager.gd")
const VILLAGER_SKINS: Array[Texture2D] = [
	preload("res://assets/art/villager_0.png"),
	preload("res://assets/art/villager_1.png"),
]
## Décors ajoutés par stade : [clé de PropSpawner.PROPS, cellule].
const STAGE_PROPS := {
	2: [["h", Vector2i(61, 50)], ["h", Vector2i(50, 57)], ["rack_meat", Vector2i(67, 61)], ["baskets", Vector2i(65, 61)]],
	3: [["longhouse", Vector2i(52, 50)], ["h", Vector2i(63, 61)], ["palisade", Vector2i(66, 58)], ["palisade", Vector2i(67, 58)],
		["palisade", Vector2i(68, 58)], ["palisade", Vector2i(69, 58)], ["torch", Vector2i(55, 50)], ["torch", Vector2i(59, 50)],
		["banner", Vector2i(66, 52)], ["baskets", Vector2i(60, 61)]],
}
## Villageois ajoutés par stade : boucle de points de passage (en tuiles, fractions permises).
const STAGE_VILLAGERS := {
	2: [[Vector2(56.5, 56.6), Vector2(60.0, 57.2), Vector2(66.0, 62.2)],
		[Vector2(50.5, 58.3), Vector2(51.5, 55.9), Vector2(55.4, 55.8)]],
	3: [[Vector2(52.5, 51.4), Vector2(55.5, 53.6), Vector2(57.6, 52.4)],
		[Vector2(63.5, 62.4), Vector2(64.6, 59.7), Vector2(60.6, 58.9)]],
}
const ANNOUNCES := {2: "LA TRIBU GRANDIT", 3: "LE VILLAGE PROSPERE"}
## Les nouveaux villageois arrivent par le chemin du sud.
const ARRIVAL := Vector2(57.5, 62.0)
const STEP_DELAY := 0.28
const GOLD := Color8(255, 214, 90)

var stage := 1

var _world: World
var _hud: Hud
var _props: PropSpawner
var _fire: Node2D
var _villager_count := 0


func setup(world: World, hud: Hud) -> void:
	_world = world
	_hud = hud
	_props = PropSpawner.new(world.map)
	_fire = get_tree().get_first_node_in_group(&"campfire")
	# Au lancement, le camp est montré directement à son stade (sans animation).
	for s in range(2, Upgrades.camp_stage() + 1):
		_build(s, false)
	stage = Upgrades.camp_stage()
	GameState.upgrade_bought.connect(_on_upgrade_bought)


func _on_upgrade_bought(_id: String, _level: int) -> void:
	var target := Upgrades.camp_stage()
	while stage < target:
		stage += 1
		await _build(stage, true)


## Ajoute les éléments d'un stade ; `animated` : apparition un à un, bandeau, arrivée des villageois.
func _build(s: int, animated: bool) -> void:
	if animated:
		_hud.announce(ANNOUNCES[s])
		AudioManager.play(&"camp_stage")
		# Moment fort : grands rayons au-dessus du feu et bref éclat de l'écran.
		var at := _fire.global_position if _fire else _world.camp_position
		CombatFx.rays(at + Vector2(0, -14), 1.6)
		CombatFx.flash_screen()
		await get_tree().create_timer(0.5).timeout
	if s == 3 and _fire:
		_fire.enlarge()
		if animated:
			CombatFx.burst(_fire.global_position + Vector2(0, -12), GOLD)
			CombatFx.ring(_fire.global_position + Vector2(0, -4), 44.0, GOLD)
	for item in STAGE_PROPS.get(s, []):
		var node := _props.make_prop(item[0], item[1], _world.entity_layer())
		if animated:
			_appear(node)
			await get_tree().create_timer(STEP_DELAY).timeout
	for loop in STAGE_VILLAGERS.get(s, []):
		_add_villager(loop, animated)


func _appear(node: Node2D) -> void:
	CombatFx.puff(node.global_position + Vector2(0, -2))
	node.modulate.a = 0.0
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "modulate:a", 1.0, 0.35)
	# Décor traversable : le nœud est le sprite ; sinon le sprite est le premier enfant du corps.
	var sprite: Sprite2D = node if node is Sprite2D else node.get_child(0)
	if sprite:
		var rest := sprite.position
		sprite.position = rest + Vector2(0, 6)
		tween.tween_property(sprite, "position", rest, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _add_villager(loop: Array, arriving: bool) -> void:
	var v := VILLAGER.new()
	v.skin = VILLAGER_SKINS[_villager_count % VILLAGER_SKINS.size()]
	_villager_count += 1
	v.fire = _fire.global_position if _fire else _world.camp_position
	for p in loop:
		v.waypoints.append(_tile(p))
	v.position = _tile(ARRIVAL) if arriving else v.waypoints[0]
	_world.add_entity(v)
	if arriving:
		v.modulate.a = 0.0
		v.create_tween().tween_property(v, "modulate:a", 1.0, 0.6)


static func _tile(p: Vector2) -> Vector2:
	return p * TileIds.SIZE
