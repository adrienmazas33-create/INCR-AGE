class_name UnitStats
extends Resource
## Caractéristiques d'une unité, réglables dans l'éditeur (fichiers data/units/*.tres) sans toucher au code.

@export var display_name := ""

@export_group("Vie")
@export var max_health := 40.0
## Points de vie rendus par seconde, après quelques secondes sans être touché (0 = aucun).
@export var regen_per_second := 0.0

@export_group("Attaque")
@export var damage := 5.0
## Portée de mêlée, mesurée jusqu'au bord de la cible.
@export var attack_range := 14.0
@export var attack_cooldown := 0.7
## Délai entre le début du geste (visible) et l'impact.
@export var attack_windup := 0.1
@export var knockback := 80.0

@export_group("Corps")
@export var move_speed := 100.0
## Rayon du corps, pour mesurer les portées de bord à bord.
@export var body_radius := 5.0
## Part du recul effectivement subie (0 = inébranlable, 1 = recul complet).
@export var knockback_taken := 1.0

@export_group("Butin")
## Ressource ("food", "materials") -> [minimum, maximum] d'objets lâchés.
@export var drops := {}
## Chance de lâcher un objet de savoir.
@export var knowledge_chance := 0.0
