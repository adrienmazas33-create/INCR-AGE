class_name CharacterSprite
extends Sprite2D
## Animation commune aux personnages : repos ou marche, orientation face / dos / profil (retourné pour
## la gauche), une rangée par orientation. Par défaut, la planche 6 x 3 du générateur ; une autre
## planche (héros PixelLab) règle ses propres images et cadences.

enum Facing { DOWN, UP, SIDE }

## Vitesse sous laquelle le personnage est considéré à l'arrêt.
const WALK_THRESHOLD := 12.0
## Balancement de marche calculé : montée au milieu de chaque pas, et léger report d'un côté puis de
## l'autre (en pixels entiers : le dessin reste net, sans rotation).
const SWAY_BOB := 2.0
const SWAY_SIDE := 1.0

var idle_frames: Array[int] = [0, 1]
var walk_frames: Array[int] = [2, 3, 4, 5]
var idle_fps := 2.0
## Images par seconde de la marche ; avec walk_sway, pas par seconde.
var walk_fps := 9.0
## Planche de poses fixes, sans images de marche (soldat PixelLab) : la marche est un balancement
## calculé. Le parent remet la position du sprite à zéro à chaque image (Combatant).
var walk_sway := false

var facing := Facing.DOWN
var _anim_time := 0.0
var _walking := false


## Oriente le personnage vers `dir`. Diagonales : le profil l'emporte, il lit mieux la marche.
func face(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	if absf(dir.x) >= absf(dir.y) * 0.7:
		facing = Facing.SIDE
		flip_h = dir.x < 0.0
	else:
		facing = Facing.DOWN if dir.y > 0.0 else Facing.UP


## Avance l'animation ; la cadence de marche suit la vitesse réelle (pas de patinage).
func animate(velocity: Vector2, reference_speed: float, delta: float) -> void:
	var walking := velocity.length() > WALK_THRESHOLD
	if walking != _walking:
		_walking = walking
		_anim_time = 0.0
	var frames: Array[int] = walk_frames if walking else idle_frames
	_anim_time += delta * (walk_fps * clampf(velocity.length() / reference_speed, 0.6, 1.2) if walking else idle_fps)
	frame = facing * hframes + frames[int(_anim_time) % frames.size()]
	if walk_sway and walking:
		var s := sin(PI * _anim_time)
		position += Vector2(roundf(s * SWAY_SIDE), -roundf(absf(s) * SWAY_BOB))


## Décale le cycle de repos pour que les membres d'un groupe ne respirent pas en même temps.
func offset_phase(seconds: float) -> void:
	_anim_time = seconds
