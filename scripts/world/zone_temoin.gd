class_name ZoneTemoin
extends Node2D
## Zone témoin du chantier artistique (docs/WORLD_ART_PLAN.md), autour du camp seulement. Trois rendus,
## que F2 fait défiler pour comparer en jeu :
## - ORIGINAL : le rendu actuel du jeu ;
## - LPC : essai de la voie A (tuiles LPC, assets/art/lpc, OGA-BY 3.0), sol, chemins, rivière et arbres ;
## - INCR : notre propre jeu de tuiles (voie C, docs/TILESET_SPEC.md), au fil des étapes de production ;
##   étape 1 : herbe (grass_fill.png) ; étape 2 : terre et ses bords en grille double (dirt_fill.png,
##   dirt_on_grass.png) ; étape 3 : eau animée et berges (water_fill.png, water_on_grass.png).
##   étape 4 : arbres, buissons, souches et leurs ombres (nature.png). Le pont, les huttes et les
##   petits décors gardent le rendu actuel.
##   étape 5 : décalques au sol (decals.png).
##   étape 6 : falaises, escalier et rebords (cliffs.png), sur une seconde zone : le grand plateau
##   nord-est entier et ses abords (CLIFF_ZONE), qui reçoit aussi notre herbe, nos chemins, nos arbres
##   et nos décalques. L'essai LPC ne la couvre pas : elle y garde le rendu original.
## Au lancement : INCR ; « -- --zone-temoin=off », « =lpc » ou « =incr » pour choisir.
## Purement visuel : carte, collisions et règles intactes.

enum Mode { ORIGINAL, LPC, INCR }
const MODE_NAMES := ["RENDU ORIGINAL", "ESSAI LPC", "TUILES INCR-AGE"]
const OUR_GRASS := preload("res://assets/art/tiles/grass_fill.png")
const OUR_DIRT := preload("res://assets/art/tiles/dirt_fill.png")
const OUR_DIRT_EDGES := preload("res://assets/art/tiles/dirt_on_grass.png")
## Sols qui reçoivent notre herbe : le dessus du plateau, et les faces de falaise (sous leurs parties
## transparentes : coins arrondis, pied).
const GRASS_KINDS := [MapData.Ground.GRASS, MapData.Ground.MEADOW, MapData.Ground.FOREST, MapData.Ground.PLATEAU, MapData.Ground.FACE]
## L'escalier compte comme la terre du chemin qui y mène : la terre passe dessous.
const DIRT_KINDS := [MapData.Ground.PATH, MapData.Ground.SAND, MapData.Ground.STAIRS]
const NATURE := preload("res://assets/art/tiles/nature.png")
const DECALS := preload("res://assets/art/tiles/decals.png")
const OUR_WATER := preload("res://assets/art/tiles/water_fill.png")
const OUR_WATER_EDGES := preload("res://assets/art/tiles/water_on_grass.png")
const WATER_KINDS := [MapData.Ground.WATER, MapData.Ground.BRIDGE]
## Animation de l'eau : 4 images, 6 par seconde.
const WATER_FPS := 6.0
const WATER_FRAMES := 4

## Zone témoin autour du camp, et zone du plateau témoin (étape 6), en cases.
const ZONE := Rect2i(44, 44, 39, 23)
const CLIFF_ZONE := Rect2i(78, 4, 42, 38)
const ZONES: Array[Rect2i] = [ZONE, CLIFF_ZONE]
## Falaises (cliffs.png, voir tools/draw_cliffs.gd) : colonnes de la planche.
const CLIFFS := preload("res://assets/art/tiles/cliffs.png")
const CLIFF_END_LEFT := 3
const CLIFF_END_RIGHT := 4
const CLIFF_NOOK_LEFT := 5
const CLIFF_NOOK_RIGHT := 6
const CLIFF_SHADOW := Vector2i(6, 2)
const T := 32
const GRASS := preload("res://assets/art/lpc/grass.png")
const DIRT := preload("res://assets/art/lpc/dirt.png")
const WATER := preload("res://assets/art/lpc/watergrass.png")
const TREETOP := preload("res://assets/art/lpc/treetop.png")
const TRUNK := preload("res://assets/art/lpc/trunk.png")
## Planche LPC d'un terrain (3 x 6 cases) : bords et coins de la plaque, coins rentrants,
## remplissages. Coordonnées en cases.
const TL := Vector2i(0, 2)
const TOP := Vector2i(1, 2)
const TR := Vector2i(2, 2)
const LEFT := Vector2i(0, 3)
const RIGHT := Vector2i(2, 3)
const BL := Vector2i(0, 4)
const BOTTOM := Vector2i(1, 4)
const BR := Vector2i(2, 4)
const MISSING_SE := Vector2i(1, 0)
const MISSING_SW := Vector2i(2, 0)
const MISSING_NE := Vector2i(1, 1)
const MISSING_NW := Vector2i(2, 1)
const FILLS: Array[Vector2i] = [Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5), Vector2i(1, 3)]

