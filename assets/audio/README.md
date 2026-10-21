# Sons d'INCR-AGE — origine et licences

| Fichier | Origine | Licence |
|---|---|---|
| `sfx/hit.wav` | Synthèse originale, `tools/generate_sfx.gd` | Propriété du projet, aucun tiers |
| `sfx/pickup.wav` | Idem | Idem |
| `sfx/buy.wav` | Idem | Idem |
| `sfx/boar_grunt.wav` | Idem | Idem |
| `sfx/fire_loop.wav` | Idem | Idem |

Aucun échantillon extérieur n'est utilisé : chaque son est calculé note par note (marimba, bruit filtré, ondes simples).

Pour régénérer :
```
godot --headless --path . --script res://tools/generate_sfx.gd
godot --headless --path . --import
```

Tout son ajouté plus tard, venant d'une source extérieure, doit être listé ici avec :
- sa source (lien) ;
- son auteur ;
- sa licence, qui doit autoriser l'usage commercial (CC0 de préférence).
