# Phase 3 — Première progression incrémentale

**Statut : lot 3A réalisé, en attente de validation. Les lots 3B (évolution du village) et 3C (sauvegarde) attendent une validation explicite.**

Écart par rapport au plan : ajout d'un trot de rattrapage des compagnons et d'un décalage latéral conditionnel, nécessaires pour que 8 compagnons suivent sans être replacés de force.

## Lot 3A — Recrutement et améliorations (plan technique)

### Quatre améliorations payées avec les ressources existantes

| Id | Nom affiché | Effet par niveau | Max | Coût du niveau n (n = 0, 1, …) |
|---|---|---|---|---|
| `recruit` | RECRUE | +1 compagnon (3 au départ) | 5 achats → 8 compagnons | vivres 5 × 1,35ⁿ ; matériaux 1 × 1,5ⁿ |
| `damage` | FORCE | +15 % de dégâts pour tout le groupe | 5 | matériaux 3 × 1,45ⁿ ; vivres 2 × 1,4ⁿ ; savoir n − 1 à partir du niveau 2 |
| `magnet` | AIMANT | +24 px de rayon de ramassage (96 au départ) | 4 | matériaux 2 × 1,5ⁿ ; vivres 2 × 1,3ⁿ |
| `vigor` | VIGUEUR | +15 % de vie pour tout le groupe | 4 | vivres 4 × 1,4ⁿ ; matériaux 2 × 1,45ⁿ ; savoir 1 à partir du niveau 2 |

Coûts arrondis à l'entier supérieur.

Un jeune sanglier rapporte environ 2,5 vivres et 1 matériau. Les premiers achats sont donc possibles après 2 ou 3 combats. Le savoir, plus rare, n'intervient qu'aux niveaux élevés.

### Interface : le feu de camp

- **Panneau** : il glisse depuis la gauche quand le héros s'approche du feu, et se referme quand il s'en éloigne.
  - Une ligne par amélioration : icône, nom en police pixel, niveau (pastilles, ou 3/8 pour les recrues), coût en icônes et chiffres.
  - Les ressources manquantes sont en rouge, les lignes non abordables atténuées.
- **Achat** : clic ou toucher sur la ligne (compatible tactile), ou touches 1 à 4 (rangée du haut ou pavé numérique). Le héros reste pilotable, rien d'autre ne change dans les commandes. La navigation à la manette s'ajoutera plus tard sur les mêmes lignes.
- **Repère** : un petit signe doré flotte au-dessus du feu dès qu'un achat est possible, pour attirer le joueur au camp.
- **Retours visuels** :
  - ligne qui brille et compteur qui baisse en rouge ;
  - RECRUE : le compagnon surgit près du feu dans un nuage d'étincelles et rejoint le groupe ;
  - FORCE : tout le groupe s'illumine en or ;
  - VIGUEUR : tout le groupe s'illumine en vert et voit sa vie remontée ;
  - AIMANT : un cercle montre le nouveau rayon.

### Architecture (légère, sans refonte)

- `Upgrades` (`scripts/progression/upgrades.gd`) : catalogue, coûts, effets calculés à partir des niveaux stockés dans `GameState`. Ce stockage sera repris tel quel par la sauvegarde 3C.
- `GameState` reçoit `upgrades`, `can_afford()`, `spend()` et le signal `upgrade_bought`.
- **Effets branchés aux points existants** :
  - `AutoAttack` multiplie les dégâts du groupe ;
  - `Combatant.refresh_max_health()` applique la vigueur ;
  - `Pickup` lit le rayon d'aimant ;
  - `Party.add_follower()` gère le recrutement.
- **Groupe jusqu'à 8** :
  - marche en **colonne par deux** (décalage latéral de ±8 px autour de la trace), qui reste dans les passages de 2 tuiles ;
  - éventail de combat réparti selon le nombre d'alliés ;
  - 8 apparences distinctes.

### Vérifications prévues

- Tour complet de la carte à 8 compagnons : replacements forcés, écart maximal, FPS.
- Achats simulés (`--give`, `--buy`) ; captures du panneau et des effets.
- Combats à 8 compagnons.