var _map: MapData
var _entities: Node2D
## Sprites d'origine masqués dans la zone, et arbres LPC ajoutés : basculés ensemble par F2.
var _hidden: Array[CanvasItem] = []
var _trees: Array[Node2D] = []
## Nos arbres, buissons et souches (voie C, étape 4), et décors d'origine masqués seulement sous nos
## tuiles : buissons, et arbres de la zone du plateau (l'essai LPC n'y plante rien).
var _our_trees: Array[Node2D] = []
var _hidden_incr: Array[CanvasItem] = []
## Cases des deux zones, dans l'ordre (rangée par rangée).
var _cells: Array[Vector2i] = []
var _nature := {}
## Décalques au sol : [numéro dans decals.png, position des pieds en pixels], calculés une fois.
var _decals: Array = []
var _mode := Mode.INCR
var _hud: Hud
var _overlay: TileMapLayer
var _overlay_cells := {}
var _time := 0.0
var _frame := 0
## Calque de l'eau, au-dessus du sol de la zone.
var _water := Node2D.new()


func setup(map: MapData, entities: Node2D, hud: Hud = null, overlay: TileMapLayer = null) -> void:
	_map = map
	_entities = entities
	_hud = hud
	_overlay = overlay
	for zone in ZONES:
		for y in range(zone.position.y, zone.end.y):
			for x in range(zone.position.x, zone.end.x):
				_cells.append(Vector2i(x, y))
	# Décors d'origine de la couche Overlay dans les zones (sauf les ponts ; dont l'ombre au pied des
	# falaises) : masqués sous nos tuiles.
	if overlay:
		for c in overlay.get_used_cells():
			if _in_zones(c) and map.ground_at(c) != MapData.Ground.BRIDGE:
				_overlay_cells[c] = [overlay.get_cell_source_id(c), overlay.get_cell_atlas_coords(c)]
	for arg in OS.get_cmdline_user_args():
		match arg:
			"--zone-temoin=off": _mode = Mode.ORIGINAL
			"--zone-temoin=lpc": _mode = Mode.LPC
			"--zone-temoin=incr": _mode = Mode.INCR
	# Les décors sont posés juste après le terrain : on attend qu'ils existent pour les relever.
	_collect_old_trees.call_deferred()
	_plant_trees()
	_plant_our_trees()
	_place_decals()
	_water.draw.connect(_draw_water)
	add_child(_water)


## Eau animée : on ne redessine qu'au changement d'image (6 fois par seconde).
func _process(delta: float) -> void:
	if _mode != Mode.INCR:
		return
	_time += delta
	var frame := int(_time * WATER_FPS) % WATER_FRAMES
	if frame != _frame:
		_frame = frame
		_water.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F2:
		_set_mode((_mode + 1) % Mode.size())
		if _hud:
			_hud.announce(MODE_NAMES[_mode])
		get_viewport().set_input_as_handled()


func _set_mode(mode: int) -> void:
	_mode = mode
	visible = mode != Mode.ORIGINAL
	# Les arbres LPC ne remplacent les arbres d'origine que dans l'essai LPC.
	# Arbres d'origine remplacés dans l'essai LPC (arbres LPC) comme dans nos tuiles (nos arbres) ;
	# buissons d'origine remplacés dans nos tuiles seulement.
	for item in _hidden:
		item.visible = mode == Mode.ORIGINAL
	for item in _hidden_incr:
		item.visible = mode != Mode.INCR
	for tree in _trees:
		tree.visible = mode == Mode.LPC
	for tree in _our_trees:
		tree.visible = mode == Mode.INCR
	for c: Vector2i in _overlay_cells:
		if mode == Mode.INCR:
			_overlay.erase_cell(c)
		else:
			_overlay.set_cell(c, _overlay_cells[c][0], _overlay_cells[c][1])
	queue_redraw()
	_water.queue_redraw()


