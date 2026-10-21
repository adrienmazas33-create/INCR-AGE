extends Node
## Réglages globaux du prototype. Point unique pour couper les effets d'ambiance
## (eau animée, fumée, halo du feu, papillons) sur une machine modeste ou pour déboguer.

## Effets d'ambiance décoratifs. Désactivés : rendu statique, aucune logique de jeu touchée.
## Aussi désactivables au lancement avec l'argument « -- --no-fx ».
var ambient_effects := true
## Secousse de caméra sur les coups forts.
var screen_shake := true
## Micro-pause du jeu à l'impact (sensation de poids). « -- --no-hitstop » pour la couper.
var hit_stop := true


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if "--no-fx" in args:
		ambient_effects = false
	if "--no-hitstop" in args:
		hit_stop = false
