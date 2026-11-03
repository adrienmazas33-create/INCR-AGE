extends SceneTree
## Marche du soldat obtenue à partir de la vraie marche PixelLab du héros (déjà intégrée), sans rien
## générer : on garde le mouvement du héros (jambes, balancement des bras, rythme des pas) et on lui rend
## l'apparence du soldat, image par image. Les sources ne sont pas modifiées.
## 1. Jambes du héros, chaque couleur ramenée à la plus proche de la palette du soldat.
## 2. Tête, torse et bras : ceux de la pose du soldat, recalés à chaque image sur le mouvement du héros
##    (décalage mesuré en comparant chaque partie à la pose fixe du héros) : ni bandeau, ni tunique,
##    ni protège-poignets, mains vides.
## 3. Massue : tout ce qui dépasse sous le bras qui la tenait disparaît ; là où son manche croise la
##    jambe, cette jambe est refaite avec l'autre jambe de l'image opposée du cycle, en miroir.
## Case de 48 x 52 : la marche du héros, avec le rebond du pas, dépasse 48 px de haut ; les poses fixes
## y sont posées 2 px plus bas, si bien que les pieds restent à la même place dans le jeu.
## Usage : godot --headless --path . --script res://tools/transfer_walk.gd -- [south] ; puis --import.

const SOURCES := "res://assets/source/pixellab/"
const OUT := "res://assets/art/soldier_walk_from_hero_%s.png"
## Planche du jeu : rangées face, dos, profil (CharacterSprite) ; colonne 0 la pose du soldat, puis le
## cycle transféré ; une direction pas encore transférée répète sa pose (le jeu la balance).
const SHEET := "res://assets/art/soldier_pixellab_transfer.png"
const ROWS := ["south", "north", "east"]
const W := 48
const H := 52
## Les poses fixes (48 x 48) sont posées à cette hauteur dans la case ; la case est découpée dans les
## images de marche (68 x 68, pose centrée par PixelLab) à partir de ce point.
const PAD := 2
const CROP := Vector2i(10, 10 - PAD)

## Réglages par direction (rangées et colonnes de la case de 48 x 52, bornes incluses).
const SETTINGS := {
	"south": {
		# Tête (cheveux, visage, cou) ; torse et pagne, entre les bras ; bras, à gauche et à droite.
		"head": [2, 21], "torso": [22, 39], "torso_cols": [15, 31],
		"arms": [22, 39], "left_arm": [6, 14], "right_arm": [32, 41],
		# Sous la rangée 40, tout ce qui est à gauche de la colonne 12 (la massue) disparaît.
		"below_club": [40, 12],
		# Le manche de la massue croise la jambe gauche (à l'écran) sur certaines images. Cette jambe est
		# refaite avec la jambe droite de l'image opposée du cycle (k + 4), jamais masquée, retournée en
		# miroir autour de l'axe du corps de chaque image : de la rangée 38 (sous la main, où passe le manche)
		# aux pieds, jusqu'à la colonne 22.
		"mirror_leg": [38, 22],
	},
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0] if args.size() > 0 else "south"
	var s: Dictionary = SETTINGS[dir]
	var hero_pose := _pose("hero", dir)
	var soldier := _pose("soldier", dir)
	var palette := _palette(soldier)
	var frames := _walk_frames(dir)
	var report: Array[String] = []
	var images: Array[Image] = []
	var centers: Array[int] = []
	for k in frames.size():
		var frame := _load(frames[k]).get_region(Rect2i(CROP, Vector2i(W, H)))
		var head_off := _match(frame, hero_pose, s["head"], [0, W - 1])
		var torso_off := _match(frame, hero_pose, s["torso"], s["torso_cols"])
		var arms_off := [_match(frame, hero_pose, s["arms"], s["left_arm"]), _match(frame, hero_pose, s["arms"], s["right_arm"])]
		report.append("%d: tête %s torse %s bras %s %s" % [k, head_off, torso_off, arms_off[0], arms_off[1]])
		images.append(_transfer(frame, soldier, palette, s, head_off, torso_off, arms_off))
		centers.append(torso_off.x)
	# Jambe gauche refaite par miroir de la jambe droite de l'image opposée (axe : colonne 23,5 + décalage).
	var leg: Array = s["mirror_leg"]
	for k in frames.size():
		var j := (k + frames.size() / 2) % frames.size()
		var limit: int = leg[1] + centers[k]
		for y in range(leg[0], H):
			for x in range(limit + 1):
				var sx: int = W - 1 + centers[j] + centers[k] - x
				images[k].set_pixel(x, y, images[j].get_pixel(sx, y) if sx > limit and sx < W else Color(0, 0, 0, 0))
	var sheet := Image.create(W * frames.size(), H, false, Image.FORMAT_RGBA8)
	for k in frames.size():
		sheet.blit_rect(images[k], Rect2i(0, 0, W, H), Vector2i(k * W, 0))
	sheet.save_png(OUT % dir)
	_game_sheet(frames.size())
	print("transfer_walk : %s -> %s, %d images ; décalages %s" % [dir, OUT % dir, frames.size(), ", ".join(report)])
	quit()