## Arbres d'origine des zones (forêts, arbres isolés) et buissons : masqués selon le rendu affiché.
## Seuls leurs dessins sont masqués : leurs collisions restent en place.
func _collect_old_trees() -> void:
	for child in _entities.get_children():
		if child.name.begins_with("ForestRow"):
			for sprite: Node2D in child.get_children():
				if _in_zone(sprite.global_position):
					_hidden.append(sprite)
				elif _in_zones(Vector2i(sprite.global_position / T)):
					_hidden_incr.append(sprite)
		elif child is Node2D and not child in _trees and not child in _our_trees and _in_zones(Vector2i((child as Node2D).global_position / T)):
			var ch := _map.char_at(Vector2i((child as Node2D).global_position / T))
			if ch.length() == 1 and ch in "tpb":
				for part in child.get_children():
					if part is Sprite2D:
						if ch == "b" or not _in_zone(child.global_position):
							_hidden_incr.append(part)
						else:
							_hidden.append(part)
	_set_mode(_mode)


## Nos arbres (voie C, étape 4) : en forêt, un par case en quinconce comme les arbres d'origine,
## un peu assombris au cœur de la forêt ; feuillus et sapins sur les arbres isolés de la carte,
## nos buissons sur ses buissons, et deux souches posées en lisière (décor, sans collision).
const FOREST_MIX := ["oak", "birch", "wide", "oak", "pine", "wide", "birch", "pine"]
const STUMPS: Array[Vector2i] = [Vector2i(64, 62), Vector2i(50, 51)]


func _plant_our_trees() -> void:
	_nature = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/tiles/nature.json"))
	for c in _cells:
		var ch := _map.char_at(c)
		var at := Vector2(c * T) + Vector2(T * 0.5, T * 0.75)
		if _map.ground_at(c) == MapData.Ground.FOREST:
			var stagger := 8.0 if c.y % 2 else -8.0
			at += Vector2(stagger + (_hash(c) % 9 - 4), _hash(c + Vector2i(5, 9)) % 7 - 3)
			var shade := 1.0 if _forest_edge(c) else 0.84 + (_hash(c) % 10) * 0.01
			_add_ours(FOREST_MIX[_hash(c) % FOREST_MIX.size()], at, shade, _hash(c) % 2 == 0)
		elif ch == "t":
			_add_ours(["oak", "birch", "wide"][_hash(c) % 3], at, 1.0, _hash(c) % 2 == 0)
		elif ch == "p":
			_add_ours("pine", at, 1.0, _hash(c) % 2 == 0)
		elif ch == "b":
			_add_ours("bush_berry" if _hash(c) % 3 == 0 else "bush", at, 1.0, _hash(c) % 2 == 0)
	for c in STUMPS:
		_add_ours("stump", Vector2(c * T) + Vector2(T * 0.5, T * 0.75), 1.0, false)


func _forest_edge(c: Vector2i) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if _map.ground_at(c + d) != MapData.Ground.FOREST:
			return true
	return false


## Un objet de la planche nature.png, posé à ses pieds, avec son ombre dessous (même nœud, trié en profondeur).
func _add_ours(key: String, at: Vector2, shade: float, flip: bool) -> void:
	var node := Node2D.new()
	node.position = at.round()
	for part in [key + "_shadow", key]:
		var info: Dictionary = _nature[part]
		var sprite := Sprite2D.new()
		sprite.texture = NATURE
		sprite.region_enabled = true
		sprite.region_rect = Rect2(info["rect"][0], info["rect"][1], info["rect"][2], info["rect"][3])
		sprite.centered = false
		sprite.offset = -Vector2(info["pivot"][0], info["pivot"][1])
		# L'ombre n'est jamais retournée : la lumière vient toujours d'en haut à gauche.
		sprite.flip_h = flip and part == key
		if part == key:
			sprite.modulate = Color(shade, shade, shade)
		node.add_child(sprite)
	_entities.add_child(node)
	_our_trees.append(node)


