class_name Party
extends Node
## Groupe du héros : enregistre sa trace de pas et donne à chaque allié sa place.
## En marche, chacun suit la trace à distance fixe (donc toujours par un chemin praticable :
## escaliers, ponts). À l'arrêt, ils se rangent en petit groupe derrière le héros.
## Futur point d'entrée des ordres collectifs.

const FOLLOWER := preload("res://scenes/characters/follower.tscn")
const SKINS: Array[Texture2D] = [
	preload("res://assets/art/follower_0.png"),
	preload("res://assets/art/follower_1.png"),
	preload("res://assets/art/follower_2.png"),
]
const TRAIL_STEP := 4.0
const TRAIL_MAX := 400
## Distance le long de la trace entre le héros et chaque allié (puis +22 px par allié en plus).
const TRAIL_GAPS := [24.0, 46.0, 68.0]
## Places à l'arrêt, en repère « derrière / côté » du héros.
const IDLE_SLOTS := [Vector2(20, 15), Vector2(20, -15), Vector2(36, 2)]
const IDLE_DELAY := 0.35
## Au-delà, l'allié ne rejoint pas sa place à l'arrêt en ligne droite : il remonte la trace.
const IDLE_REACH := 70.0
## Avance du point visé sur la trace, et fenêtre de recherche de la position sur la trace (en points).
const LOOKAHEAD := 16.0
const TRACK_BACK := 8
const TRACK_AHEAD := 24
const BACKTRACK_PENALTY := 100.0
const SEPARATION_RADIUS := 13.0
const SEPARATION_PUSH := 50.0
const REGROUP_DISTANCE := 12.0 * TileIds.SIZE
const STUCK_REGROUP_OFFSCREEN := 1.0
const STUCK_REGROUP_ANYWAY := 4.0
const WORLD_MASK := 1
## Un ennemi n'est attaqué par les alliés que s'il est à cette distance du héros...
const ENGAGE_RADIUS := 110.0
## ...et ils le lâchent s'il s'en éloigne au-delà : pas de poursuite sans fin.
const LEASH_RADIUS := 150.0
## Angle (radians) de chaque allié autour de l'ennemi, par rapport à la direction du héros.
const COMBAT_FAN := [-0.9, 0.9, 0.0]

var hero: Hero
var followers: Array[Follower] = []
var hero_idle := false
## Statistiques de contrôle (outil de développement).
var stats := {"teleports": 0, "max_gap": 0.0}

var _events: Array[String] = []
var _trail := PackedVector2Array()
## Les points de trace ont un index absolu (_base + index local) pour survivre au rognage de la trace.
var _base := 0
## Index absolu du point de trace où se trouve chaque allié.
var _cursor := {}
var _idle_time := 0.0
var _heading := Vector2.DOWN
## Places à l'arrêt, relatives au héros ; Vector2.INF = place inaccessible.
var _slots: Array[Vector2] = []


func setup(p_hero: Hero, world: World, count := 3) -> void:
	hero = p_hero
	add_to_group("party")
	_trail = PackedVector2Array([hero.global_position])
	for i in count:
		var f := FOLLOWER.instantiate() as Follower
		f.party = self
		f.index = i
		f.get_node("Sprite").texture = SKINS[i % SKINS.size()]
		f.position = hero.global_position + _slot_offset(i)
		world.add_entity(f)
		followers.append(f)


func _physics_process(delta: float) -> void:
	var p := hero.global_position
	var last := _trail[_trail.size() - 1]
	if p.distance_to(last) > 64.0:
		# Le héros a été déplacé d'un bloc (retour au camp, outil de dev) : le groupe le suit.
		_base += _trail.size()
		_trail = PackedVector2Array([p])
		for f in followers:
			f.teleport(p + _slot_offset(f.index))
			_cursor[f.index] = _base
		_slots = _compute_idle_slots()
	elif p.distance_to(last) >= TRAIL_STEP:
		_trail.append(p)
		if _trail.size() > TRAIL_MAX:
			_trail.remove_at(0)
			_base += 1
	if hero.velocity.length() > 5.0:
		_idle_time = 0.0
		_heading = hero.velocity.normalized()
	else:
		_idle_time += delta
	var was_idle := hero_idle
	hero_idle = _idle_time > IDLE_DELAY
	if hero_idle and not was_idle:
		_slots = _compute_idle_slots()
	for f in followers:
		stats["max_gap"] = maxf(stats["max_gap"], f.global_position.distance_to(p))


