extends Node
## Réglages globaux du prototype. Point unique pour couper les effets d'ambiance
## (eau animée, fumée, halo du feu, papillons) sur une machine modeste ou pour déboguer.

## Effets d'ambiance décoratifs. Désactivés : rendu statique, aucune logique de jeu touchée.
## Aussi désactivables au lancement avec l'argument « -- --no-fx ».
var ambient_effects := true


func _init() -> void:
	if "--no-fx" in OS.get_cmdline_user_args():
		ambient_effects = false