## Arbres LPC : un toutes les deux cases en forêt (couvert dense), et sur chaque arbre isolé.
func _plant_trees() -> void:
	for y in range(ZONE.position.y, ZONE.end.y):
		for x in range(ZONE.position.x, ZONE.end.x):
			var c := Vector2i(x, y)
			var forest := _map.ground_at(c) == MapData.Ground.FOREST
			if (forest and (x + (y / 2) % 2) % 2 == 0 and y % 2 == 0) or _map.char_at(c) in "tp":
				var pine := _map.char_at(c) == "p" or (forest and _hash(c) % 3 == 0)
				_add_tree(c, pine)


func _add_tree(c: Vector2i, pine: bool) -> void:
	var tree := Node2D.new()
	var jitter := Vector2(_hash(c) % 9 - 4, _hash(c + Vector2i(7, 3)) % 7 - 3)
	tree.position = Vector2(c * T) + Vector2(T * 0.5, T * 0.8) + jitter
	var variant := _hash(c) % 2
	var trunk := Sprite2D.new()
	trunk.texture = TRUNK
	trunk.region_enabled = true
	trunk.region_rect = Rect2(variant * 96, 0, 96, 96)
	trunk.centered = false
	trunk.offset = Vector2(-48, -78)
	tree.add_child(trunk)
	var crown := Sprite2D.new()
	crown.texture = TREETOP
	crown.region_enabled = true
	crown.centered = false
	if pine:
		crown.region_rect = Rect2(variant * 96, 96, 96, 128)
		crown.offset = Vector2(-48, -150)
	else:
		crown.region_rect = Rect2(variant * 96, 0, 96, 96)
		crown.offset = Vector2(-48, -130)
	tree.add_child(crown)
	_entities.add_child(tree)
	_trees.append(tree)


func _draw() -> void:
	if _map == null:
		return
	if _mode == Mode.INCR:
		_draw_incr()
		return
	# Par couche (une texture à la fois) : fond d'herbe, terre, eau. La prairie fleurie garde le fond
	# d'herbe : la plaque d'herbe claire LPC dessinait un contour sombre peu naturel.
	for y in range(ZONE.position.y, ZONE.end.y):
		for x in range(ZONE.position.x, ZONE.end.x):
			var c := Vector2i(x, y)
			if _map.ground_at(c) != MapData.Ground.BRIDGE:
				_tile(GRASS, c, FILLS[_hash(c) % 3])
	_layer(DIRT, [MapData.Ground.PATH, MapData.Ground.SAND])
	_layer(WATER, [MapData.Ground.WATER, MapData.Ground.BRIDGE])


## Notre jeu de tuiles.
## 1. Remplissages, case par case : herbe sur les cases d'herbe, de prairie et de forêt (sous les arbres,
##    sans bande du vert d'origine autour), variantes 0 à 3 à 20 % chacune, motte et fleurs à 10 % ;
##    terre sur les chemins (3 variantes).
## 2. Grille double : à chaque sommet entre quatre cases, une tuile décalée d'une demi-case. La terre
##    d'abord (tuiles opaques, l'eau y compte comme de l'herbe), puis l'eau, qui pose aussi les tuiles
##    pleines : les cases d'eau reçoivent de l'herbe dessous, si bien que la part « terre » d'une berge
##    arrondie montre de l'herbe et non de l'eau. Les sommets de bordure sont inclus pour l'eau.
func _draw_incr() -> void:
	for c in _cells:
		var g := _map.ground_at(c)
		if g in GRASS_KINDS or g in WATER_KINDS:
			var h := _hash(c) % 20
			var v := h / 4 if h < 16 else (4 if h < 18 else 5)
			draw_texture_rect_region(OUR_GRASS, Rect2(Vector2(c * T), Vector2(T, T)), Rect2(v * T, 0, T, T))
		elif g in DIRT_KINDS:
			draw_texture_rect_region(OUR_DIRT, Rect2(Vector2(c * T), Vector2(T, T)), Rect2(_hash(c) % 3 * T, 0, T, T))
	# Terre, puis berges et eau par-dessus (côté terre des berges transparent, sauf une lèvre d'herbe).
	for zone in ZONES:
		for vy in range(zone.position.y + 1, zone.end.y):
			for vx in range(zone.position.x + 1, zone.end.x):
				var dest := Rect2(Vector2(vx * T - T / 2, vy * T - T / 2), Vector2(T, T))
				var mask := _corners(vx, vy, DIRT_KINDS)
				if mask != 0 and mask != 15:
					draw_texture_rect_region(OUR_DIRT_EDGES, dest, Rect2(mask % 4 * T, mask / 4 * T, T, T))
	_draw_cliffs()
	# Décalques au sol (étape 5), posés à plat par-dessus le sol et sous les personnages.
	for d: Array in _decals:
		draw_texture_rect_region(DECALS, Rect2(d[1] - Vector2(8, 15), Vector2(16, 16)), Rect2(d[0] * 16, 0, 16, 16))


