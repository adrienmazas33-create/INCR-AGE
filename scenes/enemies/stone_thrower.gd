class_name StoneThrower
extends Combatant
## Lanceur de pierres d'un clan rival. Il reste aux abords de son repaire, repère le groupe de loin et
## garde ses distances pour lancer : brève préparation bien visible (lueur rouge, petit tremblement),
## puis une pierre file vers l'endroit où se tenait sa cible au départ, sans la suivre : on l'esquive
## en bougeant. Si on l'approche de près, il recule un instant, seulement si la voie est libre et sans
## quitter les abords de son repaire ; sinon il tient bon et continue de lancer. Il abandonne quand le
## groupe s'éloigne de son repaire, et y retourne.

enum State { IDLE, ENGAGE, WINDUP, BACKOFF, RETURN, DEAD }

## Distance de repérage (bord à bord) et rayon autour du repaire au-delà duquel il ne va pas.
@export var aggro_radius := 130.0
@export var leash_radius := 5.0 * 32.0
## Il s'approche jusqu'à cette distance de sa cible ; plus près que `backoff_trigger`, il recule.
@export var keep_distance := 85.0
@export var backoff_trigger := 44.0
@export var backoff_time := 0.7
## Délai minimal entre deux reculs : pas d'oscillation permanente.
@export var backoff_cooldown := 2.5
@export var stone_speed := 170.0

const WANDER_RADIUS := 1.5 * 32.0
## Sans ligne de tir sur sa cible pendant ce temps, il abandonne.
const LOST_SIGHT_TIME := 3.0
const ANIM_SPEED := 60.0
const DANGER := Color8(226, 64, 52)

var home := Vector2.ZERO

var _state := State.IDLE
var _timer := 0.0
var _cooldown := 0.0
var _backoff_wait := 0.0
var _backoff_dir := Vector2.ZERO
var _target: Combatant
var _goal := Vector2.ZERO
var _move := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super()
	home = global_position
	_goal = home
	_rng.seed = hash(home)
	# Premier lancer décalé d'un lanceur à l'autre : jamais de tirs parfaitement synchronisés.
	_cooldown = _rng.randf_range(0.4, 1.6)
	_timer = _rng.randf_range(0.5, 2.0)


func _physics_process(delta: float) -> void:
	_timer -= delta
	_cooldown -= delta
	_backoff_wait -= delta
	var move := Vector2.ZERO
	match _state:
		State.IDLE:
			move = _wander()
			var seen := _spot()
			if seen:
				_engage(seen)
		State.ENGAGE:
			move = _engage_move()
		State.WINDUP:
			if not _target_valid():
				_set_state(State.ENGAGE, LOST_SIGHT_TIME)
			elif _timer <= 0.0:
				_throw()
				_set_state(State.ENGAGE, LOST_SIGHT_TIME)
		State.BACKOFF:
			move = _backoff_dir * stats.move_speed
			if _timer <= 0.0 or (global_position + move * delta).distance_to(home) > leash_radius:
				_set_state(State.ENGAGE, LOST_SIGHT_TIME)
				move = Vector2.ZERO
		State.RETURN:
			move = global_position.direction_to(home) * stats.move_speed * 1.1
			health.heal(stats.max_health * 0.15 * delta)
			if global_position.distance_to(home) < 8.0:
				_set_state(State.IDLE, _rng.randf_range(0.5, 1.5))
	_move = move
	velocity = move + consume_knockback(delta)
	move_and_slide()
	# Recul gêné par un obstacle : il tient sa position et reprend le combat.
	if _state == State.BACKOFF and get_slide_collision_count() > 0:
		_set_state(State.ENGAGE, LOST_SIGHT_TIME)


