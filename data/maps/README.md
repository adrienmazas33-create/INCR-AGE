# Cartes

`prototype.txt` : carte fixe du prototype, 120 x 100 tuiles de 32 px. Une ligne = une rangée de tuiles.
Elle a été esquissée par `tools/draft_map.gd` (formes placées à la main), puis elle se retouche directement ici.
Relancer `draft_map.gd` écrase les retouches manuelles.

## Légende

| Car. | Sol / objet | Passage |
|---|---|---|
| `.` | herbe | oui |
| `"` | prairie fleurie | oui |
| `:` | chemin de terre | oui |
| `s` | sable | oui |
| `~` | eau | non |
| `o` | eau avec nénuphars | non |
| `=` | pont (posé sur l'eau) | oui |
| `T` | forêt dense | non |
| `#` | plateau (en hauteur) | oui, accès uniquement par escalier |
| `v` | face de falaise (2 rangées sous le bord sud d'un plateau) | non |
| `^` | escalier taillé dans la falaise | oui |
| `t` / `p` | arbre feuillu / pin isolé | non |
| `b` | buisson | non |
| `r` / `R` | petit / gros rocher | non |
| `h` | hutte | non |
| `F` | feu de camp | non |
| `c` `l` `w` `k` | caisse, rondin, tas de bois, séchoir à peaux | non |
| `M` | menhir (repère, point de vue) | non |
| `I` | totem | non |
| `n` | roseaux | oui |
| `@` | apparition du héros | oui |

Sous un objet, le sol reprend le type majoritaire des cases voisines.

Après une retouche, vérifier l'accessibilité :

```
godot --headless --path . --script res://tools/check_map.gd
```
