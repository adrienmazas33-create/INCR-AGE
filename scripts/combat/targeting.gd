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


## Carte et corps du terrain, renseignés au lancement : servent aux lignes de tir.
static var map: MapData
static var terrain_body: RID


## Ligne de tir d'une pierre : null si elle est libre, sinon le point où la pierre s'arrête.
## Une pierre vole au-dessus de l'eau, mais forêts et faces de falaise l'arrêtent (cases entières, vérifiées
## case par case), comme les décors posés sur la carte ou ajoutés ensuite (arbres isolés, buissons,
## rochers, huttes, bâtiments du village : leur vraie collision, par un rayon qui ignore le seul bloc de
## terrain, où se trouve l'eau). Les vues directes du combat ne changent pas.
static func shot_blocker(any_node: Node2D, a: Vector2, b: Vector2) -> Variant:
	if map:
		var length := a.distance_to(b)
		var steps := maxi(int(length / 4.0), 1)
		for i in range(1, steps + 1):
			var p := a.lerp(b, float(i) / steps)
			var c := Vector2i(p / TileIds.SIZE)
			if map.in_bounds(c) and map.ground_at(c) in [MapData.Ground.FOREST, MapData.Ground.FACE]:
				return p
	var query := PhysicsRayQueryParameters2D.create(a + Vector2(0, -3), b + Vector2(0, -3), WORLD_MASK)
	if terrain_body.is_valid():
		query.exclude = [terrain_body]
	var hit := any_node.get_world_2d().direct_space_state.intersect_ray(query)
	return null if hit.is_empty() else hit["position"] + Vector2(0, 3)
