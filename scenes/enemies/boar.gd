class_name Boar
extends Combatant
## Sanglier. Erre près de son repaire, repère le groupe, prépare une charge bien visible (tête basse,
## œil rouge, poussière), fonce en ligne droite, puis reste étourdi un instant : c'est le moment de
## le frapper, ou de s'écarter de sa trajectoire. Affaibli, il fuit. Il ne s'éloigne jamais beaucoup
## de son repaire : il n'entraîne pas le joueur au loin.

enum State { WANDER, CHASE, WINDUP, CHARGE, RECOVER, FLEE, RETURN, DEAD }

const PICKUP := preload("res://scenes/loot/pickup.gd")

@export var aggro_radius := 80.0
@export var leash_radius := 7.0 * 32.0
@export var charge_trigger := 80.0
@export var windup_time := 0.55
@export var charge_speed := 230.0
@export var charge_time := 0.4
@export var recover_time := 0.8
@export var flee_ratio := 0.25
@export var flee_time := 2.0

const WANDER_RADIUS := 2.5 * 32.0
## Le sanglier fixe la direction de sa charge à cette fraction de la préparation : on peut l'esquiver.
const AIM_LOCK := 0.35
const CONTACT := 10.0
const LOST_SIGHT_TIME := 4.0
const IMPACT_STOP := 0.06

var home := Vector2.ZERO

var _state := State.WANDER
var _timer := 0.0
var _target: Combatant
var _dir := Vector2.RIGHT
var _goal := Vector2.ZERO
var _hit: Array[Combatant] = []
var _fled := false
var _aim_locked := false
var _anim_time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super()
	home = global_position
	_rng.seed = hash(home)
	_goal = home
	_timer = _rng.randf_range(0.5, 2.0)


func _physics_process(delta: float) -> void:
	_timer -= delta
	var move := Vector2.ZERO
	match _state:
		State.WANDER:
			move = _wander()
			var seen := Targeting.nearest(self, &"party_members", aggro_radius)
			if seen and seen.global_position.distance_to(home) < leash_radius:
				_engage(seen)
		State.CHASE:
			# Sans vue sur sa cible pendant un moment (contourné, caché), il abandonne.
			var sight := _target_valid() and Targeting.has_sight(self, global_position, _target.global_position)
			if sight:
				_timer = LOST_SIGHT_TIME
			if not _target_valid() or _target.global_position.distance_to(home) > leash_radius or _timer <= 0.0:
				_set_state(State.RETURN)
			elif sight and edge_distance(_target) <= charge_trigger:
				_set_state(State.WINDUP, windup_time)
				AudioManager.play(&"boar_grunt", global_position)
				_aim_locked = false
			else:
				move = global_position.direction_to(_target.global_position) * stats.move_speed
		State.WINDUP:
			if not _aim_locked and _target_valid():
				_dir = global_position.direction_to(_target.global_position)
				if _timer < windup_time * (1.0 - AIM_LOCK):
					_aim_locked = true
			if int(_timer * 10.0) != int((_timer + delta) * 10.0):
				CombatFx.puff(global_position + Vector2(-_dir.x * 10.0, -2))
			if _timer <= 0.0:
				_set_state(State.CHARGE, charge_time)
				_hit.clear()
		State.CHARGE:
			move = _dir * charge_speed
			_charge_hits()
		State.RECOVER:
			if _timer <= 0.0:
				_set_state(State.CHASE if _target_valid() else State.RETURN)
		State.FLEE:
			var threat := Targeting.nearest(self, &"party_members", 200.0, false)
			var away := global_position - threat.global_position if threat else global_position - home
			move = away.normalized() * stats.move_speed * 1.3
			if global_position.distance_to(home) > leash_radius:
				move = global_position.direction_to(home) * stats.move_speed * 1.3
			if _timer <= 0.0:
				_set_state(State.RETURN)
		State.RETURN:
			move = global_position.direction_to(home) * stats.move_speed * 1.2
			health.heal(stats.max_health * 0.15 * delta)
			if global_position.distance_to(home) < 10.0:
				_set_state(State.WANDER, _rng.randf_range(0.5, 1.5))
	velocity = move + (Vector2.ZERO if _state == State.CHARGE else consume_knockback(delta))
	move_and_slide()
	if _state == State.CHARGE:
		if get_slide_collision_count() > 0:
			# Il percute un obstacle : sonné plus longtemps.
			CombatFx.puff(global_position + _dir * 12.0 + Vector2(0, -4))
			CombatFx.shake(1.0)
			_set_state(State.RECOVER, recover_time * 1.5)
		elif _timer <= 0.0:
			_set_state(State.RECOVER, recover_time)