## Eau et berges (calque à part, seul redessiné à chaque image de l'animation).
func _draw_water() -> void:
	if _mode != Mode.INCR:
		return
	for zone in ZONES:
		for vy in range(zone.position.y, zone.end.y + 1):
			for vx in range(zone.position.x, zone.end.x + 1):
				var mask := _corners(vx, vy, WATER_KINDS)
				if mask == 0:
					continue
				var dest := Rect2(Vector2(vx * T - T / 2, vy * T - T / 2), Vector2(T, T))
				if mask == 15:
					_water.draw_texture_rect_region(OUR_WATER, dest, Rect2(_frame * T, 0, T, T))
				else:
					_water.draw_texture_rect_region(OUR_WATER_EDGES, dest, Rect2(_frame * T * 4 + mask % 4 * T, mask / 4 * T, T, T))


## Falaises du plateau (étape 6), par-dessus l'herbe et la terre, sous les décalques et les personnages.
## Faces : face haute (sous le plateau) ou basse ; une face prolonge sa voisine de même hauteur. Contre
## un sol plus bas, son bout s'arrondit (coin saillant) ; contre le plateau, ou contre une face plus
## avancée, elle passe derrière (coin rentrant, avec l'ombre du relief voisin à gauche). Escalier avec
## ses joues ; rebords vus de dessus sur les bords ouest, est et nord du plateau ; ombre au pied des faces.
func _draw_cliffs() -> void:
	for c in _cells:
		match _map.ground_at(c):
			MapData.Ground.FACE:
				var top := _map.ground_at(c + Vector2i.UP) != MapData.Ground.FACE
				var row := 0 if top else 1
				var left := _face_side(c, Vector2i.LEFT)
				var right := _face_side(c, Vector2i.RIGHT)
				var col := _hash(c) % 3
				if left == 1:
					col = CLIFF_END_LEFT
				elif right == 1:
					col = CLIFF_END_RIGHT
				_cliff(c, Vector2i(col, row))
				if left == 2:
					_cliff(c, Vector2i(CLIFF_NOOK_LEFT, row))
				if right == 2:
					_cliff(c, Vector2i(CLIFF_NOOK_RIGHT, row))
			MapData.Ground.STAIRS:
				var top := _map.ground_at(c + Vector2i.UP) == MapData.Ground.PLATEAU
				_cliff(c, Vector2i(0 if top else 1, 2))
				if _map.ground_at(c + Vector2i.LEFT) != MapData.Ground.STAIRS:
					_cliff(c, Vector2i(2 if top else 4, 2))
				if _map.ground_at(c + Vector2i.RIGHT) != MapData.Ground.STAIRS:
					_cliff(c, Vector2i(3 if top else 5, 2))
			MapData.Ground.PLATEAU:
				var v := _hash(c) % 2
				if _map.ground_at(c + Vector2i.LEFT) != MapData.Ground.PLATEAU:
					_cliff(c, Vector2i(v, 3))
				if _map.ground_at(c + Vector2i.RIGHT) != MapData.Ground.PLATEAU:
					_cliff(c, Vector2i(2 + v, 3))
				if _map.ground_at(c + Vector2i.UP) != MapData.Ground.PLATEAU:
					_cliff(c, Vector2i(4 + v, 3))
			var g:
				var above := c + Vector2i.UP
				if g != MapData.Ground.WATER and _map.ground_at(above) == MapData.Ground.FACE \
						and _map.ground_at(above + Vector2i.UP) == MapData.Ground.FACE:
					_cliff(c, CLIFF_SHADOW)


