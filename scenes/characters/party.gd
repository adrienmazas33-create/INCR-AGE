class_name Party
extends Node
## Groupe du héros : enregistre sa trace de pas et donne à chaque allié sa place.
## En marche, ils suivent la trace en colonne par deux (donc toujours par un chemin praticable :
## escaliers, ponts). À l'arrêt, ils se rangent en petit groupe derrière le héros.
## Dans la colonne et au repos, les combattants à la lance passent devant, les frondeurs derrière
## (rang dans le groupe) ; en combat, les frondeurs se placent à portée de tir, du côté du héros.
## Futur point d'entrée des ordres collectifs.

const FOLLOWER := preload("res://scenes/characters/follower.tscn")
const SKINS: Array[Texture2D] = [
	preload("res://assets/art/follower_0.png"),
	preload("res://assets/art/follower_1.png"),
	preload("res://assets/art/follower_2.png"),
	preload("res://assets/art/follower_3.png"),
	preload("res://assets/art/follower_4.png"),
	preload("res://assets/art/follower_5.png"),
	preload("res://assets/art/follower_6.png"),
	preload("res://assets/art/follower_7.png"),
]
## Mêmes compagnons en frondeurs : sans lance, fronde en main (planches provisoires).
const SLING_SKINS: Array[Texture2D] = [
	preload("res://assets/art/slinger_0.png"),
	preload("res://assets/art/slinger_1.png"),
	preload("res://assets/art/slinger_2.png"),
	preload("res://assets/art/slinger_3.png"),
	preload("res://assets/art/slinger_4.png"),
	preload("res://assets/art/slinger_5.png"),
	preload("res://assets/art/slinger_6.png"),
	preload("res://assets/art/slinger_7.png"),
]
const TRAIL_STEP := 4.0
const TRAIL_MAX := 400
## Colonne par deux : distance le long de la trace du premier rang, écart entre rangs,
## et décalage latéral de chaque file par rapport à la trace.
const GAP_FIRST := 24.0
const GAP_ROW := 20.0
const FILE_OFFSET := 8.0
## Marge libre exigée au-delà du décalage latéral (rayon du corps et un peu d'air).
const FILE_CLEARANCE := 8.0
## Temps à forcer sans avancer avant de se recentrer sur la trace.
const UNSTICK_TIME := 0.3
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
## Raccrochage à la trace : nombre de points récents examinés d'abord, et distance au-delà de laquelle
## on cherche sur toute la trace.
const REJOIN_RECENT := 120
const REJOIN_MAX_GAP := 48.0
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
## Ouverture de l'éventail des alliés autour d'un ennemi (radians, de part et d'autre du héros).
const COMBAT_FAN := 1.3

## Allure propre à chaque compagnon (troupes organiques) : tirée une fois pour toutes d'après son numéro,
## elle casse la géométrie du groupe sans toucher au suivi de la trace (mêmes garde-fous qu'avant).
## Avance ou retard propre sur la trace, écart propre à la trace, et balancement lent des deux (px).
const GAP_JITTER := 4.0
const LATERAL_JITTER := 3.0
const SWAY := 2.5
## Période du balancement (s), entre ces bornes.
const SWAY_PERIOD := Vector2(5.0, 9.0)
## Écart de vitesse de marche propre (fraction).
const PACE_JITTER := 0.05
## Départ échelonné quand le héros repart après une halte, et arrivée échelonnée à la halte (s, au plus).
const START_STAGGER := 0.3
const IDLE_STAGGER := 0.45
## Place à la halte : décalage tiré à chaque halte (px), petits pas sur place et coups d'œil alentour.
const SLOT_JITTER := 5.0
const FIDGET_EVERY := Vector2(3.0, 7.0)
const FIDGET_STEP := 4.0
const GLANCE_CHANCE := 0.5
## Éventail de combat : angle (rad) et distance (px) propres à chacun.
const FAN_JITTER := 0.12
const REACH_JITTER := 3.0

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
var _world: World
## Allié -> rang dans le groupe (voir _update_ranks).
var _ranks := {}
## Horloge du balancement, et temps de marche depuis la dernière halte (départ échelonné).
var _time := 0.0
var _move_time := 0.0
## Petits pas à la halte : index de l'allié -> décalage actuel, et attente avant le suivant.
var _fidget := {}
var _fidget_wait := {}
## Tirages de la halte (déterministes : une même partie rejoue les mêmes gestes).
var _rng := RandomNumberGenerator.new()


