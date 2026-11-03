extends SceneTree
## Cycle de marche fabriqué à partir d'une pose fixe, par découpage des membres en pixels entiers
## (méthode « cut-out ») : aucune rotation, aucun ré-échantillonnage ; chaque pixel affiché vient de la
## pose d'origine, qui n'est pas modifiée.
## - Jambes : découpées sous le pagne. Leur longueur change en retirant ou en dupliquant des rangées du
##   tibia (genou plié, jambe tendue) ; cuisse, pied et contours restent intacts. Une jambe levée se
##   rapproche du centre d'un pixel (le pas croisé).
## - Avant-bras : décalés d'un pixel en opposition avec les jambes (le bras qui avance descend vers la
##   caméra) ; un décalage vers le bas prolonge le haut de l'avant-bras pour ne pas laisser de trou.
## - Corps (tête, torse, pagne, haut des bras) : monte d'un pixel quand une jambe passe.
## Prototype : soldat de base, marche vers le bas. Les réglages de chaque personnage et direction sont
## dans WALKS ; validés, ils serviront aux autres directions puis aux autres unités.
## Usage : godot --headless --path . --script res://tools/animate_walk.gd -- [<nom>] ; puis --import.

const SOURCES := "res://assets/source/pixellab/"

## Découpage de la pose (rangées et colonnes de la toile de 48 px, bornes incluses) et cycle.
## Chaque image du cycle : [montée du corps, pied gauche, pied droit, avant-bras gauche, avant-bras droit,
## décalage horizontal de la jambe gauche, de la jambe droite]. Pied : + plus bas (il avance vers la
## caméra), - levé. Avant-bras : + plus bas (il avance), - plus haut (il recule).
const WALKS := {
	"soldier_south": {
		"unit": "soldier", "pose": "south", "out": "res://assets/art/soldier_walk_south.png",
		# Planche du jeu : rangées face, dos, profil (CharacterSprite) ; colonne 0 la pose, puis le cycle.
		# Les directions sans cycle répètent leur pose (le jeu les balance, comme avant).
		"sheet": "res://assets/art/soldier_pixellab_walk.png", "rows": ["south", "north", "east"],
		# Jambes : de la rangée 38 (sous le pagne) aux pieds ; tibia extensible en 40-41.
		"hip": 38, "shin": [40, 41], "sole": 45,
		"left_leg": [12, 20], "right_leg": [25, 34],
		# Avant-bras, détachés du torse à partir de la rangée 31.
		"forearm": [31, 37], "left_arm": [8, 14], "right_arm": [32, 39],
		"frames": [
			# Contact : pied gauche en avant, droit en arrière ; bras droit en avant.
			[0, 1, -1, -1, 1, 0, 0],
			# Passage : pied droit levé et croisé, corps haut.
			[-1, 0, -3, 0, 0, 0, -1],
			# Contact inverse.
			[0, -1, 1, 1, -1, 0, 0],
			# Passage inverse.
			[-1, -3, 0, 0, 0, 1, 0],
		],
	},
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var key: String = args[0] if args.size() > 0 else "soldier_south"
	var walk: Dictionary = WALKS[key]
	var pose := Image.load_from_file(SOURCES + "%s/rotations/%s.png" % [walk["unit"], walk["pose"]])
	pose.convert(Image.FORMAT_RGBA8)
	var size := pose.get_size()
	var frames: Array = walk["frames"]
	var sheet := Image.create(size.x * frames.size(), size.y, false, Image.FORMAT_RGBA8)
	for k in frames.size():
		var img := _frame(pose, walk, frames[k])
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, size), Vector2i(k * size.x, 0))
	sheet.save_png(walk["out"])
	var rows: Array = walk["rows"]
	var game := Image.create(size.x * (1 + frames.size()), size.y * rows.size(), false, Image.FORMAT_RGBA8)
	for r in rows.size():
		var row_pose := Image.load_from_file(SOURCES + "%s/rotations/%s.png" % [walk["unit"], rows[r]])
		row_pose.convert(Image.FORMAT_RGBA8)
		for k in 1 + frames.size():
			var src := sheet if rows[r] == walk["pose"] and k > 0 else row_pose
			var at := Vector2i((k - 1) * size.x, 0) if src == sheet else Vector2i.ZERO
			game.blit_rect(src, Rect2i(at, size), Vector2i(k * size.x, r * size.y))
	game.save_png(walk["sheet"])
	print("animate_walk : %s -> %s, %d images de %d x %d ; planche du jeu %s" % [key, walk["out"], frames.size(), size.x,
		size.y, walk["sheet"]])
	quit()


## Une image du cycle : jambes d'abord (le pagne passe devant), puis le corps, puis les avant-bras.
func _frame(pose: Image, walk: Dictionary, f: Array) -> Image:
	var size := pose.get_size()
	var out := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var body_dy: int = f[0]
	_leg(out, pose, walk, walk["left_leg"], body_dy, f[1], f[5])
	_leg(out, pose, walk, walk["right_leg"], body_dy, f[2], f[6])
	# Corps : tout sauf les jambes et les avant-bras.
	for y in size.y:
		for x in size.x:
			var c := pose.get_pixel(x, y)
			if c.a == 0.0 or _in_leg(walk, x, y) or _in_forearm(walk, x, y):
				continue
			_put(out, x, y + body_dy, c)
	_forearm(out, pose, walk, walk["left_arm"], body_dy + f[3])
	_forearm(out, pose, walk, walk["right_arm"], body_dy + f[4])
	return out


## Jambe : la hanche suit le corps, le pied va à sa hauteur ; le tibia absorbe la différence.
func _leg(out: Image, pose: Image, walk: Dictionary, cols: Array, body_dy: int, foot_dy: int, dx: int) -> void:
	var rows: Array[int] = []
	var shin: Array = walk["shin"]
	var stretch := foot_dy - body_dy
	for y in range(walk["hip"], walk["sole"] + 1):
		if y in shin and stretch < 0 and -stretch > shin.find(y):
			continue
		rows.append(y)
		if y == shin[shin.size() - 1]:
			for i in maxi(stretch, 0):
				rows.append(y)
	var top: int = walk["hip"] + body_dy
	for i in rows.size():
		for x in range(cols[0], cols[1] + 1):
			var c := pose.get_pixel(x, rows[i])
			if c.a > 0.0:
				_put(out, x + dx, top + i, c)


## Avant-bras décalé de `dy` ; vers le bas, sa première rangée est répétée pour rejoindre le haut du bras.
func _forearm(out: Image, pose: Image, walk: Dictionary, cols: Array, dy: int) -> void:
	var rows: Array = walk["forearm"]
	for y in range(rows[0], rows[1] + 1):
		for x in range(cols[0], cols[1] + 1):
			var c := pose.get_pixel(x, y)
			if c.a == 0.0:
				continue
			_put(out, x, y + dy, c)
			if y == rows[0]:
				for fill in range(rows[0], rows[0] + dy):
					_put(out, x, fill, c)


func _in_leg(walk: Dictionary, x: int, y: int) -> bool:
	if y < walk["hip"]:
		return false
	return _between(x, walk["left_leg"]) or _between(x, walk["right_leg"])


func _in_forearm(walk: Dictionary, x: int, y: int) -> bool:
	var rows: Array = walk["forearm"]
	if y < rows[0] or y > rows[1]:
		return false
	return _between(x, walk["left_arm"]) or _between(x, walk["right_arm"])


func _between(v: int, range_: Array) -> bool:
	return v >= range_[0] and v <= range_[1]


func _put(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)