## Côté d'une face : 0 si elle continue (face de même hauteur, escalier), 1 si son bout est à l'air
## (coin saillant), 2 si elle passe derrière le relief voisin (coin rentrant).
func _face_side(c: Vector2i, dir: Vector2i) -> int:
	var n := c + dir
	match _map.ground_at(n):
		MapData.Ground.STAIRS:
			return 0
		MapData.Ground.PLATEAU:
			return 2
		MapData.Ground.FACE:
			var mine := _face_top_row(c)
			var theirs := _face_top_row(n)
			return 0 if mine == theirs else (1 if mine > theirs else 2)
	return 1


## Rangée du haut de la face à laquelle appartient la case (la face fait deux rangées).
func _face_top_row(c: Vector2i) -> int:
	return c.y if _map.ground_at(c + Vector2i.UP) != MapData.Ground.FACE else c.y - 1


func _cliff(c: Vector2i, tile: Vector2i) -> void:
	draw_texture_rect_region(CLIFFS, Rect2(Vector2(c * T), Vector2(T, T)), Rect2(Vector2(tile * T), Vector2(T, T)))


## Coins du sommet (vx, vy) appartenant à `kinds` : haut-gauche 1, haut-droite 2, bas-gauche 4,
## bas-droite 8 (docs/TILESET_SPEC.md, section 5).
func _corners(vx: int, vy: int, kinds: Array) -> int:
	var mask := 0
	for k in 4:
		if _map.ground_at(Vector2i(vx - 1 + k % 2, vy - 1 + k / 2)) in kinds:
			mask |= 1 << k
	return mask


## Plaque d'un terrain : chaque case choisit son bord, son coin ou son remplissage d'après ses voisines.
func _layer(tex: Texture2D, kinds: Array) -> void:
	for y in range(ZONE.position.y, ZONE.end.y):
		for x in range(ZONE.position.x, ZONE.end.x):
			var c := Vector2i(x, y)
			var g := _map.ground_at(c)
			if not g in kinds or g == MapData.Ground.BRIDGE:
				continue
			var n := _is(c + Vector2i.UP, kinds)
			var s := _is(c + Vector2i.DOWN, kinds)
			var w := _is(c + Vector2i.LEFT, kinds)
			var e := _is(c + Vector2i.RIGHT, kinds)
			var tile := FILLS[_hash(c) % FILLS.size()]
			if (not n and not s) or (not w and not e):
				tile = FILLS[3]
			elif not n:
				tile = TL if not w else (TR if not e else TOP)
			elif not s:
				tile = BL if not w else (BR if not e else BOTTOM)
			elif not w:
				tile = LEFT
			elif not e:
				tile = RIGHT
			elif not _is(c + Vector2i(1, 1), kinds):
				tile = MISSING_SE
			elif not _is(c + Vector2i(-1, 1), kinds):
				tile = MISSING_SW
			elif not _is(c + Vector2i(1, -1), kinds):
				tile = MISSING_NE
			elif not _is(c + Vector2i(-1, -1), kinds):
				tile = MISSING_NW
			_tile(tex, c, tile)


func _is(c: Vector2i, kinds: Array) -> bool:
	return not _map.in_bounds(c) or _map.ground_at(c) in kinds


func _tile(tex: Texture2D, c: Vector2i, src: Vector2i) -> void:
	draw_texture_rect_region(tex, Rect2(Vector2(c * T), Vector2(T, T)), Rect2(Vector2(src * T), Vector2(T, T)))


func _in_zone(p: Vector2) -> bool:
	return ZONE.has_point(Vector2i(p / T))


## Case dans l'une des deux zones (camp, plateau).
func _in_zones(c: Vector2i) -> bool:
	for zone in ZONES:
		if zone.has_point(c):
			return true
	return false


static func _hash(c: Vector2i) -> int:
	return absi((c.x * 73856093) ^ (c.y * 19349663)) % 1000


# --- Décalques au sol (voie C, étape 5) -------------------------------------------------------