func _wander() -> Vector2:
	if global_position.distance_to(_goal) > 4.0 and _timer > -3.0:
		return global_position.direction_to(_goal) * stats.move_speed * 0.45
	if _timer <= 0.0:
		_goal = home + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(8.0, WANDER_RADIUS)
		_timer = _rng.randf_range(1.5, 3.5)
	return Vector2.ZERO


func _charge_hits() -> void:
	for node in get_tree().get_nodes_in_group(&"party_members"):
		var m := node as Combatant
		if m and m.is_alive() and not m in _hit and edge_distance(m) <= CONTACT:
			_hit.append(m)
			m.receive_hit(stats.damage, global_position - _dir * 8.0, stats.knockback)
			# Il s'arrête net sur sa victime et reste étourdi à côté d'elle : le moment de riposter.
			_timer = minf(_timer, IMPACT_STOP)


func _engage(target: Combatant) -> void:
	_target = target
	_set_state(State.CHASE, LOST_SIGHT_TIME)


func _target_valid() -> bool:
	return is_instance_valid(_target) and _target.is_alive()


func _set_state(s: State, time := 0.0) -> void:
	_state = s
	_timer = time


func _on_hit(from: Vector2) -> void:
	if _state in [State.WANDER, State.RETURN]:
		var attacker := Targeting.nearest(self, &"party_members", 120.0, false)
		if attacker:
			_engage(attacker)
	if not _fled and health.ratio() < flee_ratio and _state != State.CHARGE:
		_fled = true
		_set_state(State.FLEE, flee_time)


## Le groupe est revenu au camp : on oublie le combat.
func reset_aggro() -> void:
	if is_alive():
		_target = null
		_set_state(State.RETURN)


func _on_died() -> void:
	_set_state(State.DEAD)
	collision_layer = 0
	remove_from_group(&"enemies")
	_drop_loot()
	CombatFx.poof(global_position + Vector2(0, -8))
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	super()


func _drop_loot() -> void:
	var items := []
	for kind in stats.drops:
		var span: Array = stats.drops[kind]
		for i in _rng.randi_range(span[0], span[1]):
			items.append(kind)
	if _rng.randf() < stats.knowledge_chance:
		items.append("knowledge")
	for kind in items:
		var p := PICKUP.new()
		p.position = global_position + Vector2(0, -2)
		p.launch(kind, Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(30.0, 70.0), _rng.randf_range(110.0, 160.0))
		get_parent().add_child(p)


func _animate(delta: float) -> void:
	_anim_time += delta
	var frame := 0
	var shake := 0.0
	match _state:
		State.WINDUP:
			frame = 6
			shake = 1.0 if int(_anim_time * 30.0) % 2 else -1.0
		State.DEAD:
			frame = 7
		State.RECOVER:
			frame = int(_anim_time * 3.0) % 2
			shake = signf(sin(_anim_time * 12.0))
		_:
			if velocity.length() > 8.0:
				var fps := 16.0 if _state == State.CHARGE else 9.0 * velocity.length() / stats.move_speed
				frame = 2 + int(_anim_time * fps) % 4
			else:
				frame = int(_anim_time * 2.0) % 2
	sprite.frame = frame
	var facing := _dir.x if _state in [State.WINDUP, State.CHARGE] else velocity.x
	if absf(facing) > 1.0:
		sprite.flip_h = facing < 0.0
	# L'image est décentrée (tête à droite) : on recale le décalage quand elle est retournée.
	sprite.offset = Vector2(-2.0 if sprite.flip_h else 2.0, -12.0)
	sprite.position.x += shake
