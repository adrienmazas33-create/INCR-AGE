# Phase 2 — Compagnons et premiers affrontements (proposition)

Source : bible créative V0.1, « Prototype prioritaire ».
- Étape 0 : il reste « trois alliés qui suivent ».
- Étape 1 : « ennemis simples, attaque du héros, combat automatique, butin, recrutement ».

Comme la bible demande de ne jamais tout développer d'un bloc, la phase est découpée en **deux lots**, avec une validation entre les deux.

## Lot A — Trois alliés qui suivent (fin de l'étape 0)

**Objectif** : trois hommes des cavernes accompagnent le héros partout, de façon naturelle et sans jamais le gêner.

- **Art** : trois variantes du héros (cheveux, tunique, carrure), générées par `tools/generate_art.gd`. Mêmes 3 orientations et mêmes animations.
- **Scène** : `scenes/characters/follower.tscn`. L'animation et l'orientation sont partagées avec le héros via un petit script commun, sans duplication.
- **Suivi** :
  - chaque allié suit la **trace de pas** du héros, à intervalles réguliers ;
  - à l'arrêt, ils se regroupent en petit cercle lâche autour de lui ;
  - une légère séparation empêche les empilements ;
  - un allié bloqué ou distancé de plus d'environ 12 tuiles revient près du héros, hors champ de la caméra.
- **Collisions** : les alliés heurtent le décor, mais ni le héros ni les autres alliés. Ils ne bloquent donc jamais un pont, un escalier ou un chemin étroit.
- **Hors périmètre** : ordres, combat, statistiques, mort.

**Critères de validation**
- Tour complet de la carte, escaliers et ponts compris, sans allié coincé.
- Départs et arrêts fluides, sans tremblement ni chevauchement visible.
- Lecture claire : le héros reste immédiatement repérable dans le groupe.

## Lot B — Premier combat et butin (étape 1, sans recrutement)

**Objectif** : la boucle sortir → combattre → ramasser doit déjà être agréable.

- **Ennemis** : sangliers, placés dans la prairie est et en lisière de forêt.
  - Comportement : errance, détection, charge, coup, fuite à faible vie.
  - Statistiques dans une ressource `UnitStats` (`.tres`), réglables sans code.
- **Combat** :
  - composant `Health` réutilisable ;
  - zones de coup et de dégâts en `Area2D` ;
  - retour visuel : flash blanc, recul, chiffres de dégâts, petite secousse de caméra désactivable ;
  - les alliés attaquent automatiquement l'ennemi le plus proche du héros.
- **Héros** : massue (art), attaque automatique sur l'ennemi le plus proche à portée. Voir la décision 1.
- **Butin** :
  - objets à terre attirés vers le héros (butin magnétique) ;
  - trois ressources abstraites de la bible : vivres, matériaux, savoir ;
  - compteur discret en haut à droite, seul élément d'interface.
- **Défaite du héros** : retour au campement sans perte (la mort du héros est un point ouvert de la bible).
- **Données de jeu** : autoload `GameState` pour les ressources, pensé pour la future sauvegarde mais sans sauvegarde dans ce lot.
- **Hors périmètre** : recrutement, améliorations, village, sauvegarde, époques.

**Critères de validation**
- Une dizaine de minutes de jeu donnent envie de continuer, comme le demande la bible.
- Les combats restent lisibles : qui frappe qui, et qui a mal.
- Le butin est satisfaisant à ramasser, sans encombrer l'écran.
- 60 FPS stables avec une dizaine d'ennemis et le groupe.

## Décisions à prendre avant de coder

| # | Question | Recommandation | Alternative |
|---|---|---|---|
| 1 | Attaque du héros | **Automatique** sur l'ennemi le plus proche à portée : commandes minimales, cohérent avec la bible | Touche dédiée (Espace / clic) pour plus de contrôle |
| 2 | Recrutement | **Reporté en phase 3** avec le village : il prend son sens avec la production à la base | Un captif à libérer dès le lot B |
| 3 | Rythme | **Lot A seul, puis validation**, puis lot B | Lots A et B enchaînés |
| 4 | Réapparition des sangliers | Oui, lente, hors du champ de la caméra : de quoi ramasser pendant les tests | Non : zone vidée définitivement |

## Points techniques et compromis

- **Trace de pas plutôt que pathfinding** : les alliés passent exactement là où le héros est passé, donc toujours par un chemin valide (escaliers, ponts). C'est simple et robuste. Un `AStarGrid2D` construit sur `MapData` reste possible plus tard pour des ordres du type « allez là-bas ».
- **Couches de collision** à ajouter : `ennemis`, `zones_de_coup`, `butin`. Les personnages restent dans `World.add_entity()` pour le tri en profondeur.
- **Performance** : un groupe de 4 et une dizaine d'ennemis ne posent aucun problème. Les grandes armées des phases suivantes demanderont une simulation plus légère (bible : « simulation d'ennemis simplifiée »).
