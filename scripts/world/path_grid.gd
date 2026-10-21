class_name PathGrid
extends RefCounted
## Recherche de chemin du déplacement à la souris : A* (AStar2D) sur les cases de MapData, avec les
## mêmes règles de passage que le terrain (on ne change de niveau que par un escalier). Les bâtiments
## ajoutés par l'évolution du camp, absents de la carte, sont relevés par requête physique autour du feu.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
## Demi-taille (en cases) de la zone où le camp peut grandir, autour du feu.
const CAMP_AREA := Vector2i(14, 10)
## Écart maximal (en cases) entre le clic et la case praticable retenue : au-delà, clic refusé.
const SNAP_RADIUS := 1.5
## Point visé dans une case : au niveau des pieds, comme le placement du héros.
const FOOT := Vector2(16, 22)

var _map: MapData
var _astar := AStar2D.new()
var _camp_cell := Vector2i.ZERO
var _probe := PhysicsShapeQueryParameters2D.new()


func _init(map: MapData, camp: Vector2) -> void:
	_map = map
	_camp_cell = Vector2i(camp / TileIds.SIZE)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 18)
	_probe.shape = shape
	_probe.collision_mask = 1
	_astar.reserve_space(map.width * map.height)
	# Passages orthogonaux permis, un bit par direction (ordre de DIRS), calculés une seule fois.
	var steps := PackedByteArray()
	steps.resize(map.width * map.height)
	for y in map.height:
		for x in map.width:
			var c := Vector2i(x, y)
			if map.is_cell_blocked(c):
				continue
			_astar.add_point(_id(c), Vector2(c) + Vector2(0.5, 0.5))
			var bits := 0
			for i in 4:
				if map.can_step(c, c + DIRS[i]):
					bits |= 1 << i
			steps[_id(c)] = bits
	for y in map.height:
		for x in map.width:
			var c := Vector2i(x, y)
			var id := _id(c)
			var bits := steps[id]
			for i in 4:
				if bits & (1 << i):
					_astar.connect_points(id, _id(c + DIRS[i]), false)
			# Diagonale permise seulement si les deux passages orthogonaux le sont (pas de coin rogné).
			for i in range(4, 8):
				var d := DIRS[i]
				var hx := 0 if d.x > 0 else 1
				var vy := 2 if d.y > 0 else 3
				if bits & (1 << hx) and bits & (1 << vy) \
						and steps[_id(c + Vector2i(d.x, 0))] & (1 << vy) and steps[_id(c + Vector2i(0, d.y))] & (1 << hx):
					_astar.connect_points(id, _id(c + d), false)


## Chemin en pixels de `from` vers `to` (vide si la destination est inaccessible).
func find_path(from: Vector2, to: Vector2, space: PhysicsDirectSpaceState2D) -> PackedVector2Array:
	_refresh_camp(space)
	var start := _astar.get_closest_point(from / TileIds.SIZE)
	var goal := _astar.get_closest_point(to / TileIds.SIZE)
	if start < 0 or goal < 0 or _astar.get_point_position(goal).distance_to(to / TileIds.SIZE) > SNAP_RADIUS:
		return PackedVector2Array()
	var cells := _astar.get_point_path(start, goal)
	var path := PackedVector2Array()
	for p in cells:
		path.append((p - Vector2(0.5, 0.5)) * TileIds.SIZE + FOOT)
	# Dernier point : l'endroit exact du clic quand il tombe dans la case retenue.
	if not path.is_empty() and Vector2i(to / TileIds.SIZE) == _cell(goal):
		path[path.size() - 1] = to
	return path


## Désactive les cases du camp occupées par un bâtiment ajouté depuis le lancement.
func _refresh_camp(space: PhysicsDirectSpaceState2D) -> void:
	for y in range(_camp_cell.y - CAMP_AREA.y, _camp_cell.y + CAMP_AREA.y + 1):
		for x in range(_camp_cell.x - CAMP_AREA.x, _camp_cell.x + CAMP_AREA.x + 1):
			var c := Vector2i(x, y)
			if not _astar.has_point(_id(c)) or _astar.is_point_disabled(_id(c)):
				continue
			_probe.transform = Transform2D(0.0, Vector2(c * TileIds.SIZE) + Vector2(16, 16))
			if not space.intersect_shape(_probe, 1).is_empty():
				_astar.set_point_disabled(_id(c))


func _id(c: Vector2i) -> int:
	return c.y * _map.width + c.x


func _cell(id: int) -> Vector2i:
	return Vector2i(id % _map.width, id / _map.width)
