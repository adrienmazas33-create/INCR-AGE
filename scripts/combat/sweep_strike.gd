class_name SweepStrike
extends ActiveSkill
## FRAPPE CIRCULAIRE (lot G2) : le héros tourne sur lui-même et balaie tout ce qui l'entoure d'un coup
## de massue. Chaque ennemi à portée (environ une case autour de lui) est frappé, repoussé et
## interrompu : un sanglier qui prépare ou mène sa charge est étourdi, un lanceur qui arme son tir le
## perd. Aucune visée ; la portée courte oblige le héros à s'approcher, donc à prendre un risque.
## Pensée pour se dégager ou briser une attaque, pas pour abattre seule un champion.

## Portée : distance entre les bords des corps.
const RADIUS := 26.0
## Dégâts : multiple du coup du héros (amélioration FORCE comprise).
const DAMAGE_FACTOR := 2.5
const KNOCKBACK := 300.0
## Étourdissement d'un ennemi interrompu.
const STAGGER := 0.9
## Tour sur lui-même : durée et ordre des orientations (droite, face, gauche, dos).
const SPIN_TIME := 0.24
const SPIN_DIRS: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

## Ennemis touchés en tout, et abattus (statistiques de contrôle).
static var hits := 0
static var kills := 0

var _spin := -1.0


func _init() -> void:
	display_name = "FRAPPE CIRCULAIRE"
	cooldown = Upgrades.SKILL_COOLDOWN


## Recharge raccourcie par l'amélioration FRAPPE (lot G4), dès le lancement puis à chaque achat.
func _ready() -> void:
	cooldown = Upgrades.skill_cooldown()
	GameState.upgrade_bought.connect(func(id: String, _level: int) -> void:
		if id == "skill":
			cooldown = Upgrades.skill_cooldown()
			remaining = minf(remaining, cooldown))


func _activate() -> void:
	var anim := unit.sprite as CharacterSprite
	_spin = 0.0
	unit.glow(CombatFx.HERO_TINT, 0.3)
	CombatFx.sweep(unit.global_position + Vector2(0, -6), RADIUS + unit.stats.body_radius + 6.0)
	AudioManager.play(&"sweep", unit.global_position)
	var damage := unit.stats.damage * Upgrades.damage_multiplier() * DAMAGE_FACTOR
	var struck := 0
	for node in unit.get_tree().get_nodes_in_group(&"enemies"):
		var foe := node as Combatant
		if foe == null or not foe.is_alive() or unit.edge_distance(foe) > RADIUS:
			continue
		foe.receive_hit(damage, unit.global_position, KNOCKBACK)
		foe.stagger(STAGGER)
		struck += 1
		hits += 1
		if not foe.is_alive():
			kills += 1
		CombatFx.impact(foe.global_position + Vector2(0, -8), true, false)
	# Un seul temps fort, quel que soit le nombre d'ennemis : la frappe pèse sans saccader.
	if struck > 0:
		CombatFx.hit_stop(0.06)
	CombatFx.shake(2.5 if struck > 0 else 1.0)
	if anim:
		anim.face(SPIN_DIRS[0])


func _process(delta: float) -> void:
	super(delta)
	if _spin < 0.0:
		return
	_spin += delta
	var anim := unit.sprite as CharacterSprite
	if _spin >= SPIN_TIME:
		_spin = -1.0
		return
	if anim:
		anim.face(SPIN_DIRS[mini(int(_spin / SPIN_TIME * SPIN_DIRS.size()), SPIN_DIRS.size() - 1)])