func _transfer(frame: Image, soldier: Image, palette: Array, s: Dictionary, head_off: Vector2i, torso_off: Vector2i, arms_off: Array) -> Image:
	var out := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var head: Array = s["head"]
	var torso: Array = s["torso"]
	var cols: Array = s["torso_cols"]
	var arms: Array = s["arms"]
	var below: Array = s["below_club"]
	# Héros : ses jambes seulement, recolorées ; tête, torse, bras et massue retirés.
	for y in H:
		for x in W:
			var c := frame.get_pixel(x, y)
			if c.a == 0.0:
				continue
			if y <= head[1] + head_off.y:
				continue
			if y >= torso[0] + torso_off.y and y <= torso[1] + torso_off.y and x >= cols[0] + torso_off.x and x <= cols[1] + torso_off.x:
				continue
			if y >= arms[0] and y <= arms[1] + maxi(arms_off[0].y, arms_off[1].y) and (x <= s["left_arm"][1] + arms_off[0].x or x >= s["right_arm"][0] + arms_off[1].x):
				continue
			if y >= below[0] and x <= below[1]:
				continue
			out.set_pixel(x, y, _nearest(c, palette))
	# Soldat : torse, bras puis tête, recalés sur le mouvement du héros.
	for y in range(torso[0], torso[1] + 1):
		for x in range(cols[0], cols[1] + 1):
			_paste(out, soldier, x, y, torso_off)
	for y in range(arms[0], arms[1] + 1):
		for x in range(s["left_arm"][0], s["left_arm"][1] + 1):
			_paste(out, soldier, x, y, arms_off[0])
		for x in range(s["right_arm"][0], s["right_arm"][1] + 1):
			_paste(out, soldier, x, y, arms_off[1])
	for y in range(head[0], head[1] + 1):
		for x in W:
			_paste(out, soldier, x, y, head_off)
	return out


func _paste(out: Image, src: Image, x: int, y: int, off: Vector2i) -> void:
	var c := src.get_pixel(x, y)
	var p := Vector2i(x, y) + off
	if c.a > 0.0 and p.x >= 0 and p.y >= 0 and p.x < W and p.y < H:
		out.set_pixel(p.x, p.y, c)


## Décalage (±3 px) qui superpose le mieux une partie de la pose fixe du héros à l'image de marche.
func _match(frame: Image, pose: Image, rows: Array, cols: Array) -> Vector2i:
	var best := Vector2i.ZERO
	var best_cost := INF
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var cost := 0.0
			for y in range(rows[0], rows[1] + 1):
				for x in range(cols[0], cols[1] + 1):
					var a := pose.get_pixel(x, y)
					var px := x + dx
					var py := y + dy
					var b := frame.get_pixel(px, py) if px >= 0 and py >= 0 and px < W and py < H else Color(0, 0, 0, 0)
					cost += absf(a.a - b.a) * 2.0 + (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) * minf(a.a, b.a)
			cost += (absi(dx) + absi(dy)) * 0.5
			if cost < best_cost:
				best_cost = cost
				best = Vector2i(dx, dy)
	return best


func _palette(img: Image) -> Array:
	var seen := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				seen[c.to_html(false)] = c
	return seen.values()


func _nearest(c: Color, palette: Array) -> Color:
	var best: Color = palette[0]
	var best_d := INF
	for p: Color in palette:
		var d := (c.r - p.r) ** 2 * 0.3 + (c.g - p.g) ** 2 * 0.59 + (c.b - p.b) ** 2 * 0.11
		if d < best_d:
			best_d = d
			best = p
	return best


func _walk_frames(dir: String) -> Array[String]:
	var folder := SOURCES + "hero/animations/Walking/%s/" % dir
	var out: Array[String] = []
	for f in DirAccess.get_files_at(folder):
		if f.ends_with(".png"):
			out.append(folder + f)
	out.sort()
	return out


## Pose fixe (48 x 48) posée dans une case de 48 x 52, à PAD px du haut.
func _pose(unit: String, dir: String) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var src := _load(SOURCES + "%s/rotations/%s.png" % [unit, dir])
	img.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(0, PAD))
	return img


func _load(path: String) -> Image:
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGBA8)
	return img


func _game_sheet(count: int) -> void:
	var game := Image.create(W * (1 + count), H * ROWS.size(), false, Image.FORMAT_RGBA8)
	for r in ROWS.size():
		var pose := _pose("soldier", ROWS[r])
		var path: String = OUT % ROWS[r]
		var cycle: Image = _load(path) if FileAccess.file_exists(path) else null
		for k in 1 + count:
			var src := cycle if cycle and k > 0 else pose
			var at := Vector2i((k - 1) * W, 0) if src == cycle else Vector2i.ZERO
			game.blit_rect(src, Rect2i(at, Vector2i(W, H)), Vector2i(k * W, r * H))
	game.save_png(SHEET)
