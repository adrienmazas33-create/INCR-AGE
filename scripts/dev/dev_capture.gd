class_name DevCapture
extends Node
## Outil de développement : placement, déplacements scriptés et capture d'écran en ligne de commande.
## Exemples :
##   Godot --path . -- --at=58,40 --zoom=0 --walk=move_up:1.5,move_left:0.5 --capture=C:/tmp/shot.png
##   Godot --path . -- --route=58,52/57,46/55,41 --capture=C:/tmp/fin.png
##   Godot --path . -- --give=food:30,materials:10 --buy=recruit,damage --capture=C:/tmp/camp.png
## --route conduit le héros d'une tuile à l'autre (comme au clavier) et signale les étapes non atteintes.
## Sans ces arguments, rien n'est ajouté au jeu.

const WAYPOINT_TIMEOUT := 10.0
const MOVE_ACTIONS := ["move_left", "move_right", "move_up", "move_down"]

var _hero: Node2D
var _camera: GameCamera
var _capture_path := ""
var _steps := []
var _route: Array[Vector2] = []
var _settle := 0.8
var _buys := []


static func attach_if_requested(parent: Node, hero: Node2D, camera: GameCamera) -> void:
	var args := OS.get_cmdline_user_args()
	if not Array(args).any(func(a: String) -> bool:
			return a.begins_with("--capture") or a.begins_with("--walk") or a.begins_with("--at") or a.begins_with("--route") or a.begins_with("--buy")):
		return
	var dev := DevCapture.new()
	dev._hero = hero
	dev._camera = camera
	dev._parse(args)
	parent.add_child(dev)


func _parse(args: PackedStringArray) -> void:
	for arg in args:
		var kv := arg.split("=", true, 1)
		match kv[0]:
			"--at":
				_hero.position = _tile_center(kv[1])
				_hero.reset_physics_interpolation()
			"--zoom":
				_camera.set_level(int(kv[1]))
			"--walk":
				for step in kv[1].split(","):
					var q := step.split(":")
					_steps.append([q[0], float(q[1])])
			"--route":
				for wp in kv[1].split("/"):
					_route.append(_tile_center(wp))
			"--hero-hp":
				_hero.health.current = float(kv[1])
			"--give":
				for pair in kv[1].split(","):
					var q := pair.split(":")
					GameState.add(q[0], int(q[1]))
			"--buy":
				_buys = Array(kv[1].split(","))
			"--settle":
				_settle = float(kv[1])
			"--capture":
				_capture_path = kv[1]
	_camera.snap_to_target()


func _ready() -> void:
	_run()


func _run() -> void:
	await get_tree().create_timer(0.3).timeout
	for id in _buys:
		print("DevCapture : achat %s -> %s" % [id, "ok" if Upgrades.buy(id) else "refusé"])
		await get_tree().create_timer(0.25).timeout
	for step in _steps:
		Input.action_press(step[0])
		await get_tree().create_timer(step[1]).timeout
		Input.action_release(step[0])
	if not _route.is_empty():
		await _drive_route()
	await get_tree().create_timer(_settle).timeout
	print("DevCapture : héros en %s (tuile %s), %d FPS, %d nœuds" % [_hero.global_position, Vector2i(_hero.global_position / TileIds.SIZE),
		Engine.get_frames_per_second(), get_tree().get_node_count()])
	var party := get_tree().get_first_node_in_group("party")
	if party:
		print("DevCapture : " + party.debug_summary())
	print("DevCapture : ressources %s ; héros %d/%d PV, %d coup(s) porté(s) ; %d ennemi(s) debout ; échelle de temps %.2f" % [GameState.summary(),
		_hero.health.current, _hero.health.max_health, _hero.attack.hits, get_tree().get_nodes_in_group(&"enemies").size(), Engine.time_scale])
	if _capture_path != "":
		for i in 3:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(_capture_path)
	get_tree().quit()


## Rejoint chaque étape par le plus court chemin praticable de la carte, case par case.
func _drive_route() -> void:
	var map: MapData = get_tree().current_scene.get_node("World").map
	var start := Time.get_ticks_msec()
	for i in _route.size():
		var goal := Vector2i(_route[i] / TileIds.SIZE)
		var cells := _path(map, Vector2i(_hero.global_position / TileIds.SIZE), goal)
		if cells.is_empty():
			print("DevCapture : étape %d %s sans chemin praticable" % [i, goal])
			continue
		for c in cells:
			var wp := Vector2(c * TileIds.SIZE) + Vector2(16, 24)
			var t0 := Time.get_ticks_msec()
			while _hero.global_position.distance_to(wp) > 4.0:
				if Time.get_ticks_msec() - t0 > WAYPOINT_TIMEOUT * 1000.0:
					print("DevCapture : case %s non atteinte, héros bloqué en %s" % [c, Vector2i(_hero.global_position / TileIds.SIZE)])
					break
				_press_towards(wp - _hero.global_position)
				await get_tree().physics_frame
	for a in MOVE_ACTIONS:
		Input.action_release(a)
	print("DevCapture : parcours de %d étapes en %.1f s" % [_route.size(), (Time.get_ticks_msec() - start) / 1000.0])


func _path(map: MapData, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var prev := {from: from}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size() and not prev.has(to):
		var c := queue[head]
		head += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if not prev.has(n) and map.can_step(c, n):
				prev[n] = c
				queue.append(n)
	var out: Array[Vector2i] = []
	if not prev.has(to):
		return out
	var c := to
	while c != from:
		out.push_front(c)
		c = prev[c]
	return out


func _press_towards(v: Vector2) -> void:
	var d := v.normalized()
	var strengths := [maxf(-d.x, 0.0), maxf(d.x, 0.0), maxf(-d.y, 0.0), maxf(d.y, 0.0)]
	for k in 4:
		if strengths[k] > 0.05:
			Input.action_press(MOVE_ACTIONS[k], strengths[k])
		else:
			Input.action_release(MOVE_ACTIONS[k])


func _tile_center(text: String) -> Vector2:
	var p := text.split(",")
	return Vector2(int(p[0]), int(p[1])) * TileIds.SIZE + Vector2(16, 24)
