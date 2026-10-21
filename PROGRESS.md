# INCR-AGE — Suivi du projet

**État : phase 1 validée (tag `phase-1`) ; phase 2, lot A (trois alliés qui suivent) validé (tag `phase-2a`). Prochaine étape : lot B. Plan : `docs/PHASE_2_PLAN.md`.**
Titre du jeu non choisi : « INCR-AGE » est le nom du dossier, pas un titre.

## Lancer et tester

- Jeu : double-clic sur `lancer_jeu.bat`. Éditeur : `lancer_jeu.bat editeur`.
- Ou à la main : Godot 4.7.2 → Importer → `project.godot` → F5.
- Godot a été installé par `winget install GodotEngine.GodotEngine` (4.7.2 stable).
- Contrôles : ZQSD, WASD ou flèches pour se déplacer ; molette pour zoomer ; F11 pour le plein écran ; Échap pour quitter.
- Couper les effets d'ambiance : lancer avec `-- --no-fx`, ou passer `ambient_effects` à `false` dans `scripts/autoload/game_settings.gd`.

## Choix techniques

| Sujet | Choix | Raison / compromis |
|---|---|---|
| Moteur | Godot 4.7.2, GDScript, rendu *GL Compatibility* | Le plus portable (Web, mobile plus tard). |
| Pixel art | Résolution logique 640 x 360, étirement `canvas_items` + `expand`, filtre *nearest*, accrochage des transformations au pixel | Rendu net à toute taille de fenêtre. |
| Zoom | Paliers où un pixel du jeu couvre un nombre **entier** de pixels écran (720p : 3 paliers ; 1080p : 4) | Aucune déformation des pixels une fois le zoom stabilisé. |
| Fluidité | Physique 60 Hz + interpolation physique ; la caméra se met à jour au même rythme que le héros | Mouvement lisse sur écrans > 60 Hz sans décalage héros/caméra. |
| Carte | Fichier ASCII `data/maps/prototype.txt` (légende : `data/maps/README.md`), construit au lancement | Lisible et éditable en texte, prêt pour une génération semi-procédurale future. Compromis : la carte n'apparaît pas dans l'éditeur Godot. |
| Transitions de sol | Auto-tuiles 8 voisins (256 variantes générées) au lieu des « terrains » Godot | Rendu maîtrisé, aucune configuration manuelle dans l'éditeur. |
| Relief | Plateaux praticables ; falaise de 2 tuiles sous le bord sud, rebords rocheux ailleurs ; accès par escaliers | Hauteur lisible en vue 3/4, zones infranchissables nettes. |
| Collisions | Rectangles fusionnés par rangée (eau, forêt, falaises) + bandes de 6 px sur les rebords + emprise au pied des objets | Peu de formes ; on longe les obstacles sans accrocher. |
| Profondeur | Conteneur `Entities` trié en Y ; arbres de forêt regroupés par rangée | Le héros passe derrière les arbres, huttes et rochers. |
| Art | 100 % procédural et original (`tools/generate_art.gd`), déterministe | Aucun asset externe ni payant ; remplaçable plus tard par de vrais sprites. |
| Alliés | Suivi de la **trace de pas** du héros (pas de pathfinding), place mémorisée sur la trace, point visé 16 px en avant ; regroupement derrière le héros à l'arrêt | Passent toujours par un chemin valide (escaliers, ponts) ; simple et robuste. Pathfinding (`AStarGrid2D`) gardé pour de futurs ordres. |

## Terminé (phase 1)

- Projet Godot, Git, `.gitignore`, structure de dossiers.
- Art provisoire : herbe (variantes, fleurs, touffes, cailloux), chemins, sable, eau, sous-bois, plateaux, falaises, escaliers, ponts, nénuphars ; héros (repos 2 images, marche 4 images, face / dos / profil) ; arbres feuillus (3), pins (2), buissons, rochers, 2 huttes, feu de camp animé, caisse, rondin, tas de bois, séchoir, menhir, totem, roseaux, papillons.
- Carte fixe 120 x 100 conçue à la main :
  - campement central (feu, 3 huttes, totem, caisses, rondins, bois, séchoir) ;
  - forêts denses, rivière nord-sud avec 2 ponts, lac avec plage et îlot ;
  - 3 plateaux rocheux avec escaliers et menhirs en points de vue ;
  - grande prairie est (future zone de combats), prairie sud-est ;
  - clairière ouest, étang caché au nord-ouest.
- Vérification d'accessibilité : 4 908 des 4 915 cases praticables sont atteignables depuis le campement. Les 7 restantes sont des cases isolées par des décors, sans incidence.
- Héros : 8 directions, accélération et freinage vifs, virage franc, orientation et animation cohérentes, ombre portée.
- Caméra : suivi ferme avec léger regard vers l'avant, zoom molette progressif, arrêt net aux bords de la carte.
- Ambiance : feu animé (flammes, halo, fumée), scintillement de l'eau (shader), papillons, variations de végétation. Tout se coupe via `GameSettings`.
- Script de lancement `lancer_jeu.bat`.

