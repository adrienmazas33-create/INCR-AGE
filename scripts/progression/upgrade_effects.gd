class_name UpgradeEffects
extends Node
## Applique en jeu les améliorations achetées, avec leur retour visuel, et affiche au-dessus du feu
## un repère doré tant qu'un achat est possible (pour attirer le joueur au campement).

const MARKER := preload("res://assets/art/fx/marker.png")
const GOLD := Color8(255, 214, 90)
const GREEN := Color8(140, 236, 110)
## Distance au feu sous laquelle le repère s'efface (le panneau du camp prend le relais).
const MARKER_HIDE_RADIUS := 120.0

var _party: Party
var _camp := Vector2.ZERO
var _marker := Sprite2D.new()
var _time := 0.0


func setup(party: Party, camp: Vector2, layer: Node2D) -> void:
	_party = party
	_camp = camp
	_marker.texture = MARKER
	_marker.z_index = 5
	_marker.visible = false
	layer.add_child(_marker)
	GameState.upgrade_bought.connect(_on_bought)


func _process(delta: float) -> void:
	_time += delta
	var near := _party.hero.global_position.distance_to(_camp) < MARKER_HIDE_RADIUS
	_marker.visible = not near and Upgrades.any_affordable()
	_marker.position = _camp + Vector2(0, -40 - roundf(sin(_time * 3.0) * 2.0))


func _on_bought(id: String, _level: int) -> void:
	var members: Array = [_party.hero]
	members.append_array(_party.followers)
	match id:
		"recruit":
			var at := _camp + Vector2(randf_range(-16.0, 16.0), 24.0)
			var recruit := _party.add_follower(at)
			recruit.glow(GOLD, 1.2)
			CombatFx.burst(at + Vector2(0, -10), GOLD)
		"damage":
			for m in members:
				m.glow(GOLD)
				CombatFx.sparkle(m.global_position + Vector2(0, -16), GOLD)
		"vigor":
			for m in members:
				m.refresh_max_health(true)
				m.glow(GREEN)
				CombatFx.sparkle(m.global_position + Vector2(0, -16), GREEN)
		"magnet":
			CombatFx.ring(_party.hero.global_position + Vector2(0, -4), Upgrades.magnet_radius(), GOLD)
