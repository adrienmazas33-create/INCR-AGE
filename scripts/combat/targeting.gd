class_name Targeting
## Requêtes de ciblage partagées. Groupes : "party_members" (héros et alliés debout), "enemies".

const WORLD_MASK := 1


## Unité vivante du groupe `group` la plus proche de `from`, à moins de `max_distance` (de bord à bord)
## et, si demandé, en vue directe (pas de mur, falaise ou eau entre les deux).
static func nearest(from: Combatant, group: StringName, max_distance: float, need_sight := true) -> Combatant:
	var best: Combatant = null
	var best_d := max_distance
	for node in from.get_tree().get_nodes_in_group(group):
		var other := node as Combatant
		if other == null or other == from or not other.is_alive():
			continue
		var d := from.edge_distance(other)
		if d <= best_d and (not need_sight or has_sight(from, from.global_position, other.global_position)):
			best = other
			best_d = d
	return best


static func has_sight(any_node: Node2D, a: Vector2, b: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(a + Vector2(0, -3), b + Vector2(0, -3), WORLD_MASK)
	return any_node.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