func target_for(f: Follower) -> Vector2:
	if hero_idle and f.index < _slots.size() and _slots[f.index] != Vector2.INF \
			and f.global_position.distance_to(hero.global_position) < IDLE_REACH \
			and _clear(f.global_position, hero.global_position + _slots[f.index]):
		return hero.global_position + _slots[f.index]
	var gap := _gap(f.index)
	# Suivi de trajectoire : viser un point de la trace un peu en avant de sa propre position,
	# jamais en ligne droite vers sa place (sinon il coupe les virages et bute sur les falaises).
	var ahead := _length_to_hero(_track(f))
	if ahead <= gap:
		return point_behind(gap)
	return point_behind(maxf(gap, ahead - LOOKAHEAD))


## Ennemi que l'allié doit combattre : seulement un ennemi proche du héros (le joueur décide où l'on se bat
## par sa position), et l'allié lâche prise dès que l'ennemi s'éloigne trop du héros.
func foe_for(f: Follower, current: Combatant) -> Combatant:
	var anchor := hero.global_position
	if is_instance_valid(current) and current.is_alive() and current.global_position.distance_to(anchor) <= LEASH_RADIUS:
		return current
	var best: Combatant = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var e := node as Combatant
		if e == null or not e.is_alive() or e.global_position.distance_to(anchor) > ENGAGE_RADIUS:
			continue
		var d := f.global_position.distance_to(e.global_position)
		if d < best_d and Targeting.has_sight(f, f.global_position, e.global_position):
			best = e
			best_d = d
	return best


## Place de combat autour de l'ennemi : du côté du héros, chaque allié sur son propre angle
## (éventail de ±50°), pour qu'ils ne s'empilent pas et restent lisibles.
func combat_spot(f: Follower, foe: Combatant) -> Vector2:
	var toward_hero := hero.global_position - foe.global_position
	var dir := toward_hero.normalized() if toward_hero.length() > 0.1 else Vector2.LEFT
	dir = dir.rotated(COMBAT_FAN[f.index % COMBAT_FAN.size()])
	return foe.global_position + dir * (foe.stats.body_radius + f.stats.body_radius + f.stats.attack_range * 0.6)


## Après un combat ou une relève, l'allié reprend la trace là où il se trouve.
func rejoin_trail(f: Follower) -> void:
	_cursor[f.index] = _base + _nearest_index(f.global_position, 0, _trail.size())


## Poussée qui écarte un allié de ses voisins et du héros.
func separation(f: Follower) -> Vector2:
	var push := Vector2.ZERO
	for other in followers:
		if other != f:
			push += _repel(f.global_position, other.global_position, SEPARATION_RADIUS)
	push += _repel(f.global_position, hero.global_position, SEPARATION_RADIUS + 2.0)
	return push


func should_regroup(f: Follower, stuck_time: float) -> bool:
	if stuck_time > STUCK_REGROUP_ANYWAY:
		return true
	var far := f.global_position.distance_to(hero.global_position) > REGROUP_DISTANCE
	return (far or stuck_time > STUCK_REGROUP_OFFSCREEN) and not _visible_rect().has_point(f.global_position)


func regroup(f: Follower) -> void:
	_events.append("allié %d en %s (héros %s)" % [f.index, Vector2i(f.global_position / TileIds.SIZE), Vector2i(hero.global_position / TileIds.SIZE)])
	f.teleport(point_behind(_gap(f.index)))
	_cursor[f.index] = _base + _nearest_index(f.global_position, 0, _trail.size())
	stats["teleports"] += 1


