extends SceneTree
## Assemble les sources PixelLab d'un personnage (assets/source/pixellab/<nom>/) en une planche au
## format de CharacterSprite : rangées face, dos, profil (regard vers la droite ; la gauche est obtenue
## en miroir) ; colonne 0 : la pose fixe, puis les images de marche. Cases de la taille des images de
## marche ; la pose fixe, plus petite, y est centrée (c'est ainsi que PixelLab aligne les deux).
## Aucune mise à l'échelle, aucune retouche de pixel.
## Contrôle : le point le plus bas de chaque image doit tomber dans la même bande (les pieds), sinon
## l'outil signale l'écart et n'écrit rien.
## Usage : godot --headless --path . --script res://tools/pack_pixellab.gd -- <nom> [<sortie>] [--poses]
## (par défaut : hero, assets/art/hero_pixellab.png), puis --import.
## --poses : planche des seules poses fixes (une colonne, cases de la taille des poses), pour un
## personnage dont la marche n'existe pas dans toutes les directions ; le jeu calcule alors un
## balancement de marche (CharacterSprite.walk_sway).

const SOURCES := "res://assets/source/pixellab/"
## Directions PixelLab dans l'ordre des rangées de CharacterSprite (Facing.DOWN, UP, SIDE).
const ROWS := ["south", "north", "east"]
const WALK := "Walking"
## Écart toléré (px) entre les pieds des images : le pas fait monter et descendre le corps.
const FEET_BAND := 5


func _init() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var poses_only := args.has("--poses")
	args.erase("--poses")
	var unit: String = args[0] if args.size() > 0 else "hero"
	var out_path: String = args[1] if args.size() > 1 else "res://assets/art/%s_pixellab.png" % unit
	var root := SOURCES + unit + "/"
	if poses_only:
		_pack_poses(root, unit, out_path)
		return
	var walk_counts: Array[int] = []
	var cell := Vector2i.ZERO
	for dir: String in ROWS:
		var frames := _walk_frames(root, dir)
		if frames.is_empty():
			_fail("aucune image de marche pour « %s »" % dir)
			return
		walk_counts.append(frames.size())
		cell = Image.load_from_file(frames[0]).get_size()
	if walk_counts.min() != walk_counts.max():
		_fail("nombre d'images de marche différent selon la direction : %s" % [walk_counts])
		return
	var columns := 1 + walk_counts[0]
	var sheet := Image.create(columns * cell.x, ROWS.size() * cell.y, false, Image.FORMAT_RGBA8)
	var feet: Array[int] = []
	for r in ROWS.size():
		var pose := Image.load_from_file(root + "rotations/%s.png" % ROWS[r])
		pose.convert(Image.FORMAT_RGBA8)
		var at := Vector2i(0, r * cell.y) + (cell - pose.get_size()) / 2
		sheet.blit_rect(pose, Rect2i(Vector2i.ZERO, pose.get_size()), at)
		feet.append(_lowest(pose) + (cell.y - pose.get_height()) / 2)
		var frames := _walk_frames(root, ROWS[r])
		for k in frames.size():
			var img := Image.load_from_file(frames[k])
			img.convert(Image.FORMAT_RGBA8)
			if img.get_size() != cell:
				_fail("%s : %s au lieu de %s" % [frames[k], img.get_size(), cell])
				return
			sheet.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i((1 + k) * cell.x, r * cell.y))
			feet.append(_lowest(img))
	if feet.max() - feet.min() > FEET_BAND:
		_fail("pieds hors de la bande commune : rangées %d à %d (écart toléré %d)" % [feet.min(), feet.max(), FEET_BAND])
		return
	sheet.save_png(out_path)
	print("pack_pixellab : %s -> %s, %d x %d cases de %d x %d ; pieds aux rangées %d à %d de la case" % [unit, out_path,
		columns, ROWS.size(), cell.x, cell.y, feet.min(), feet.max()])
	quit()


## Planche des poses fixes : une case par rangée, à la taille des poses.
func _pack_poses(root: String, unit: String, out_path: String) -> void:
	var cell := Image.load_from_file(root + "rotations/%s.png" % ROWS[0]).get_size()
	var sheet := Image.create(cell.x, ROWS.size() * cell.y, false, Image.FORMAT_RGBA8)
	var feet: Array[int] = []
	for r in ROWS.size():
		var pose := Image.load_from_file(root + "rotations/%s.png" % ROWS[r])
		pose.convert(Image.FORMAT_RGBA8)
		if pose.get_size() != cell:
			_fail("%s : %s au lieu de %s" % [ROWS[r], pose.get_size(), cell])
			return
		sheet.blit_rect(pose, Rect2i(Vector2i.ZERO, cell), Vector2i(0, r * cell.y))
		feet.append(_lowest(pose))
	if feet.max() - feet.min() > FEET_BAND:
		_fail("pieds hors de la bande commune : rangées %d à %d" % [feet.min(), feet.max()])
		return
	sheet.save_png(out_path)
	print("pack_pixellab : %s (poses fixes) -> %s, 1 x %d cases de %d x %d ; pieds aux rangées %d à %d de la case" % [unit,
		out_path, ROWS.size(), cell.x, cell.y, feet.min(), feet.max()])
	quit()


func _walk_frames(root: String, dir: String) -> Array[String]:
	var folder := root + "animations/%s/%s/" % [WALK, dir]
	var out: Array[String] = []
	for f in DirAccess.get_files_at(folder):
		if f.ends_with(".png"):
			out.append(folder + f)
	out.sort()
	return out


## Rangée du pixel opaque le plus bas.
func _lowest(img: Image) -> int:
	for y in range(img.get_height() - 1, -1, -1):
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				return y
	return -1


func _fail(message: String) -> void:
	push_error("pack_pixellab : " + message)
	quit(1)
