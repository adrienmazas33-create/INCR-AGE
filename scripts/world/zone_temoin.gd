class_name ZoneTemoin
extends Node2D
## Zone témoin du chantier artistique (docs/WORLD_ART_PLAN.md), autour du camp seulement. Trois rendus,
## que F2 fait défiler pour comparer en jeu :
## - ORIGINAL : le rendu actuel du jeu ;
## - LPC : essai de la voie A (tuiles LPC, assets/art/lpc, OGA-BY 3.0), sol, chemins, rivière et arbres ;
## - INCR : notre propre jeu de tuiles (voie C, docs/TILESET_SPEC.md), au fil des étapes de production ;
##   étape 1 : herbe (grass_fill.png) ; étape 2 : terre et ses bords en grille double (dirt_fill.png,
##   dirt_on_grass.png) ; étape 3 : eau animée et berges (water_fill.png, water_on_grass.png).
##   Le reste (pont, arbres, décors) garde le rendu actuel ; le pont, posé au-dessus, reste visible.
## Au lancement : INCR ; « -- --zone-temoin=off », « =lpc » ou « =incr » pour choisir.
## Purement visuel : carte, collisions et règles intactes.

enum Mode { ORIGINAL, LPC, INCR }
const MODE_NAMES := ["RENDU ORIGINAL", "ESSAI LPC", "TUILES INCR-AGE"]
const OUR_GRASS := preload("res://assets/art/tiles/grass_fill.png")
const OUR_DIRT := preload("res://assets/art/tiles/dirt_fill.png")
const OUR_DIRT_EDGES := preload("res://assets/art/tiles/dirt_on_grass.png")
const GRASS_KINDS := [MapData.Ground.GRASS, MapData.Ground.MEADOW, MapData.Ground.FOREST]
const DIRT_KINDS := [MapData.Ground.PATH, MapData.Ground.SAND]
const OUR_WATER := preload("res://assets/art/tiles/water_fill.png")
const OUR_WATER_EDGES := preload("res://assets/art/tiles/water_on_grass.png")
const WATER_KINDS := [MapData.Ground.WATER, MapData.Ground.BRIDGE]
## Animation de l'eau : 4 images, 6 par seconde.
const WATER_FPS := 6.0
const WATER_FRAMES := 4

## Zone témoin, en cases (bornes incluses).
const ZONE := Rect2i(44, 44, 39, 23)
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
	# Décors d'origine de la couche Overlay dans la zone (sauf les ponts) : masqués sous nos tuiles.
	if overlay:
		for c in overlay.get_used_cells():
			if ZONE.has_point(c) and map.ground_at(c) != MapData.Ground.BRIDGE:
				_overlay_cells[c] = [overlay.get_cell_source_id(c), overlay.get_cell_atlas_coords(c)]
	for arg in OS.get_cmdline_user_args():
		match arg:
			"--zone-temoin=off": _mode = Mode.ORIGINAL
			"--zone-temoin=lpc": _mode = Mode.LPC
			"--zone-temoin=incr": _mode = Mode.INCR
	# Les décors sont posés juste après le terrain : on attend qu'ils existent pour les relever.
	_collect_old_trees.call_deferred()
	_plant_trees()
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
	for item in _hidden:
		item.visible = mode != Mode.LPC
	for tree in _trees:
		tree.visible = mode == Mode.LPC
	for c: Vector2i in _overlay_cells:
		if mode == Mode.INCR:
			_overlay.erase_cell(c)
		else:
			_overlay.set_cell(c, _overlay_cells[c][0], _overlay_cells[c][1])
	queue_redraw()
	_water.queue_redraw()


## Arbres d'origine de la zone (forêts et arbres isolés) : masqués pendant l'essai.
func _collect_old_trees() -> void:
	for child in _entities.get_children():
		if child.name.begins_with("ForestRow"):
			for sprite: Node2D in child.get_children():
				if _in_zone(sprite.global_position):
					_hidden.append(sprite)
		elif child is Node2D and not child in _trees and _in_zone(child.global_position):
			var c := Vector2i((child as Node2D).global_position / T)
			if _map.char_at(c) in "tp":
				for part in child.get_children():
					if part is Sprite2D:
						_hidden.append(part)
	_set_mode(_mode)


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
	for y in range(ZONE.position.y, ZONE.end.y):
		for x in range(ZONE.position.x, ZONE.end.x):
			var c := Vector2i(x, y)
			var g := _map.ground_at(c)
			if g in GRASS_KINDS or g in WATER_KINDS:
				var h := _hash(c) % 20
				var v := h / 4 if h < 16 else (4 if h < 18 else 5)
				draw_texture_rect_region(OUR_GRASS, Rect2(Vector2(c * T), Vector2(T, T)), Rect2(v * T, 0, T, T))
			elif g in DIRT_KINDS:
				draw_texture_rect_region(OUR_DIRT, Rect2(Vector2(c * T), Vector2(T, T)), Rect2(_hash(c) % 3 * T, 0, T, T))
	# Terre, puis berges et eau par-dessus (côté terre des berges transparent, sauf une lèvre d'herbe).
	for vy in range(ZONE.position.y + 1, ZONE.end.y):
		for vx in range(ZONE.position.x + 1, ZONE.end.x):
			var dest := Rect2(Vector2(vx * T - T / 2, vy * T - T / 2), Vector2(T, T))
			var mask := _corners(vx, vy, DIRT_KINDS)
			if mask != 0 and mask != 15:
				draw_texture_rect_region(OUR_DIRT_EDGES, dest, Rect2(mask % 4 * T, mask / 4 * T, T, T))


## Eau et berges (calque à part, seul redessiné à chaque image de l'animation).
func _draw_water() -> void:
	if _mode != Mode.INCR:
		return
	for vy in range(ZONE.position.y, ZONE.end.y + 1):
		for vx in range(ZONE.position.x, ZONE.end.x + 1):
			var mask := _corners(vx, vy, WATER_KINDS)
			if mask == 0:
				continue
			var dest := Rect2(Vector2(vx * T - T / 2, vy * T - T / 2), Vector2(T, T))
			if mask == 15:
				_water.draw_texture_rect_region(OUR_WATER, dest, Rect2(_frame * T, 0, T, T))
			else:
				_water.draw_texture_rect_region(OUR_WATER_EDGES, dest, Rect2(_frame * T * 4 + mask % 4 * T, mask / 4 * T, T, T))


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


static func _hash(c: Vector2i) -> int:
	return absi((c.x * 73856093) ^ (c.y * 19349663)) % 1000
