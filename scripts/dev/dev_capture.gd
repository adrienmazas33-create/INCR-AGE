class_name DevCapture
extends Node
## Outil de développement : placement, déplacements scriptés et capture d'écran en ligne de commande.
## Exemples :
##   Godot --path . -- --at=58,40 --zoom=0 --walk=move_up:1.5,move_left:0.5 --capture=C:/tmp/shot.png
##   Godot --path . -- --route=58,52/57,46/55,41 --capture=C:/tmp/fin.png
##   Godot --path . -- --give=food:30,materials:10 --buy=recruit,damage --capture=C:/tmp/camp.png
##   Godot --path . -- --at=58,52 --click=70,60/s600,30:0.5 --capture=C:/tmp/clic.png
##   Godot --path . -- --press=F2 --capture=C:/tmp/f2.png   (touches simulées, séparées par des virgules)
## --click simule de vrais clics de souris : tuile « x,y » ou point d'écran « sx,y » (pixels logiques),
## « :s » pour n'attendre que s secondes avant l'étape suivante (sinon jusqu'à l'arrêt du héros).
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
var _avg_fps := 0.0
var _mover: ClickMover
var _clicks := []
var _presses := []


static func attach_if_requested(parent: Node, hero: Node2D, camera: GameCamera, mover: ClickMover = null) -> void:
	var args := OS.get_cmdline_user_args()
	if not Array(args).any(func(a: String) -> bool:
			return a.begins_with("--capture") or a.begins_with("--walk") or a.begins_with("--at") or a.begins_with("--route") or a.begins_with("--buy") or a.begins_with("--click") or a.begins_with("--press")):
		return
	var dev := DevCapture.new()
	dev._hero = hero
	dev._camera = camera
	dev._mover = mover
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
			"--press":
				_presses = Array(kv[1].split(","))
			"--click":
				_clicks = Array(kv[1].split("/"))
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
	for c in _clicks:
		await _click(c)
	for key_name in _presses:
		await _press(key_name)
	for step in _steps:
		Input.action_press(step[0])
		await get_tree().create_timer(step[1]).timeout
		Input.action_release(step[0])
	if not _route.is_empty():
		await _drive_route()
	# Moyenne d'images par seconde sur toute l'attente (plus fiable que le compteur instantané).
	var frames_before := Engine.get_process_frames()
	var t_before := Time.get_ticks_msec()
	await get_tree().create_timer(_settle).timeout
	_avg_fps = (Engine.get_process_frames() - frames_before) * 1000.0 / maxf(Time.get_ticks_msec() - t_before, 1.0)
	print("DevCapture : héros en %s (tuile %s), %d FPS (moyenne %.1f), %d nœuds" % [_hero.global_position, Vector2i(_hero.global_position / TileIds.SIZE),
		Engine.get_frames_per_second(), _avg_fps, get_tree().get_node_count()])
	var party := get_tree().get_first_node_in_group("party")
	if party:
		print("DevCapture : " + party.debug_summary())
	print("DevCapture : ressources %s ; héros %d/%d PV, %d coup(s) porté(s) ; %d ennemi(s) debout ; échelle de temps %.2f" % [GameState.summary(),
		_hero.health.current, _hero.health.max_health, _hero.attack.hits, get_tree().get_nodes_in_group(&"enemies").size(), Engine.time_scale])
	print("DevCapture : audio %d bruitage(s) joué(s), %d écarté(s) (anti-empilement) ; niveau ambiance %.0f dB" % [AudioManager.played, AudioManager.skipped,
		AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index(AudioManager.AMBIENCE), 0)])
	var ambience := get_tree().current_scene.get_node_or_null("Ambience")
	if ambience:
		print("DevCapture : ambiances " + ambience.debug_summary())
	print("DevCapture : sons joués %s" % AudioManager.counts)
	print("DevCapture : musique %s" % AudioManager.music_summary())
	if _capture_path != "":
		for i in 3:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(_capture_path)
	# Fermeture réaliste : même notification qu'un clic sur la croix de la fenêtre (sauvegarde).
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
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


## Appui puis relâche d'une touche (nom Godot, ex. « F2 »), comme au clavier.
func _press(key_name: String) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = OS.find_keycode_from_string(key_name)
		key.keycode = key.physical_keycode
		key.pressed = pressed
		get_viewport().push_input(key)
		await get_tree().process_frame
	print("DevCapture : touche %s" % key_name)
	await get_tree().create_timer(0.3).timeout


## Clic gauche (mouvement, appui, relâche) envoyé à la fenêtre de jeu, interface comprise.
func _click(entry: String) -> void:
	var parts := entry.split(":")
	var vp := get_viewport()
	var screen: Vector2
	if parts[0].begins_with("s"):
		var q := parts[0].substr(1).split(",")
		screen = Vector2(float(q[0]), float(q[1]))
	else:
		screen = vp.get_canvas_transform() * _tile_center(parts[0])
	var motion := InputEventMouseMotion.new()
	motion.position = screen
	motion.global_position = screen
	vp.push_input(motion, true)
	await get_tree().process_frame
	for pressed in [true, false]:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = pressed
		button.position = screen
		button.global_position = screen
		vp.push_input(button, true)
		await get_tree().process_frame
	var start := Time.get_ticks_msec()
	var limit := float(parts[1]) if parts.size() > 1 else 25.0
	while Time.get_ticks_msec() - start < limit * 1000.0 and (parts.size() > 1 or _mover.is_moving()):
		await get_tree().physics_frame
	print("DevCapture : clic %s -> %s ; héros en %s (tuile %s) après %.1f s" % [entry, "en route" if _mover.is_moving() else "arrêté",
		_hero.global_position.round(), Vector2i(_hero.global_position / TileIds.SIZE), (Time.get_ticks_msec() - start) / 1000.0])


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