func setup(p_hero: Hero, world: World, count := 3) -> void:
	hero = p_hero
	_world = world
	add_to_group("party")
	_rng.seed = 1789
	_trail = PackedVector2Array([hero.global_position])
	# Rôles enregistrés (ou combattants par défaut), alignés sur le nombre de compagnons.
	GameState.fit_roles(count)
	for i in count:
		add_follower(hero.global_position + _slot_offset(i), GameState.roles[i])


## Ajoute un compagnon à `at` (recrutement) avec le rôle donné ; il rejoint la trace du groupe depuis là.
func add_follower(at: Vector2, role := GameState.DEFAULT_ROLE) -> Follower:
	var f := FOLLOWER.instantiate() as Follower
	f.party = self
	f.index = followers.size()
	_give_gait(f)
	f.assign_role(role)
	f.get_node("Sprite").texture = _skin(f.index, role)
	f.position = at
	if GameState.roles.size() <= f.index:
		GameState.roles.append(role)
	_world.add_entity(f)
	followers.append(f)
	_update_ranks()
	rejoin_trail(f)
	_slots = _compute_idle_slots()
	return f


## Réaffectation au camp : le compagnon `i` passe de la lance à la fronde, ou l'inverse. Gratuit et
## réversible ; aucune unité créée, vie gardée en proportion, un compagnon à terre le reste.
func switch_role(i: int) -> void:
	if i < 0 or i >= followers.size():
		return
	var f := followers[i]
	var role := "spear" if f.is_ranged() else "sling"
	f.convert_role(role, _skin(i, role))
	GameState.set_role(i, role)
	_update_ranks()
	_slots = _compute_idle_slots()


## Allure propre au compagnon, tirée d'après son numéro : le même compagnon garde la même allure
## d'une partie à l'autre et quel que soit son rôle.
func _give_gait(f: Follower) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * (f.index + 1)
	f.pace = 1.0 + rng.randf_range(-PACE_JITTER, PACE_JITTER)
	f.gap_shift = rng.randf_range(-GAP_JITTER, GAP_JITTER)
	f.lateral_shift = rng.randf_range(-LATERAL_JITTER, LATERAL_JITTER)
	f.sway_period = rng.randf_range(SWAY_PERIOD.x, SWAY_PERIOD.y)
	f.sway_phase = rng.randf() * TAU
	f.start_delay = rng.randf() * START_STAGGER
	f.idle_delay = rng.randf() * IDLE_STAGGER
	f.fan_shift = rng.randf_range(-FAN_JITTER, FAN_JITTER)
	f.reach_shift = rng.randf_range(-REACH_JITTER, REACH_JITTER)


func _skin(i: int, role: String) -> Texture2D:
	return (SLING_SKINS if role == "sling" else SKINS)[i % SKINS.size()]


## Rang de chaque allié dans le groupe : les combattants d'abord, dans l'ordre, puis les frondeurs.
## Il donne la place dans la colonne, au repos et dans l'éventail de combat.
func _update_ranks() -> void:
	_ranks.clear()
	for ranged in [false, true]:
		for f in followers:
			if f.is_ranged() == ranged:
				_ranks[f] = _ranks.size()


func _rank(f: Follower) -> int:
	return _ranks.get(f, f.index)


func _physics_process(delta: float) -> void:
	var p := hero.global_position
	var last := _trail[_trail.size() - 1]
	if p.distance_to(last) > 64.0:
		# Le héros a été déplacé d'un bloc (retour au camp, outil de dev) : le groupe le suit.
		_base += _trail.size()
		_trail = PackedVector2Array([p])
		for f in followers:
			f.teleport(p + _slot_offset(_rank(f)))
			_cursor[f.index] = _base
		_slots = _compute_idle_slots()
	elif p.distance_to(last) >= TRAIL_STEP:
		_trail.append(p)
		if _trail.size() > TRAIL_MAX:
			_trail.remove_at(0)
			_base += 1
	_time += delta
	if hero.velocity.length() > 5.0:
		_idle_time = 0.0
		_move_time += delta
		_heading = hero.velocity.normalized()
	else:
		_idle_time += delta
	var was_idle := hero_idle
	hero_idle = _idle_time > IDLE_DELAY
	if hero_idle:
		_move_time = 0.0
	if hero_idle and not was_idle:
		_slots = _compute_idle_slots()
		_fidget.clear()
		_fidget_wait.clear()
	if hero_idle:
		_update_fidgets(delta)
	for f in followers:
		stats["max_gap"] = maxf(stats["max_gap"], f.global_position.distance_to(p))