## Point situé à `dist` pixels derrière le héros, en suivant sa trace.
func point_behind(dist: float) -> Vector2:
	var prev := hero.global_position
	var remaining := dist
	for i in range(_trail.size() - 1, -1, -1):
		var seg := prev.distance_to(_trail[i])
		if seg >= remaining and seg > 0.0:
			return prev.lerp(_trail[i], remaining / seg)
		remaining -= seg
		prev = _trail[i]
	return prev


func debug_summary() -> String:
	var gaps := []
	for f in followers:
		gaps.append(int(f.global_position.distance_to(hero.global_position)))
	return "groupe : écarts actuels %s px, écart max %d px, %d retour(s) forcé(s)%s" % [gaps, stats["max_gap"], stats["teleports"],
		"" if _events.is_empty() else "\n  " + "\n  ".join(_events)]


func _gap(i: int) -> float:
	return TRAIL_GAPS[i] if i < TRAIL_GAPS.size() else TRAIL_GAPS[-1] + 22.0 * (i - TRAIL_GAPS.size() + 1)


## Point de trace où se trouve l'allié. La recherche reste dans une fenêtre autour de sa position
## précédente : il ne « saute » jamais vers un autre passage de la trace (au-dessus d'une falaise...).
func _track(f: Follower) -> int:
	var local := clampi(int(_cursor.get(f.index, _base)) - _base, 0, _trail.size() - 1)
	var best := _nearest_index(f.global_position, maxi(local - TRACK_BACK, 0), mini(local + TRACK_AHEAD, _trail.size()), local)
	_cursor[f.index] = _base + best
	return best


## Point de trace le plus proche de `pos` entre `from` et `to`. Les points plus récents l'emportent
## à distance égale, et revenir avant `anchor` est pénalisé : là où la trace repasse sur elle-même
## (demi-tour), l'allié prend le raccourci au lieu d'osciller.
func _nearest_index(pos: Vector2, from: int, to: int, anchor := 0) -> int:
	var best := from
	var best_d := INF
	for i in range(from, to):
		var d := pos.distance_squared_to(_trail[i]) + (BACKTRACK_PENALTY if i < anchor else 0.0)
		if d <= best_d:
			best_d = d
			best = i
	return best


## Distance le long de la trace entre le point `i` et le héros.
func _length_to_hero(i: int) -> float:
	var total := 0.0
	for k in range(i, _trail.size() - 1):
		total += _trail[k].distance_to(_trail[k + 1])
	return total + _trail[_trail.size() - 1].distance_to(hero.global_position)


func _clear(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from + Vector2(0, -3), to + Vector2(0, -3), WORLD_MASK)
	return hero.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _slot_offset(i: int) -> Vector2:
	var back := -_heading
	var slot: Vector2 = IDLE_SLOTS[i % IDLE_SLOTS.size()] + Vector2(18.0 * (i / IDLE_SLOTS.size()), 0)
	return back * slot.x + back.orthogonal() * slot.y


## Places à l'arrêt, calculées une fois ; une place hors d'atteinte directe (mur, falaise) est écartée.
func _compute_idle_slots() -> Array[Vector2]:
	var space := hero.get_world_2d().direct_space_state
	var out: Array[Vector2] = []
	for f in followers:
		var from := hero.global_position + Vector2(0, -3)
		var to := from + _slot_offset(f.index)
		var query := PhysicsRayQueryParameters2D.create(from, to + (to - from).normalized() * 6.0, WORLD_MASK)
		out.append(Vector2.INF if not space.intersect_ray(query).is_empty() else _slot_offset(f.index))
	return out


func _repel(a: Vector2, b: Vector2, radius: float) -> Vector2:
	var d := a.distance_to(b)
	if d >= radius:
		return Vector2.ZERO
	var dir := (a - b) / d if d > 0.01 else Vector2.RIGHT
	return dir * (radius - d) / radius * SEPARATION_PUSH


func _visible_rect() -> Rect2:
	var vp := hero.get_viewport()
	return (vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()).grow(16.0)
