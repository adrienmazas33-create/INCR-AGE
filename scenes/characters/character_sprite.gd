class_name CharacterSprite
extends Sprite2D
## Animation commune aux personnages (planche 6 x 3 du générateur) : repos ou marche,
## orientation face / dos / profil (retourné pour la gauche).

enum Facing { DOWN, UP, SIDE }

const IDLE_FRAMES := [0, 1]
const WALK_FRAMES := [2, 3, 4, 5]
const IDLE_FPS := 2.0
const WALK_FPS := 9.0
## Vitesse sous laquelle le personnage est considéré à l'arrêt.
const WALK_THRESHOLD := 12.0

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
	var frames: Array = WALK_FRAMES if walking else IDLE_FRAMES
	_anim_time += delta * (WALK_FPS * clampf(velocity.length() / reference_speed, 0.6, 1.2) if walking else IDLE_FPS)
	frame = facing * hframes + frames[int(_anim_time) % frames.size()]


## Décale le cycle de repos pour que les membres d'un groupe ne respirent pas en même temps.
func offset_phase(seconds: float) -> void:
	_anim_time = seconds