func target_for(f: Follower) -> Vector2:
	# Halte : chacun gagne sa place à son tour (délai propre), puis y fait de petits pas.
	var slot := hero.global_position + _slot(f)
	if is_resting(f) and slot.is_finite() and f.global_position.distance_to(hero.global_position) < IDLE_REACH \
			and _clear(f.global_position, slot + _fidget.get(f.index, Vector2.ZERO)):
		f.trail_lag = 0.0
		return slot + _fidget.get(f.index, Vector2.ZERO)
	# Départ échelonné : quand le héros repart d'une halte, chacun se met en route à son tour, s'il est
	# encore près de lui.
	if not hero_idle and _move_time < f.start_delay and f.global_position.distance_to(hero.global_position) < IDLE_REACH:
		f.trail_lag = 0.0
		return f.global_position
	# Place dans la colonne : avance et écart propres, qui se balancent lentement.
	var sway := _time * TAU / f.sway_period + f.sway_phase
	var gap := _gap(_rank(f)) + f.gap_shift + sin(sway) * SWAY
	var file := FILE_OFFSET + f.lateral_shift + cos(sway) * SWAY
	# Suivi de trajectoire : viser un point de la trace un peu en avant de sa propre position,
	# jamais en ligne droite vers sa place (sinon il coupe les virages et bute sur les falaises).
	# Un allié qui force sans avancer revient exactement sur la trace, avec une visée plus courte.
	var hindered := f.stuck_time > UNSTICK_TIME
	var lateral := 0.0 if hindered else (file if _rank(f) % 2 else -file)
	var ahead := _length_to_hero(_track(f))
	f.trail_lag = maxf(ahead - gap, 0.0)
	if ahead <= gap:
		return _on_trail(gap, lateral)
	return _on_trail(maxf(gap, ahead - (LOOKAHEAD * 0.5 if hindered else LOOKAHEAD)), lateral)


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
## (éventail de ±75° pour les combattants, ±45° pour les frondeurs), pour qu'ils ne s'empilent pas et
## restent lisibles. Les frondeurs se tiennent aux trois quarts de leur portée : derrière les combattants.
func combat_spot(f: Follower, foe: Combatant) -> Vector2:
	var toward_hero := hero.global_position - foe.global_position
	var dir := toward_hero.normalized() if toward_hero.length() > 0.1 else Vector2.LEFT
	var ranged := 0
	for other in followers:
		ranged += 1 if other.is_ranged() else 0
	var melee := followers.size() - ranged
	if f.is_ranged():
		var k := _rank(f) - melee
		dir = dir.rotated((0.0 if ranged < 2 else lerpf(-0.8, 0.8, float(k) / (ranged - 1))) + f.fan_shift)
		return foe.global_position + dir * (foe.stats.body_radius + f.stats.body_radius + f.stats.attack_range * 0.75 + f.reach_shift)
	var r := _rank(f)
	dir = dir.rotated((0.0 if melee < 2 else lerpf(-COMBAT_FAN, COMBAT_FAN, float(r) / (melee - 1))) + f.fan_shift)
	# Au-delà de quatre combattants, un sur deux se tient au second rang pour ne pas s'empiler.
	# Chacun garde un léger écart d'angle et de distance : l'éventail n'est pas tiré au cordeau.
	var depth := 8.0 if melee > 4 and r % 2 else 0.0
	return foe.global_position + dir * (foe.stats.body_radius + f.stats.body_radius + f.stats.attack_range * 0.6 + depth + absf(f.reach_shift) * 0.5)


