# INCR-AGE — Suivi du projet

**État : phases 1 et 2 validées (tags `phase-1`, `phase-2a`, `phase-2b`) ; phase 3 : lot 3A validé (tag `phase-3a`), lot 3B en cours, lot 3C non commencé. Plans : `docs/PHASE_2_PLAN.md`, `docs/PHASE_3_PLAN.md`.**
Titre du jeu non choisi : « INCR-AGE » est le nom du dossier, pas un titre.

## Lancer et tester

- Jeu : double-clic sur `lancer_jeu.bat`. Éditeur : `lancer_jeu.bat editeur`.
- Ou à la main : Godot 4.7.2 → Importer → `project.godot` → F5.
- Godot a été installé par `winget install GodotEngine.GodotEngine` (4.7.2 stable).
- Contrôles : ZQSD, WASD ou flèches pour se déplacer ; molette pour zoomer ; F11 pour le plein écran ; Échap pour quitter.
- Couper les effets d'ambiance : lancer avec `-- --no-fx`, ou passer `ambient_effects` à `false` dans `scripts/autoload/game_settings.gd`.
- Combat : rien à presser. Le héros et ses compagnons frappent seuls les ennemis à portée ; le joueur choisit où se battre par ses déplacements. `-- --no-hitstop` coupe la micro-pause d'impact.
- Améliorations : s'approcher du feu de camp ouvre le panneau ; cliquer (ou toucher) une ligne, ou touches 1 à 4. Un repère doré flotte au-dessus du feu quand un achat est possible.

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
| Alliés | Suivi de la **trace de pas** du héros (pas de pathfinding), colonne par deux (±8 px, seulement s'il y a la place), place mémorisée sur la trace, trot de rattrapage en cas de retard, point visé 16 px en avant ; regroupement derrière le héros à l'arrêt | Passent toujours par un chemin valide (escaliers, ponts) ; simple et robuste. Pathfinding (`AStarGrid2D`) gardé pour de futurs ordres. |
| Combat | Attaque automatique (`AutoAttack`) : cible la plus proche à portée et en vue, geste visible puis impact différé (une cible qui s'écarte esquive) ; base `Combatant` commune (vie, recul, flash, barre de vie) | Commandes inchangées ; le placement compte. Les compétences actives futures seront des composants voisins d'`AutoAttack` utilisant `receive_hit()`. |
| Laisses | Alliés : n'engagent qu'un ennemi à moins de 110 px du héros, le lâchent au-delà de 150 px. Sangliers : jamais à plus de 7 tuiles de leur repaire | Aucune poursuite sans fin ; le joueur n'est jamais entraîné loin malgré lui. |
| Données | Caractéristiques des unités dans `data/units/*.tres` (`UnitStats`), ressources dans l'autoload `GameState` | Réglables sans code ; base de la future sauvegarde. |
| Progression | Catalogue `Upgrades` (coûts exponentiels doux, effets calculés), niveaux dans `GameState.upgrades`, effets appliqués par `UpgradeEffects` | Achats accessibles dès 2 ou 3 combats ; stockage prêt pour la sauvegarde 3C. |

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

## Terminé (phase 2, lot B)

- Sangliers (jeune / grand), 11 repaires (`g` / `G` sur la carte), réapparition après 45 s hors de vue et loin du héros.
- Comportement : errance, détection, charge préparée bien lisible (tête basse, œil rouge, poussière, visée figée avant le départ : on peut l'esquiver), arrêt net à l'impact puis étourdissement (moment pour riposter), fuite quand il faiblit, retour au repaire.
- Héros et alliés : attaque automatique (arc de coup, élan, étincelle, recul, flash blanc, chiffres de dégâts, micro-pause et secousse légère sur les coups forts) ; alliés répartis en éventail autour de l'ennemi, du côté du héros.
- Vie : barres au-dessus des unités blessées (or pour le héros), régénération après 4 s sans coup. Allié K.O. : à terre 8 s puis relevé à 50 %. Héros K.O. : fondu et retour de tout le groupe au campement, sans perte.
- Butin : viande (vivres), peau et os (matériaux), dent gravée rare (savoir) ; jaillit, rebondit, puis aimanté vers le membre du groupe le plus proche (96 px) ; compteur discret en haut à droite.

## Terminé (phase 3, lot 3A)

- Quatre améliorations au feu de camp : RECRUE (3 à 8 compagnons), FORCE (+15 % de dégâts par niveau, 5 niveaux), AIMANT (+24 px de ramassage, 4 niveaux), VIGUEUR (+15 % de vie, 4 niveaux). Coûts en vivres et matériaux, savoir pour les niveaux élevés de FORCE et VIGUEUR. Détail : `docs/PHASE_3_PLAN.md`.
- Panneau du feu de camp en pixel art (police complète générée : majuscules, chiffres, % /) : icône, nom, niveau, coût ; ressources manquantes en rouge, lignes non abordables atténuées ; survol, clic, toucher, touches 1 à 4 (rangée du haut ou pavé numérique).
- Retours : ligne qui brille (ou tremble en rouge si refusé), compteur qui baisse en rouge, recrue qui surgit près du feu dans une gerbe d'étincelles, lueur dorée (FORCE) ou verte avec soin (VIGUEUR) sur tout le groupe, cercle du nouveau rayon (AIMANT), repère doré au-dessus du feu.
- Huit apparences de compagnons ; marche en colonne par deux ; éventail de combat adapté au nombre ; trot de rattrapage.

## Vérifications réellement effectuées

- Lancement sans erreur de script ; captures d'écran en jeu de chaque région (campement, ponts, lac, plateaux, prairies, étang).
- Déplacements scriptés : montée et descente d'escalier ; arrêt contre l'eau, la forêt, le pied de falaise et les rebords ouest, nord et est d'un plateau.
- Mode sans effets (`--no-fx`) : lancement sans erreur.
- 60 FPS (synchro verticale) en vue large au-dessus de la forêt, environ 7 600 nœuds.
- Lot A : tour complet piloté (colline nord, pont nord, grand plateau est, pont est, étang, lac, éperon sud-ouest, retour au camp, 150 s) : héros jamais bloqué, **0 replacement forcé** des alliés, écart maximal 81 px. Captures : groupe au camp, en file sur le pont et dans l'escalier, arrêt sur le pont.
- Lot B : combats en jeu près des repaires de la prairie est (charge, coups du héros et des alliés, mort, butin aimanté et compté), K.O. du héros et retour au camp (groupe replacé autour de lui), tour complet de la carte avec ennemis (héros jamais bloqué ; deux alliés mis K.O. par le grand sanglier puis replacés comme prévu), retour de l'échelle de temps à 1 après les micro-pauses, 60 FPS. Captures : mêlée, éventail des alliés, butin, compteur.
- Lot 3A : panneau capturé au camp (achats possibles, puis après achats) ; achats simulés de toutes les améliorations (coûts déduits, effets visibles) ; tour complet de la carte à 8 compagnons : 4 replacements forcés, tous après les combats du couloir ouest (contre 67 avant le correctif de rattrapage) ; tour à 3 compagnons sans régression (1 replacement) ; combat à 8 avec FORCE 2 : sanglier abattu en moins d'une seconde, butin ramassé ; 60 FPS, environ 7 780 nœuds.
- **Non vérifié** : sensations de contrôle, de caméra et de combat par un humain, clic réel dans le panneau (achats testés par commande), toucher sur écran tactile, écran 120/144 Hz, plein écran.

## En cours

- Lot 3B : évolution automatique du campement.

## Problèmes connus / limites

- Les diagonales (chemins, rivière, flancs des grands plateaux) gardent un aspect « en marches » dû à la grille de 32 px. Pistes : tuiles diagonales, ou forme du terrain sur une sous-grille de 16 px.
- Petites faces de falaise en gradins aux coins des plateaux arrondis.
- Environ 5 500 arbres en sprites : correct sur PC. Pour le Web ou le mobile, prévoir MultiMesh ou des arbres en tuiles.
- La carte `.txt` et `props.json` ne sont pas des ressources Godot. À l'export, ajouter `*.txt, *.json` aux filtres de fichiers non-ressources.
- Pas d'exécutable exporté : les modèles d'export Godot ne sont pas installés.
- À 8 compagnons, les combats contre les jeunes sangliers deviennent très courts : l'équilibrage des ennemis devra suivre la croissance de l'armée (phases suivantes).
- Équilibrage provisoire (vie, dégâts, cadences) : à ajuster après tes essais, directement dans `data/units/*.tres`.
- Le butin non ramassé reste au sol indéfiniment (pas encore de disparition).

## Prochaines étapes

1. Lot 3B (après validation) : évolution automatique du campement en trois états.
2. Lot 3C : sauvegarde locale fiable.
3. Ajustements d'équilibrage au fil des essais (`data/units/*.tres`, `scripts/progression/upgrades.gd`).
4. Plus tard : manette (les actions `move_*` et `zoom_*` sont déjà abstraites).

## Reprendre le travail (session suivante)

1. Lire ce fichier et `git log --oneline`. Dépôt GitHub : https://github.com/adrienmazas33-create/INCR-AGE (branche `main`, tags `phase-1`, `phase-2a`, `phase-2b`, `phase-3a`). Pousser après chaque étape validée.
2. Architecture :
   - `scenes/main.tscn` : assemble `World`, `Hero`, `Party`, `EnemySpawner`, `Hud` (avec `CampPanel`), `UpgradeEffects` (créés en code) et `GameCamera` ; gère le retour au camp.
   - `scenes/world/` : `world.gd` charge la carte. `scripts/world/` contient `MapData` (lecture et requêtes), `TerrainBuilder` (tuiles et collisions), `PropSpawner` (décors) et `TileIds` (disposition des atlas).
   - `scenes/characters/` : `hero.*`, `follower.*`, `party.gd` (trace et places du groupe), `character_sprite.gd` (animation commune). `scenes/camera/game_camera.*`, `scenes/props/` (feu, papillon).
   - Combat : `scripts/combat/` (`UnitStats`, `Health`, `Combatant`, `AutoAttack`, `Targeting`, `HealthBar`), `scenes/enemies/boar.*`, `scripts/world/enemy_spawner.gd`, `scenes/loot/pickup.gd`, `scenes/fx/`, `scenes/ui/hud.gd`, `scripts/ui/pixel_text.gd`. Autoloads : `GameSettings`, `GameState`, `CombatFx`.
   - Progression : `scripts/progression/` (`Upgrades`, `UpgradeEffects`), `scenes/ui/camp_panel*.gd`.
   - Les futurs PNJ s'ajoutent au monde par `World.add_entity()` pour être triés en profondeur.
3. Commandes utiles (depuis la racine, `godot` = exécutable console de Godot) :
   - Régénérer l'art : `godot --headless --path . --script res://tools/generate_art.gd`, puis `godot --headless --path . --import`.
   - Vérifier la carte : `godot --headless --path . --script res://tools/check_map.gd -- --preview=apercu.png`.
   - Réesquisser la carte (**écrase les retouches manuelles**) : `godot --headless --path . --script res://tools/draft_map.gd`.
   - Capture ou déplacement scripté : `godot --path . -- --at=58,40 --zoom=0 --walk=move_up:1.5 --capture=C:/chemin/shot.png`.
   - Parcours piloté (plus court chemin case par case) avec bilan du groupe : `godot --path . -- --route=58,17/79,30/99,20/80,56/58,58`.
   - Tests de combat : `--hero-hp=6` (forcer un K.O.) ; le bilan affiche ressources, PV et coups portés par le héros.
   - Achats : `--give=food:30,materials:10,knowledge:2 --buy=recruit,damage` (achats exécutés au lancement).