## Numéros dans decals.png : touffes 0 à 2, fleurs 3 (jaune), 4 (blanche), 5 (mauve), cailloux 6 et 7,
## feuilles mortes 8 et 9, champignons 10 et 11.
const DECAL_TUFTS := [0, 1, 2]
const DECAL_FLOWERS := [3, 4, 5]
## Probabilité (sur 1000) qu'une case lance une grappe, selon son voisinage.
const SEED_EDGE := 300
const SEED_PATH := 80
const SEED_OPEN := 100
## Décors de la carte autour desquels on ne pose rien (huttes, feu, rondins, bois, séchoir, caisses, totem).
const BUSY_PROPS := "hFlwkcI"


## Grappes irrégulières et reproductibles (même résultat à chaque lancement) :
## - en lisière (à deux cases au plus des forêts et des arbres, au-delà de la canopée qui couvre la
##   première) : feuilles mortes, quelques champignons, touffes ;
## - le long des chemins : quelques cailloux et touffes ;
## - en terrain ouvert : touffes et, parfois, un bouquet d'une seule couleur.
## Les grappes sont espacées d'au moins deux cases, pour garder des zones calmes. Rien sur l'eau, le pont,
## les chemins et le camp, ni près des bâtiments des trois stades du village.
func _place_decals() -> void:
	var blocked := {}
	for stage: int in CampVillage.STAGE_PROPS:
		for item: Array in CampVillage.STAGE_PROPS[stage]:
			var p: Vector2i = item[1]
			for y in range(p.y - 2, p.y + 2):
				for x in range(p.x - 2, p.x + 3):
					blocked[Vector2i(x, y)] = true
	for c in _cells:
		var ch := _map.char_at(c)
		if ch.length() == 1 and BUSY_PROPS.contains(ch):
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					blocked[c + Vector2i(dx, dy)] = true
	var is_tree := func(n: Vector2i) -> bool:
		return _map.ground_at(n) == MapData.Ground.FOREST or _map.char_at(n) in ["t", "p"]
	var is_path := func(n: Vector2i) -> bool:
		return _map.ground_at(n) == MapData.Ground.PATH
	var seeds: Array[Vector2i] = []
	for c in _cells:
		if not _decal_ok(c, blocked):
			continue
		var edge := _near(c, is_tree, 2)
		var path := _near(c, is_path)
		var chance := SEED_EDGE if edge else (SEED_PATH if path else SEED_OPEN)
		if _hash(c + Vector2i(31, 17)) >= chance:
			continue
		var crowded := false
		for s in seeds:
			crowded = crowded or (absi(s.x - c.x) <= 2 and absi(s.y - c.y) <= 2)
		if crowded:
			continue
		seeds.append(c)
		_cluster(c, edge, path, blocked)
	print_verbose("ZoneTemoin : %d grappes, %d décalques" % [seeds.size(), _decals.size()])


func _cluster(c: Vector2i, edge: bool, path: bool, blocked: Dictionary) -> void:
	var count := 2 + _hash(c + Vector2i(3, 5)) % 3
	var flower: int = DECAL_FLOWERS[_hash(c + Vector2i(11, 2)) % 3]
	var mushroom_done := false
	for k in count:
		var h := _hash(c + Vector2i(k * 7 + 1, k * 13 + 4))
		var at := Vector2(c * T) + Vector2(T * 0.5, T * 0.6) + Vector2(h % 29 - 14, (h / 29) % 17 - 8)
		if not _decal_ok(Vector2i(at / T), blocked):
			continue
		var kind: int
		if edge:
			kind = [8, 9, 0, 8, 9, 2, 10, 11][h % 8]
			if kind >= 10:
				if mushroom_done:
					kind = 8 + h % 2
				mushroom_done = true
		elif path:
			kind = [6, 7, 0, 2][h % 4]
		else:
			kind = flower if h % 5 == 0 else DECAL_TUFTS[h % 3]
		_decals.append([kind, at.round()])


## Case où un décalque peut se poser : herbe ou prairie nue des zones, hors des abords bâtis.
func _decal_ok(c: Vector2i, blocked: Dictionary) -> bool:
	return _in_zones(c) and not blocked.has(c) and _map.char_at(c) in [".", "\""] \
		and _map.ground_at(c) in [MapData.Ground.GRASS, MapData.Ground.MEADOW]


## Vrai si une case à moins de `radius` cases (hors la case elle-même) vérifie `test`.
func _near(c: Vector2i, test: Callable, radius := 1) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if (dx != 0 or dy != 0) and test.call(c + Vector2i(dx, dy)):
				return true
	return false
