class_name DevCapture
extends Node
## Outil de développement : placement, déplacements scriptés et capture d'écran en ligne de commande.
## Exemple : Godot --path . -- --at=58,40 --zoom=0 --walk=move_up:1.5,move_left:0.5 --capture=C:/tmp/shot.png
## Sans ces arguments, rien n'est ajouté au jeu.

var _hero: Node2D
var _camera: GameCamera
var _capture_path := ""
var _steps := []
var _settle := 0.8


static func attach_if_requested(parent: Node, hero: Node2D, camera: GameCamera) -> void:
	var args := OS.get_cmdline_user_args()
	if not Array(args).any(func(a: String) -> bool: return a.begins_with("--capture") or a.begins_with("--walk") or a.begins_with("--at")):
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
				var p := kv[1].split(",")
				_hero.position = Vector2(int(p[0]), int(p[1])) * TileIds.SIZE + Vector2(16, 24)
				_hero.reset_physics_interpolation()
			"--zoom":
				_camera.set_level(int(kv[1]))
			"--walk":
				for step in kv[1].split(","):
					var q := step.split(":")
					_steps.append([q[0], float(q[1])])
			"--settle":
				_settle = float(kv[1])
			"--capture":
				_capture_path = kv[1]
	_camera.snap_to_target()


func _ready() -> void:
	_run()


func _run() -> void:
	await get_tree().create_timer(0.3).timeout
	for step in _steps:
		Input.action_press(step[0])
		await get_tree().create_timer(step[1]).timeout
		Input.action_release(step[0])
	await get_tree().create_timer(_settle).timeout
	print("DevCapture : héros en %s (tuile %s), %d FPS, %d nœuds" % [_hero.global_position, Vector2i(_hero.global_position / TileIds.SIZE),
		Engine.get_frames_per_second(), get_tree().get_node_count()])
	if _capture_path != "":
		for i in 3:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(_capture_path)
	get_tree().quit()
