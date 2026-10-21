extends SceneTree
## Vérifie la carte sans la modifier : accessibilité depuis le point d'apparition, aperçu optionnel.
## Usage : godot --headless --path . --script res://tools/check_map.gd [-- --preview=<chemin.png>]

const MapDataScript := preload("res://scripts/world/map_data.gd")


func _init() -> void:
	var map = MapDataScript.load_from_file("res://data/maps/prototype.txt")
	print(map.reachability_report())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="):
			map.save_preview(arg.trim_prefix("--preview="))
	quit()
