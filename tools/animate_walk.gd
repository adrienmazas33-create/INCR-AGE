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
## De profil (mode « profile »), les deux jambes se superposent : la jambe proche sert de modèle et est
## dessinée deux fois. La jambe éloignée est la même, assombrie avec les teintes du sprite, derrière.
## Chaque jambe s'incline par un décalage progressif de ses rangées, de la hanche (0) au pied
## (pixels entiers, marches d'un pixel, sans rotation) ; une jambe levée perd des rangées de tibia.
## La main avance et recule d'un pixel, en opposition avec la jambe proche.
## Prototype : soldat de base, marche vers le bas puis de profil. Les réglages de chaque personnage et
## direction sont dans WALKS ; validés, ils serviront aux autres directions puis aux autres unités.
## Usage : godot --headless --path . --script res://tools/animate_walk.gd -- [<nom>] ; puis --import.
## La planche du jeu reprend tous les cycles déjà fabriqués du personnage (assets/art/<unité>_walk_<dir>.png).

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
	# Profil, regard vers la droite (la gauche est le miroir, dans le jeu).
	# Image : [montée du corps, inclinaison de la jambe proche, rangées de tibia retirées (jambe levée),
	# inclinaison de la jambe éloignée, rangées retirées, décalage de la main]. Inclinaison : décalage
	# du pied en pixels, + vers l'avant.
	"soldier_east": {
		"unit": "soldier", "pose": "east", "out": "res://assets/art/soldier_walk_east.png", "mode": "profile",
		"sheet": "res://assets/art/soldier_pixellab_walk.png", "rows": ["south", "north", "east"],
		# Jambe proche : rangées 38 à 46, colonnes 18 à 24 (18 à 26 pour le pied, dès la rangée 44 ; au-delà,
		# la jambe éloignée de la pose) ; tibia en 41-42. Tout ce qui est sous la
		# rangée 38 (les deux jambes de la pose) est redessiné.
		"hip": 38, "shin": [41, 42], "sole": 46, "leg": [18, 24], "foot_from": 44, "foot": [18, 26],
		# Main et avant-bras, le long du torse.
		"hand": [30, 36], "hand_cols": [15, 20],
		"frames": [
			# Contact : jambe proche en avant, éloignée en arrière ; main en arrière.
			[0, 5, 0, -5, 0, -1],
			# Passage : jambe proche en appui, éloignée levée ; corps haut.
			[-1, 0, 0, 1, 2, 0],
			# Contact inverse : main en avant.
			[0, -5, 0, 5, 0, 1],
			# Passage inverse.
			[-1, 1, 2, 0, 0, 0],
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
		var img := _profile_frame(pose, walk, frames[k]) if walk.get("mode", "") == "profile" else _frame(pose, walk, frames[k])
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, size), Vector2i(k * size.x, 0))
	sheet.save_png(walk["out"])
	var rows: Array = walk["rows"]
	var game := Image.create(size.x * (1 + frames.size()), size.y * rows.size(), false, Image.FORMAT_RGBA8)
	for r in rows.size():
		var row_pose := Image.load_from_file(SOURCES + "%s/rotations/%s.png" % [walk["unit"], rows[r]])
		row_pose.convert(Image.FORMAT_RGBA8)
		var cycle_path := "res://assets/art/%s_walk_%s.png" % [walk["unit"], rows[r]]
		var cycle: Image = sheet if rows[r] == walk["pose"] else (Image.load_from_file(cycle_path) if FileAccess.file_exists(cycle_path) else null)
		for k in 1 + frames.size():
			var src: Image = cycle if cycle and k > 0 else row_pose
			var at := Vector2i((k - 1) * size.x, 0) if src == cycle else Vector2i.ZERO
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


## Image de profil : jambe éloignée (assombrie), corps, jambe proche, main.
func _profile_frame(pose: Image, walk: Dictionary, f: Array) -> Image:
	var size := pose.get_size()
	var out := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var body_dy: int = f[0]
	var darker := _darker_map(pose, walk)
	_profile_leg(out, pose, walk, body_dy, f[3], f[4], darker)
	var hand: Array = walk["hand"]
	var hand_cols: Array = walk["hand_cols"]
	for y in range(walk["hip"]):
		for x in size.x:
			var c := pose.get_pixel(x, y)
			var in_hand: bool = y >= hand[0] and y <= hand[1] and _between(x, hand_cols)
			if c.a == 0.0 or in_hand:
				continue
			_put(out, x, y + body_dy, c)
	_profile_leg(out, pose, walk, body_dy, f[1], f[2], {})
	# Main : décalée horizontalement ; un trou laissé contre le torse reprend la couleur voisine.
	var dx: int = f[5]
	for y in range(hand[0], hand[1] + 1):
		for x in range(hand_cols[0], hand_cols[1] + 1):
			var c := pose.get_pixel(x, y)
			if c.a == 0.0:
				continue
			_put(out, x + dx, y + body_dy, c)
		if dx < 0:
			var edge := pose.get_pixel(hand_cols[1] + 1, y)
			if edge.a > 0.0:
				_put(out, hand_cols[1], y + body_dy, edge)
	return out


## Jambe de profil : la hanche suit le corps ; chaque rangée glisse vers le pied de `tilt` pixels au plus
## (+ en avant) ; `lift` rangées de tibia retirées pour une jambe levée, une ajoutée si le corps monte.
func _profile_leg(out: Image, pose: Image, walk: Dictionary, body_dy: int, tilt: int, lift: int, recolor: Dictionary) -> void:
	var shin: Array = walk["shin"]
	var stretch := -lift - body_dy
	var rows: Array[int] = []
	for y in range(walk["hip"], walk["sole"] + 1):
		if y in shin and stretch < 0 and -stretch > shin.find(y):
			continue
		rows.append(y)
		if y == shin[shin.size() - 1]:
			for i in maxi(stretch, 0):
				rows.append(y)
	var top: int = walk["hip"] + body_dy
	for i in rows.size():
		var shift := roundi(float(tilt) * i / maxf(rows.size() - 1, 1))
		var cols := _leg_cols(walk, rows[i])
		for x in range(cols[0], cols[1] + 1):
			var c := pose.get_pixel(x, rows[i])
			if c.a == 0.0:
				continue
			_put(out, x + shift, top + i, recolor.get(c.to_html(false), c))


## Colonnes de la jambe modèle à la rangée `y` (le pied dépasse vers l'avant).
func _leg_cols(walk: Dictionary, y: int) -> Array:
	return walk["foot"] if y >= walk.get("foot_from", 999) else walk["leg"]


## Teintes de la jambe éloignée : chaque couleur claire de la jambe devient la teinte immédiatement plus
## sombre de la jambe elle-même ; les contours (très sombres) restent tels quels.
func _darker_map(pose: Image, walk: Dictionary) -> Dictionary:
	var tones := {}
	for y in range(walk["hip"], walk["sole"] + 1):
		var cols := _leg_cols(walk, y)
		for x in range(cols[0], cols[1] + 1):
			var c := pose.get_pixel(x, y)
			if c.a > 0.0 and c.get_luminance() > 0.15:
				tones[c.to_html(false)] = c
	var sorted: Array = tones.values()
	sorted.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
	var map := {}
	for i in range(1, sorted.size()):
		map[(sorted[i] as Color).to_html(false)] = sorted[i - 1]
	return map


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
