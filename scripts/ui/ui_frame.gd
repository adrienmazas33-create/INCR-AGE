class_name UiFrame
extends Control
## Cadre commun de l'interface (direction artistique, passe 1) : cuir tendu dans un cadre de bois
## biseauté, coins cloutés, bandeau de titre optionnel plus sombre. Utilisable comme nœud (UiFrame)
## ou depuis le _draw() d'un autre contrôle (UiFrame.paint()).

const OUTER := Color8(22, 14, 12)
const WOOD := Color8(120, 80, 48)
const WOOD_LIGHT := Color8(168, 120, 72)
const WOOD_DARK := Color8(76, 48, 28)
const LEATHER := Color8(54, 37, 29, 238)
const LEATHER_DARK := Color8(38, 26, 21, 245)
const STUD := Color8(222, 206, 172)
## Épaisseur totale du cadre (contour, bois, liseré).
const BORDER := 4.0

## Hauteur du bandeau de titre (0 = aucun).
@export var header_height := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	paint(self, Rect2(Vector2.ZERO, size), header_height)


static func paint(ci: CanvasItem, r: Rect2, header := 0.0) -> void:
	ci.draw_rect(r, OUTER)
	var wood := r.grow(-1)
	ci.draw_rect(wood, WOOD)
	ci.draw_rect(Rect2(wood.position, Vector2(wood.size.x, 1)), WOOD_LIGHT)
	ci.draw_rect(Rect2(wood.position, Vector2(1, wood.size.y)), WOOD_LIGHT)
	ci.draw_rect(Rect2(wood.position + Vector2(0, wood.size.y - 1), Vector2(wood.size.x, 1)), WOOD_DARK)
	ci.draw_rect(Rect2(wood.position + Vector2(wood.size.x - 1, 0), Vector2(1, wood.size.y)), WOOD_DARK)
	var inner := r.grow(-BORDER)
	ci.draw_rect(inner.grow(1), OUTER)
	ci.draw_rect(inner, LEATHER)
	if header > 0.0:
		ci.draw_rect(Rect2(inner.position, Vector2(inner.size.x, header)), LEATHER_DARK)
		ci.draw_rect(Rect2(inner.position + Vector2(0, header), Vector2(inner.size.x, 1)), WOOD_DARK)
	# Clous aux quatre coins, avec leur petite ombre.
	for c in [r.position + Vector2(1, 1), Vector2(r.end.x - 3, r.position.y + 1),
			Vector2(r.position.x + 1, r.end.y - 3), r.end - Vector2(3, 3)]:
		ci.draw_rect(Rect2(c, Vector2(2, 2)), STUD)
		ci.draw_rect(Rect2(c + Vector2(1, 1), Vector2(1, 1)), WOOD_DARK)
