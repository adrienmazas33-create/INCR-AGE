class_name SkillSlot
extends Node2D
## Indicateur de la compétence active (lot G2), en bas au centre de l'écran : une petite case avec
## son symbole (une flèche qui fait le tour d'un rond). En recharge, un voile sombre la couvre et se
## retire de bas en haut ; prête, elle brille un instant. La touche est rappelée à côté.

const SIZE := 20.0
const GOLD := Color8(255, 214, 90)
const DIM := Color8(118, 78, 36)
const VEIL := Color(0.05, 0.03, 0.04, 0.7)
## Symbole 12 x 12 : flèche circulaire (« o » or, « d » contour).
const ICON := [
	"....dddd....",
	"..ddoooodd..",
	".dooddddood.",
	".dod....dod.",
	"dod......ddd",
	"dod.....dodd",
	"dod....doood",
	"dod.....ddd.",
	".dod........",
	".dooddd.....",
	"..ddooodd...",
	"....dddd....",
]
const GLINT_TIME := 0.35

var _skill: ActiveSkill
var _frame := UiFrame.new()
## Symbole, voile et éclat, dessinés par-dessus le cadre.
var _face := Node2D.new()
var _key := PixelText.new()
var _glint := 0.0


func setup(skill: ActiveSkill) -> void:
	_skill = skill
	skill.became_ready.connect(func() -> void: _glint = GLINT_TIME)


func _ready() -> void:
	_frame.size = Vector2(SIZE, SIZE)
	_frame.position = Vector2(-SIZE * 0.5, -SIZE * 0.5)
	add_child(_frame)
	_face.draw.connect(_draw_face)
	add_child(_face)
	_key.text = "ESPACE"
	_key.align = 0.0
	_key.position = Vector2(SIZE * 0.5 + 4, 0)
	_key.modulate = Color(1, 1, 1, 0.7)
	add_child(_key)
	_place()
	get_viewport().size_changed.connect(_place)


func _place() -> void:
	var view := get_viewport().get_visible_rect().size
	position = Vector2(roundf(view.x * 0.5), view.y - 16)


func _process(delta: float) -> void:
	_glint = maxf(_glint - delta, 0.0)
	_face.queue_redraw()


func _draw_face() -> void:
	if _skill == null:
		return
	var ready := _skill.is_ready()
	var top := Vector2(-6, -6)
	for y in ICON.size():
		var row: String = ICON[y]
		for x in row.length():
			if row[x] == ".":
				continue
			var c := GOLD if row[x] == "o" else DIM
			if not ready:
				c = c.darkened(0.45)
			_face.draw_rect(Rect2(top + Vector2(x, y), Vector2.ONE), c)
	# Voile de recharge : couvre la case et se retire de bas en haut.
	if not ready:
		var inner := SIZE - 4.0
		var h := roundf(inner * (1.0 - _skill.charge()))
		_face.draw_rect(Rect2(-inner * 0.5, -inner * 0.5, inner, h), VEIL)
	if _glint > 0.0:
		var a := _glint / GLINT_TIME
		_face.draw_rect(Rect2(-SIZE * 0.5, -SIZE * 0.5, SIZE, SIZE), Color(1, 0.95, 0.75, 0.45 * a), false, 1.0)
		_face.draw_rect(Rect2(-SIZE * 0.5 - 1, -SIZE * 0.5 - 1, SIZE + 2, SIZE + 2), Color(GOLD, 0.8 * a), false, 1.0)
