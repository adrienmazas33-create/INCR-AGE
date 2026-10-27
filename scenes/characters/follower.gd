class_name Follower
extends Combatant
## Allié qui accompagne le héros. Le groupe (Party) lui indique où aller et quel ennemi combattre :
## seulement ceux qui menacent le héros de près, jamais une poursuite au loin.
## Mis K.O., il reste à terre quelques secondes puis se relève (aucune perte définitive).
## Deux rôles : combattant à la lance (mêlée) ou frondeur (tir à distance, plus fragile). Le frondeur
## s'arrête dès qu'il a sa cible à portée et en vue, et tire sans avancer au contact.

const ROLE_STATS := {
	"spear": preload("res://data/units/ally.tres"),
	"sling": preload("res://data/units/slinger.tres"),
}

@export var acceleration := 1100.0
## Distance sous laquelle l'allié ralentit à l'approche de sa place.
@export var arrive_radius := 18.0

## Vitesse de référence de l'animation de marche (celle du héros).
const ANIM_SPEED := 100.0
const KO_DURATION := 8.0
const REVIVE_HEALTH := 0.5
## Retard sur sa place (le long de la trace) au-delà duquel il accélère, et facteur de vitesse.
const SPRINT_LAG := 20.0
const SPRINT := 1.25

var party: Party
var index := 0
var role := GameState.DEFAULT_ROLE
## Attaque du rôle (mêlée ou fronde), créée par assign_role ou, à défaut, à l'entrée en jeu.
var attack: AutoAttack

var _move := Vector2.ZERO
var _foe: Combatant
## Temps passé à forcer sans avancer (le groupe le recentre sur la trace, puis le replace si besoin).
var stuck_time := 0.0
## Retard sur sa place le long de la trace (renseigné par le groupe).
var trail_lag := 0.0
var _ko_time := 0.0


func _ready() -> void:
	super()
	if attack == null:
		attack = AutoAttack.new()
	attack.unit = self
	add_child(attack)
	_anim().offset_phase(index * 0.37)


func _physics_process(delta: float) -> void:
	if not is_alive():
		_ko_time -= delta
		if _ko_time <= 0.0:
			_revive(REVIVE_HEALTH)
		velocity = consume_knockback(delta)
		move_and_slide()
		return
	var previous_foe := _foe
	_foe = party.foe_for(self, _foe)
	if previous_foe and _foe == null:
		party.rejoin_trail(self)
	var goal := party.combat_spot(self, _foe) if _foe else party.target_for(self)
	# Frondeur : cible à portée et en vue, il reste où il est pour tirer.
	if _foe and is_ranged() and attack.in_range(_foe) and Targeting.has_sight(self, global_position, _foe.global_position):
		goal = global_position
	var to := goal - global_position
	var dist := to.length()
	var desired := Vector2.ZERO
	if dist > 2.0:
		# En retard sur sa place : il trottine franchement ; sinon arrivée douce.
		var speed := stats.move_speed * SPRINT if trail_lag > SPRINT_LAG and not _foe else stats.move_speed * clampf(dist / arrive_radius, 0.0, 1.0)
		desired = to / dist * speed
	desired += party.separation(self)
	_move = _move.move_toward(desired, acceleration * delta)
	velocity = _move + consume_knockback(delta)
	var before := global_position
	move_and_slide()
	if _foe:
		attack.try_attack(_foe)
	# Coincé : il veut avancer franchement mais ne progresse presque pas.
	if desired.length() > 40.0 and global_position.distance_to(before) < desired.length() * delta * 0.25:
		stuck_time += delta
	else:
		stuck_time = maxf(stuck_time - delta * 2.0, 0.0)
	if party.should_regroup(self, stuck_time):
		party.regroup(self)


func _animate(delta: float) -> void:
	if not is_alive():
		return
	if _foe and (attack.is_swinging() or _move.length() < CharacterSprite.WALK_THRESHOLD):
		_anim().face(_foe.global_position - global_position)
	elif _move.length() > CharacterSprite.WALK_THRESHOLD:
		_anim().face(_move)
	elif party.hero_idle:
		_anim().face(party.hero.global_position - global_position)
	_anim().animate(_move, ANIM_SPEED, delta)


func _on_hit(_from: Vector2) -> void:
	CombatFx.party_hit(global_position + Vector2(0, -10), false)


func _on_died() -> void:
	remove_from_group(&"party_members")
	_ko_time = KO_DURATION
	_move = Vector2.ZERO
	_foe = null
	sprite.rotation_degrees = 90.0
	sprite.modulate = Color(0.7, 0.66, 0.66)
	super()


## Relève (après un K.O., ou au retour au camp).
func _revive(fraction: float) -> void:
	health.restore(fraction)
	sprite.rotation_degrees = 0.0
	sprite.modulate = Color.WHITE
	add_to_group(&"party_members")
	party.rejoin_trail(self)


func revive_full() -> void:
	_revive(1.0)


func is_ranged() -> bool:
	return role == "sling"


## Rôle donné avant l'entrée en jeu (création par le groupe) : caractéristiques et attaque.
func assign_role(new_role: String) -> void:
	role = new_role
	stats = ROLE_STATS[role]
	attack = RangedAttack.new() if is_ranged() else AutoAttack.new()


## Réaffectation au camp, en jeu : nouvelles caractéristiques et nouvelle attaque, apparence changée.
## La vie garde sa proportion (vie maximale du nouveau rôle, améliorations comprises) et un allié
## à terre le reste : la conversion ne soigne pas et ne relève pas.
func convert_role(new_role: String, skin: Texture2D) -> void:
	if new_role == role:
		return
	attack.queue_free()
	assign_role(new_role)
	attack.unit = self
	add_child(attack)
	health.regen_per_second = stats.regen_per_second
	health.set_maximum(_max_health())
	sprite.texture = skin
	_foe = null


## Replace l'allié sans transition (appelé par le groupe).
func teleport(to: Vector2) -> void:
	global_position = to
	_move = Vector2.ZERO
	stuck_time = 0.0
	reset_physics_interpolation()


func _anim() -> CharacterSprite:
	return sprite as CharacterSprite