## Après un combat ou une relève, l'allié reprend la trace là où il se trouve.
## On cherche d'abord dans la partie récente de la trace : là où elle repasse sur elle-même (aller-retour),
## l'allié ne doit pas se raccrocher à l'ancien passage et repartir à contresens.
func rejoin_trail(f: Follower) -> void:
	var n := _trail.size()
	var recent := _nearest_index(f.global_position, maxi(n - REJOIN_RECENT, 0), n)
	if f.global_position.distance_to(_trail[recent]) > REJOIN_MAX_GAP:
		recent = _nearest_index(f.global_position, 0, n)
	_cursor[f.index] = _base + recent


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
	f.teleport(_on_trail(_gap(_rank(f)), 0.0))
	rejoin_trail(f)
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


## Halte du compagnon : le héros est arrêté depuis assez longtemps pour lui (arrivée échelonnée).
func is_resting(f: Follower) -> bool:
	return hero_idle and _idle_time > IDLE_DELAY + f.idle_delay


## Place de l'allié à la halte, relative au héros ; Vector2.INF si elle est inaccessible.
func _slot(f: Follower) -> Vector2:
	return _slots[f.index] if f.index < _slots.size() else Vector2.INF


## Halte : de temps à autre, chaque compagnon arrivé à sa place fait un petit pas autour d'elle (jamais
## au-delà de FIDGET_STEP, ni à travers un obstacle) ou jette un coup d'œil alentour.
func _update_fidgets(delta: float) -> void:
	for f in followers:
		var wait: float = _fidget_wait.get(f.index, _rng.randf_range(FIDGET_EVERY.x, FIDGET_EVERY.y)) - delta
		if wait <= 0.0:
			wait = _rng.randf_range(FIDGET_EVERY.x, FIDGET_EVERY.y)
			var slot := hero.global_position + _slot(f)
			if not f.is_alive() or not is_resting(f) or not slot.is_finite():
				pass
			elif _rng.randf() < GLANCE_CHANCE:
				f.glance(Vector2.from_angle(_rng.randf() * TAU), _rng.randf_range(0.8, 1.8))
			else:
				var step := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(FIDGET_STEP * 0.5, FIDGET_STEP)
				_fidget[f.index] = step if _clear(slot, slot + step * 2.0) else Vector2.ZERO
		_fidget_wait[f.index] = wait


func debug_summary() -> String:
	var gaps := []
	var roles := []
	for f in followers:
		gaps.append(int(f.global_position.distance_to(hero.global_position)))
		roles.append("%s %d/%d PV%s" % ["fronde" if f.is_ranged() else "lance", f.health.current, f.health.max_health,
			"" if f.is_alive() else " (K.O.)"])
	return "groupe : écarts actuels %s px, écart max %d px, %d retour(s) forcé(s)%s\n  compagnons : %s" % [gaps,
		stats["max_gap"], stats["teleports"], "" if _events.is_empty() else "\n  " + "\n  ".join(_events), ", ".join(roles)]


func _gap(i: int) -> float:
	return GAP_FIRST + GAP_ROW * (i / 2)


## Point de la trace à `dist` derrière le héros, décalé sur la file (gauche ou droite) de l'allié `i`.
## Le décalage n'est appliqué que s'il reste de la place (escalier, pont, coin de bosquet...).
func _on_trail(dist: float, lateral: float) -> Vector2:
	var p := point_behind(dist)
	var tangent := point_behind(maxf(dist - 8.0, 0.0)) - point_behind(dist + 8.0)
	if is_zero_approx(lateral) or tangent.length() < 0.5:
		return p
	var side := tangent.normalized().orthogonal() * lateral
	if not _clear(p, p + side * (1.0 + FILE_CLEARANCE / absf(lateral))):
		return p
	return p + side


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


## Places à l'arrêt, calculées une fois par halte ; chacune est légèrement décalée (tirage de la halte),
## pour un petit groupe moins géométrique. Une place hors d'atteinte directe (mur, falaise) est écartée.
func _compute_idle_slots() -> Array[Vector2]:
	var space := hero.get_world_2d().direct_space_state
	var out: Array[Vector2] = []
	for f in followers:
		var offset := _slot_offset(_rank(f)) + Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * SLOT_JITTER
		var from := hero.global_position + Vector2(0, -3)
		var to := from + offset
		var query := PhysicsRayQueryParameters2D.create(from, to + (to - from).normalized() * 6.0, WORLD_MASK)
		out.append(Vector2.INF if not space.intersect_ray(query).is_empty() else offset)
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