func _engage_move() -> Vector2:
	if not _target_valid() or _target.global_position.distance_to(home) > leash_radius + aggro_radius:
		_set_state(State.RETURN)
		return Vector2.ZERO
	var line := Targeting.shot_blocker(self, global_position, _target.global_position) == null
	if line:
		_timer = LOST_SIGHT_TIME
	elif _timer <= 0.0:
		_set_state(State.RETURN)
		return Vector2.ZERO
	var d := edge_distance(_target)
	if d < backoff_trigger and _backoff_wait <= 0.0 and _try_backoff():
		return Vector2.ZERO
	if line and d <= stats.attack_range and _cooldown <= 0.0:
		_set_state(State.WINDUP, stats.attack_windup)
		glow(DANGER, stats.attack_windup + 0.1)
		return Vector2.ZERO
	if d > keep_distance or not line:
		var move := global_position.direction_to(_target.global_position) * stats.move_speed
		# Jamais au-delà des abords de son repaire.
		if (global_position + move * 0.25).distance_to(home) > leash_radius:
			return Vector2.ZERO
		return move
	return Vector2.ZERO


## Recul bref : droit devant lui à l'opposé de la menace, ou un peu de biais ; seulement si la voie est
## libre sur toute la distance et qu'il reste aux abords de son repaire. Sinon, il ne bouge pas.
func _try_backoff() -> bool:
	var away := (global_position - _target.global_position).normalized()
	for angle in [0.0, 0.7, -0.7]:
		var dir := away.rotated(angle)
		var shift := dir * stats.move_speed * backoff_time
		if (global_position + shift).distance_to(home) > leash_radius or test_move(global_transform, shift):
			continue
		_backoff_dir = dir
		_backoff_wait = backoff_cooldown
		_set_state(State.BACKOFF, backoff_time)
		return true
	_backoff_wait = backoff_cooldown * 0.5
	return false


## Pierre vers la position actuelle de la cible (figée au départ), puis délai variable avant la suivante.
func _throw() -> void:
	var aim := _target.global_position
	lunge(global_position.direction_to(aim))
	SlingStone.launch_at(self, aim, stats.damage, &"party_members", stone_speed)
	_cooldown = stats.attack_cooldown + _rng.randf_range(-0.3, 0.4)


## Membre du groupe repéré : à portée de vue, avec une ligne de tir libre, et près du repaire.
func _spot() -> Combatant:
	var seen := Targeting.nearest(self, &"party_members", aggro_radius, false)
	if seen and seen.global_position.distance_to(home) < leash_radius + aggro_radius \
			and Targeting.shot_blocker(self, global_position, seen.global_position) == null:
		return seen
	return null


func _wander() -> Vector2:
	if global_position.distance_to(_goal) > 4.0 and _timer > -3.0:
		return global_position.direction_to(_goal) * stats.move_speed * 0.4
	if _timer <= 0.0:
		_goal = home + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(6.0, WANDER_RADIUS)
		_timer = _rng.randf_range(2.0, 4.0)
	return Vector2.ZERO


func _engage(target: Combatant) -> void:
	_target = target
	_set_state(State.ENGAGE, LOST_SIGHT_TIME)


func _target_valid() -> bool:
	return is_instance_valid(_target) and _target.is_alive()


func _set_state(s: State, time := 0.0) -> void:
	_state = s
	_timer = time


func _on_hit(_from: Vector2) -> void:
	if _state in [State.IDLE, State.RETURN]:
		var attacker := Targeting.nearest(self, &"party_members", 160.0, false)
		if attacker:
			_engage(attacker)


## Le groupe est revenu au camp : on oublie le combat.
func reset_aggro() -> void:
	if is_alive():
		_target = null
		_set_state(State.RETURN)


func _on_died() -> void:
	_set_state(State.DEAD)
	collision_layer = 0
	remove_from_group(&"enemies")
	Loot.drop(stats, global_position, get_parent(), _rng)
	CombatFx.poof(global_position + Vector2(0, -8))
	sprite.rotation_degrees = 90.0
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
	super()


func _animate(delta: float) -> void:
	if _state == State.DEAD:
		return
	var anim := sprite as CharacterSprite
	if _state == State.WINDUP and _target_valid():
		anim.face(_target.global_position - global_position)
		# Préparation : le bras se tend, la silhouette tremble un peu.
		sprite.position.x += 1.0 if int(_timer * 30.0) % 2 else -1.0
	elif _move.length() > CharacterSprite.WALK_THRESHOLD:
		anim.face(_move)
	elif _target_valid():
		anim.face(_target.global_position - global_position)
	anim.animate(_move, ANIM_SPEED, delta)