## Terminé (phase 2, lot A)

- Trois alliés aux looks distincts (roux en peau de loup, bandeau rouge, jeune imberbe), mêmes animations que le héros (`CharacterSprite`, partagé).
- Suivi en file sur la trace du héros, arrivée douce, séparation entre membres ; ils heurtent le décor mais jamais le héros ni entre eux.
- À l'arrêt : petit groupe derrière le héros, tourné vers lui ; une place derrière un mur ou au-dessus de l'eau est écartée.
- Filet de sécurité : un allié coincé ou distancé (> 12 tuiles) est replacé sur la trace, hors du champ de la caméra si possible.

## Vérifications réellement effectuées

- Lancement sans erreur de script ; captures d'écran en jeu de chaque région (campement, ponts, lac, plateaux, prairies, étang).
- Déplacements scriptés : montée et descente d'escalier ; arrêt contre l'eau, la forêt, le pied de falaise et les rebords ouest, nord et est d'un plateau.
- Mode sans effets (`--no-fx`) : lancement sans erreur.
- 60 FPS (synchro verticale) en vue large au-dessus de la forêt, environ 7 600 nœuds.
- Lot A : tour complet piloté (colline nord, pont nord, grand plateau est, pont est, étang, lac, éperon sud-ouest, retour au camp, 150 s) : héros jamais bloqué, **0 replacement forcé** des alliés, écart maximal 81 px. Captures : groupe au camp, en file sur le pont et dans l'escalier, arrêt sur le pont.
- **Non vérifié** : sensations de contrôle et de caméra par un humain, comportement sur écran 120/144 Hz, plein écran, lisibilité du héros dans le groupe à juger en jeu.

## En cours

- Rien. Lot A validé ; lot B à lancer sur demande.

## Problèmes connus / limites

- Les diagonales (chemins, rivière, flancs des grands plateaux) gardent un aspect « en marches » dû à la grille de 32 px. Pistes : tuiles diagonales, ou forme du terrain sur une sous-grille de 16 px.
- Petites faces de falaise en gradins aux coins des plateaux arrondis.
- Environ 5 500 arbres en sprites : correct sur PC. Pour le Web ou le mobile, prévoir MultiMesh ou des arbres en tuiles.
- La carte `.txt` et `props.json` ne sont pas des ressources Godot. À l'export, ajouter `*.txt, *.json` aux filtres de fichiers non-ressources.
- Pas d'exécutable exporté : les modèles d'export Godot ne sont pas installés.
- Alliés en file indienne pendant la marche : fidèle à « ils suivent », mais moins « troupe » qu'un groupe en formation (à juger).

## Prochaines étapes

1. Phase 2, lot B (après validation du lot A) : sangliers, combat automatique, butin magnétique, ressources (étape 1, sans recrutement).
2. Phase 3 pressentie : village qui évolue, recrutement, premières améliorations, sauvegarde.
3. Plus tard : manette (les actions `move_*` et `zoom_*` sont déjà abstraites).

## Reprendre le travail (session suivante)

1. Lire ce fichier et `git log --oneline`. Dépôt GitHub : https://github.com/adrienmazas33-create/INCR-AGE (branche `main`, tags `phase-1`, `phase-2a`). Pousser après chaque étape validée.
2. Architecture :
   - `scenes/main.tscn` : assemble `World`, `Hero`, `Party` (créé en code) et `GameCamera`.
   - `scenes/world/` : `world.gd` charge la carte. `scripts/world/` contient `MapData` (lecture et requêtes), `TerrainBuilder` (tuiles et collisions), `PropSpawner` (décors) et `TileIds` (disposition des atlas).
   - `scenes/characters/` : `hero.*`, `follower.*`, `party.gd` (trace et places du groupe), `character_sprite.gd` (animation commune). `scenes/camera/game_camera.*`, `scenes/props/` (feu, papillon).
   - Les futurs PNJ s'ajoutent au monde par `World.add_entity()` pour être triés en profondeur.
3. Commandes utiles (depuis la racine, `godot` = exécutable console de Godot) :
   - Régénérer l'art : `godot --headless --path . --script res://tools/generate_art.gd`, puis `godot --headless --path . --import`.
   - Vérifier la carte : `godot --headless --path . --script res://tools/check_map.gd -- --preview=apercu.png`.
   - Réesquisser la carte (**écrase les retouches manuelles**) : `godot --headless --path . --script res://tools/draft_map.gd`.
   - Capture ou déplacement scripté : `godot --path . -- --at=58,40 --zoom=0 --walk=move_up:1.5 --capture=C:/chemin/shot.png`.
   - Parcours piloté (plus court chemin case par case) avec bilan du groupe : `godot --path . -- --route=58,17/79,30/99,20/80,56/58,58`.
