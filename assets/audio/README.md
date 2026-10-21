# Sons d'INCR-AGE — origine et licences

| Fichier | Origine | Licence |
|---|---|---|
| `sfx/hit.wav` | Synthèse originale, `tools/generate_sfx.gd` | Propriété du projet, aucun tiers |
| `sfx/pickup.wav` | Idem | Idem |
| `sfx/buy.wav` | Idem | Idem |
| `sfx/boar_grunt.wav` | Idem | Idem |
| `sfx/fire_loop.wav` | Idem | Idem |
| `sfx/step_grass.wav`, `step_dirt.wav`, `step_wood.wav`, `step_stone.wav` | Idem (lot B) | Idem |
| `sfx/boar_down.wav`, `camp_stage.wav` | Idem (lot B) | Idem |
| `sfx/meadow_loop.wav`, `water_loop.wav` | Idem (lot B) | Idem |
| `sfx/bird_0.wav` à `bird_3.wav` | Idem (ajustements après le lot B) | Idem |
| `music/theme_exploration.wav` | Composition originale (partition écrite note par note) et rendu par `tools/generate_music.gd` (lot C) | Idem |

Aucun échantillon extérieur n'est utilisé : chaque son est calculé note par note (marimba, bruit filtré, ondes simples).

Pour régénérer (la musique : `res://tools/generate_music.gd`, même principe) :
```
godot --headless --path . --script res://tools/generate_sfx.gd
godot --headless --path . --import
```

Tout son ajouté plus tard, venant d'une source extérieure, doit être listé ici avec :
- sa source (lien) ;
- son auteur ;
- sa licence, qui doit autoriser l'usage commercial (CC0 de préférence).
