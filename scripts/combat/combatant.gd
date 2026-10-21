class_name Combatant
extends CharacterBody2D
## Base commune des unités qui combattent : vie, recul, flash blanc d'impact, petit élan du geste,
## barre de vie. Les sous-classes gèrent déplacement et animation (_animate).
## Les futures compétences actives du héros passeront aussi par receive_hit().

signal knocked_out

const FLASH_SHADER := preload("res://assets/shaders/flash.gdshader")
const FLASH_TIME := 0.12
const LUNGE_PIXELS := 2.0

@export var stats: UnitStats
## Hauteur de la barre de vie au-dessus des pieds.
@export var bar_height := 30.0

var health := Health.new()

@onready var sprite: Sprite2D = $Sprite

var _knock := Vector2.ZERO
var _flash := 0.0
var _lunge := Vector2.ZERO
var _sprite_rest := Vector2.ZERO


func _ready() -> void:
	health.setup(stats.max_health, stats.regen_per_second)
	health.died.connect(_on_died)
	add_child(health)
	var mat := ShaderMaterial.new()
	mat.shader = FLASH_SHADER
	sprite.material = mat
	_sprite_rest = sprite.position
	var bar := HealthBar.new()
	bar.health = health
	bar.position = Vector2(0, -bar_height)
	bar.color = HealthBar.ENEMY_COLOR if is_in_group("enemies") else (HealthBar.HERO_COLOR if is_in_group("hero") else HealthBar.PARTY_COLOR)
	add_child(bar)


func is_alive() -> bool:
	return not health.is_dead()


## Distance de bord à bord avec une autre unité.
func edge_distance(other: Combatant) -> float:
	return global_position.distance_to(other.global_position) - stats.body_radius - other.stats.body_radius


func receive_hit(amount: float, from: Vector2, knockback: float) -> void:
	if not is_alive():
		return
	health.take_damage(amount)
	var dir := global_position - from
	dir = dir.normalized() if dir.length() > 0.1 else Vector2.RIGHT
	_knock = dir * knockback * stats.knockback_taken
	_flash = FLASH_TIME
	CombatFx.damage_number(global_position + Vector2(0, -bar_height + 2), amount, is_in_group("party_members"))
	_on_hit(from)


## Petit élan du corps vers la cible au moment du coup.
func lunge(dir: Vector2) -> void:
	_lunge = dir * LUNGE_PIXELS


## Recul à ajouter à la vitesse ce tour-ci ; il s'amortit très vite.
func consume_knockback(delta: float) -> Vector2:
	var k := _knock
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)
	return k


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	(sprite.material as ShaderMaterial).set_shader_parameter("flash", 1.0 if _flash > 0.0 else 0.0)
	_lunge = _lunge.move_toward(Vector2.ZERO, 30.0 * delta)
	sprite.position = _sprite_rest + _lunge.round()
	_animate(delta)


## Animation propre à l'unité (appelée chaque image).
func _animate(_delta: float) -> void:
	pass


## Réaction à un coup reçu (cible, fuite...).
func _on_hit(_from: Vector2) -> void:
	pass


func _on_died() -> void:
	knocked_out.emit()
