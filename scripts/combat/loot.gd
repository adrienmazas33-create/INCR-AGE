class_name Loot
## Butin lâché par un ennemi abattu, d'après ses caractéristiques (drops, chance de savoir) :
## objets projetés autour de lui, ramassés ensuite par l'aimant du groupe. Partagé par tous les ennemis.

const PICKUP := preload("res://scenes/loot/pickup.gd")


static func drop(stats: UnitStats, at: Vector2, parent: Node, rng: RandomNumberGenerator) -> void:
	var items := []
	for kind in stats.drops:
		var span: Array = stats.drops[kind]
		for i in rng.randi_range(span[0], span[1]):
			items.append(kind)
	if rng.randf() < stats.knowledge_chance:
		items.append("knowledge")
	for kind in items:
		var p := PICKUP.new()
		p.position = at + Vector2(0, -2)
		p.launch(kind, Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30.0, 70.0), rng.randf_range(110.0, 160.0))
		parent.add_child(p)
