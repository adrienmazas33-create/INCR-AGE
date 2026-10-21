# INCR-AGE — Suivi du projet

**État : identification du héros validée et publiée (tag `hero-id`). Amélioration VITESSE reportée. Priorités suivantes revues dans `docs/ROADMAP.md` : audio, art du monde (zone témoin au camp), troupes plus organiques, puis carte du monde.**
**Validé : phases 1, 2 (lots A et B), 3 (lots 3A, 3B, 3C) — tags `phase-1`, `phase-2a`, `phase-2b`, `phase-3a`, `phase-3b`, `phase-3c`. Plans : `docs/PHASE_2_PLAN.md`, `docs/PHASE_3_PLAN.md`.**
Titre du jeu non choisi : « INCR-AGE » est le nom du dossier, pas un titre.

## Lancer et tester

- Jeu : double-clic sur `lancer_jeu.bat`. Éditeur : `lancer_jeu.bat editeur`.
- Ou à la main : Godot 4.7.2 → Importer → `project.godot` → F5.
- Godot a été installé par `winget install GodotEngine.GodotEngine` (4.7.2 stable).
- Contrôles : ZQSD, WASD ou flèches pour se déplacer ; molette pour zoomer ; F11 pour le plein écran ; Échap pour quitter.
- Couper les effets d'ambiance : lancer avec `-- --no-fx`, ou passer `ambient_effects` à `false` dans `scripts/autoload/game_settings.gd`.
- Combat : rien à presser. Le héros et ses compagnons frappent seuls les ennemis à portée ; le joueur choisit où se battre par ses déplacements. `-- --no-hitstop` coupe la micro-pause d'impact.
- Améliorations : s'approcher du feu de camp ouvre le panneau ; cliquer (ou toucher) une ligne, ou touches 1 à 4. Un repère doré flotte au-dessus du feu quand un achat est possible.
- Évolution du camp : automatique avec la prospérité (niveaux achetés) ; le stade et la progression s'affichent au pied du panneau du feu.
- Sauvegarde : automatique, rien à faire. La partie reprend au lancement là où elle s'était arrêtée.
  - Fichier : `%APPDATA%\Godot\app_userdata\INCR-AGE (prototype)\save.json`, avec sa copie de secours `save.bak.json`.
  - Repartir de zéro : supprimer ces fichiers, jeu fermé.

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
| Campement | Trois stades (CAMPEMENT, TRIBU à 3 niveaux achetés, VILLAGE à 8) décrits en données dans `CampVillage` ; stade calculé à partir des améliorations | Aucun placement par le joueur ; rien ne progresse hors du jeu ; la sauvegarde 3C reconstruit le camp sans donnée en plus. |
| Sauvegarde | Autoload `SaveGame` : JSON versionné dans `user://`. Écriture dans un temporaire relu et vérifié, l'ancienne version devient la copie de secours, puis renommage. Lecture : principale, puis temporaire, puis secours, avec validation et bornage de chaque champ | Fonctions natives de Godot uniquement ; une version complète existe à tout instant ; un fichier abîmé ou trop récent est mis de côté, jamais écrasé. |

## Direction artistique : graphismes PROVISOIRES

- Tout le pixel art actuel (terrain, personnages, ennemis, décors, effets, interface, police) est **provisoire**. Il est généré par code (`tools/generate_art.gd`) pour prototyper vite, sans asset externe.
- Une **refonte artistique est prévue plus tard**, pour atteindre le rendu d'un jeu indépendant professionnel (références : When Chests Rain Tons of Loot, Pikmin, illustrations de la bible créative).
- La refonte **ne remet pas en cause les mécaniques validées** : déplacements, caméra, suivi du groupe, combat automatique, butin, améliorations, évolution du camp.
- Points d'appui pour remplacer l'art sans toucher au gameplay :
  - même découpage des planches (personnages 6 x 3 images de 32 px, sangliers 8 images de 44 x 30) ;
  - atlas `props.png` + `props.json` (rectangle et point d'ancrage par nom) ;
  - tuiles 32 px et dispositions décrites dans `scripts/world/tile_ids.gd` ;
  - auto-tuiles indexées par masque de 8 voisins (256 variantes).
- Chantier artistique engagé : cadrage dans `docs/ART_DIRECTION_PLAN.md`, passe visuelle 1 décrite ci-dessous. Le reste de l'art reste provisoire.

## Chantier artistique — passe visuelle 1 (validée, tag `art-pass-1`)

Ciblée sur la tranche préhistorique, **sans aucun changement de mécanique** : mêmes collisions, portées, vitesses, règles et formats de planches.

- **Héros** : proportions plus naturelles (environ 25 px de haut, tête d'environ un tiers au lieu de la moitié), tunique portée sur une épaule. **Signature : cape de peau de bête dorée et massue à tête de pierre.**
- **Compagnons** : même gabarit, **lance à pointe de silex** qui dépasse de la silhouette (une troupe lisible à 8). Les 8 apparences sont conservées.
- **Villageois** : mêmes nouvelles proportions, sans arme.
- **Commun aux personnages** : ombrage plus riche, grain de fourrure fixé au corps, **contour sélectif** (teinté selon la matière voisine au lieu d'un brun uniforme).
- **Sanglier** :
  - tête nettement séparée (pli du cou, joue claire, groin rosé avec narine, défense blanche), œil avec reflet, oreille dressée ;
  - crinière aux pointes claires, croupe éclairée, sabots ;
  - œil rouge pendant la préparation de la charge.
- **Flash d'impact** : il éclaircit sans effacer la silhouette, les contours sombres restent sombres (shader `flash.gdshader`).
- **Feu de camp** (petit et grand) : langues qui s'enroulent, braises qui montent, bouts de bûches incandescents, pierres éclairées par-dessus, **halo posé au sol en ellipse tramée** au lieu d'un disque.
- **Combat** :
  - arc de coup épais, **doré pour le héros**, blanc pour les compagnons ;
  - étincelle en étoile avec anneau (4 images) ;
  - **nuage de poussière** à la mort d'un ennemi.
- **Butin** : icônes plus contrastées, **scintillement** périodique au sol, **aura violette** pour le savoir, éclats colorés au ramassage.
- **Moments forts** : **rayons dorés** autour du feu à chaque achat ; au changement de stade du camp, grands rayons et **bref éclat de l'écran**, en plus du ruban d'annonce.
- **Huttes** : chaume en rangs effilochés (hutte conique), panneaux cousus et pierres de lestage (dôme), portes profondes encadrées de perches liées.
- **Interface** : un même **cadre en cuir et bois cloutés** (`scripts/ui/ui_frame.gd`) pour le panneau du feu, le compteur de ressources et le ruban d'annonce.
- **Barres de vie** : affichées seulement juste après un coup (2,5 s) ou quand la vie est sous la moitié. Le groupe de 8 n'est plus surmonté d'un empilement de barres.

**Encore provisoire** :
- tout le reste de l'art (terrain, végétation, décors secondaires, maison longue, palissade, police) ;
- l'absence d'animation d'attaque dédiée (élan seulement) ;
- le grand sanglier, simple variante de couleur.

Voir les priorités 2 et 3 du plan artistique.

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

## Terminé (phase 3, lot 3B)

- Stade 2 « TRIBU » : deux huttes, séchoir à viande, paniers de réserve, deux villageois.
- Stade 3 « VILLAGE » : maison longue, nouvelle hutte, palissade à l'est, torches à l'entrée nord, bannière, panier, grand feu central, deux villageois de plus.
- Transition : bandeau « LA TRIBU GRANDIT » / « LE VILLAGE PROSPERE », éléments qui apparaissent un à un (poussière, fondu, légère montée), grand feu dans une gerbe d'étincelles, villageois qui arrivent à pied par le sud.
- Villageois : décor animé sans collision ni combat, va-et-vient entre feu, huttes et réserves, pauses tournées vers le feu.
- Pied du panneau du feu : nom du stade et barre de progression vers le suivant.

## Terminé (phase 3, lot 3C)

- **Contenu enregistré** : ressources, niveaux d'amélioration, nombre de compagnons et stade du village (déduits des améliorations, enregistrés pour contrôle), dernière position valide du héros (aucune pendant un K.O.).
- **Sauvegardes automatiques** :
  - immédiatement après chaque achat, donc à chaque recrutement, amélioration ou évolution du village ;
  - 4 s après un gain de ressources (les ramassages sont regroupés) ;
  - à la relève au camp après un K.O. ;
  - toutes les 30 s (position du héros) ;
  - à la fermeture de la fenêtre et à la touche Échap ;
  - à la mise en arrière-plan (prévu pour le mobile).
- **Restauration au lancement**, avant la construction du groupe et du camp : bon nombre de compagnons, village reconstruit à son stade sans rejouer l'animation, compteur à jour.
- **Position du héros** : acceptée seulement si elle est dans la carte et sur une case praticable, sinon point d'apparition. Une position recouverte depuis par un bâtiment est corrigée (repoussée hors de l'obstacle, ou point d'apparition).
- **Fichiers abîmés ou incompatibles** :
  - fichier illisible ou tronqué : mis de côté (`save.corrupt-….json`), la version suivante est chargée (temporaire, puis secours) ;
  - version plus récente que le jeu : mise de côté (`save.v99-….json`), nouvelle partie ;
  - champs aberrants : bornés ou ignorés (ressources négatives ou démesurées, niveaux hors limites, clés inconnues).
  - Aucun fichier n'est effacé.
- **Aucune progression jeu fermé** : la date d'enregistrement est purement informative.
- **Mode test** : `-- --save=<chemin>` utilise un autre fichier, `-- --no-save` n'écrit rien. Un lancement de l'outil de test (`--give`, `--buy`, `--at`, `--route`) n'écrit jamais dans la vraie sauvegarde, sauf si `--save` est indiqué.

## Vérifications réellement effectuées

- Lancement sans erreur de script ; captures d'écran en jeu de chaque région (campement, ponts, lac, plateaux, prairies, étang).
- Déplacements scriptés : montée et descente d'escalier ; arrêt contre l'eau, la forêt, le pied de falaise et les rebords ouest, nord et est d'un plateau.
- Mode sans effets (`--no-fx`) : lancement sans erreur.
- 60 FPS (synchro verticale) en vue large au-dessus de la forêt, environ 7 600 nœuds.
- Lot A : tour complet piloté (colline nord, pont nord, grand plateau est, pont est, étang, lac, éperon sud-ouest, retour au camp, 150 s) : héros jamais bloqué, **0 replacement forcé** des alliés, écart maximal 81 px. Captures : groupe au camp, en file sur le pont et dans l'escalier, arrêt sur le pont.
- Lot B : combats en jeu près des repaires de la prairie est (charge, coups du héros et des alliés, mort, butin aimanté et compté), K.O. du héros et retour au camp (groupe replacé autour de lui), tour complet de la carte avec ennemis (héros jamais bloqué ; deux alliés mis K.O. par le grand sanglier puis replacés comme prévu), retour de l'échelle de temps à 1 après les micro-pauses, 60 FPS. Captures : mêlée, éventail des alliés, butin, compteur.
- Lot 3A : panneau capturé au camp (achats possibles, puis après achats) ; achats simulés de toutes les améliorations (coûts déduits, effets visibles) ; tour complet de la carte à 8 compagnons : 4 replacements forcés, tous après les combats du couloir ouest (contre 67 avant le correctif de rattrapage) ; tour à 3 compagnons sans régression (1 replacement) ; combat à 8 avec FORCE 2 : sanglier abattu en moins d'une seconde, butin ramassé ; 60 FPS, environ 7 780 nœuds.
- Lot 3B : captures du passage au stade 2 (bandeau, éléments) et du stade 3 installé (village, villageois, grand feu, pied du panneau) ; tour complet de la carte au stade 3 avec 8 compagnons : héros jamais bloqué, 2 replacements forcés (après combats). Comparaison sans affichage entre stade 1 et stade 3 : pas d'écart notable. Les chiffres en millisecondes donnés à l'époque reposaient sur un indicateur erroné, retiré au lot 3C.
- **Performances absolues non fiables pendant ce lot** : l'ordinateur était sur batterie (processeur bridé) ; la version 3A, à 60 FPS lors de sa validation, ne tenait plus que 29 à 50 FPS dans les mêmes conditions. À revérifier sur secteur.
- Lot 3C, sur un fichier de test isolé, chaque scénario relancé dans le vrai jeu :
  - premier lancement sans sauvegarde : nouvelle partie normale ;
  - achats (recrues, FORCE) menant au stade TRIBU : fichier écrit tout de suite, avec copie de secours ;
  - relance : ressources, améliorations, 5 compagnons, camp au stade TRIBU sans animation (capture), position du héros à l'identique ;
  - déplacement puis fermeture : nouvelle position restaurée ;
  - **processus tué net** après des achats menant au stade VILLAGE : relance au stade 3 avec 6 compagnons ;
  - butin ramassé en combat puis processus tué : ressources retrouvées (sauvegarde différée de 4 s) ;
  - fichier principal corrompu : copie de secours chargée ;
  - écriture interrompue (principal absent, temporaire complet) : temporaire chargé ;
  - temporaire tronqué : copie de secours chargée ;
  - version 99 : mise de côté, nouvelle partie ;
  - valeurs aberrantes : bornées ;
  - position hors carte ou dans l'eau : point d'apparition ;
  - position dans la maison longue : héros repoussé sur une case libre.
- Performances (lot 3C), toujours sur batterie (secteur indisponible pendant la session) : **60 FPS de moyenne stable** au camp, au village avec 8 compagnons, et en vue large au-dessus de la forêt.
- **Validations humaines** : phase 1, lots 2A, 2B, 3A, 3B et 3C testés en jeu et validés par le porteur du projet (le 21/10/2026).
- **Passe visuelle 1** :
  - captures avant et après au camp et en combat, plus le passage au stade TRIBU (rayons et éclat) ; chaque planche vérifiée en aperçu agrandi ;
  - combat et butin inchangés (sanglier abattu, butin ramassé et compté) ;
  - tour complet de la carte : 2 replacements forcés (après combats), 60 FPS de moyenne ;
  - copie neuve des fichiers versionnés : import et lancement sans erreur.
  - **Validée** par le porteur du projet le 21/10/2026.
- **Indicateur du campement**, nouvelle partie sur un fichier de test isolé, captures lues :
  - prairie est (98,62), zoom 0 : flèche sur le bord gauche, 41 tuiles ;
  - plateau nord-est (100,17), zoom 1 : coin bas gauche, 57 tuiles ;
  - au nord du camp (58,63), zoom 1 : bord haut, 8 tuiles ;
  - zoom 2 au camp : feu visible, indicateur masqué ;
  - jamais sous le compteur, et le chiffre ne chevauche jamais la flèche ;
  - aucune erreur de script.
  - **Validé** par le porteur du projet le 22/10/2026.
- **Déplacement à la souris**, clics réels simulés (`--click`), fichier de test isolé :
  - montée sur le grand plateau par l'escalier (95,28 → 100,18) et redescente : arrivée à 2 px du clic, en 4,3 s et 4,7 s ;
  - traversée de la rivière par le pont (75,34 → 84,34) ;
  - camp au stade VILLAGE : contournement de la palissade et d'une hutte ajoutées par l'évolution du camp ;
  - clic au milieu de la rivière : refusé, croix rouge, héros immobile ;
  - clic sur une case de forêt en lisière : héros conduit à la case libre voisine ;
  - clic sur le panneau du camp, hors des boutons : aucun déplacement ;
  - nouveau clic en cours de route : la nouvelle destination remplace l'ancienne ;
  - touche de déplacement en cours de route : arrêt immédiat, sans reprise ;
  - trajets au milieu des sangliers : combat automatique inchangé (coups portés, sanglier abattu) ;
  - groupe de 3 et 8 compagnons : 0 replacement forcé ; parcours au clavier (`--route`) inchangé ; 60 FPS ;
  - construction de la grille de chemins : environ 105 ms au lancement.
  - **Validé** par le porteur du projet le 22/10/2026.
- **Identification du héros**, captures lues au zoom 2 :
  - au camp, avec 8 compagnons : anneau doré, bandeau et plume visibles, héros repérable aussitôt ;
  - en mêlée contre un sanglier près du repaire est (107,69) : héros caché en partie par les compagnons, chevron doré visible au-dessus de lui ;
  - avec 3 compagnons, hors combat : anneau net, pas de chevron ;
  - seule la planche `hero.png` change à la régénération de l'art ;
  - parcours au clavier inchangé (0 replacement forcé) ; aucune erreur de script.
- **Non vérifié** : vrai clic de souris et toucher sur écran tactile (clics simulés seulement), sensation de contrôle à la souris ; sensations de contrôle, de caméra et de combat par un humain, clic réel dans le panneau (achats testés par commande), toucher sur écran tactile, écran 120/144 Hz, plein écran.

## En cours

- **Identification du héros** (section 0 bis de `docs/ROADMAP.md`), validée le 22/10/2026 et publiée (tag `hero-id`) :
  - bandeau doré et plume à pointe d'or (`tools/generate_art.gd`, `_feather`) ;
  - anneau doré au sol, plus net quand le héros est entouré ; petit chevron au-dessus de la tête en combat seulement (`scenes/characters/hero_marker.gd`, ajouté par `Hero._ready`) ;
  - pas de lueur permanente ; collisions et mécaniques inchangées.
- **Amélioration VITESSE** : reportée, détail de ce qu'elle demandera dans `docs/ROADMAP.md`.
- **Déplacement à la souris** (lot 1 de `docs/ROADMAP.md`), validé le 22/10/2026 et publié (tag `mouse-move`) :
  - clic gauche sur le sol : le héros y va par un chemin praticable (escaliers, ponts, bâtiments du camp contournés) ;
  - un nouveau clic remplace le précédent ; une touche de déplacement l'interrompt (le clavier reste prioritaire) ;
  - repère bref au point cliqué : losange doré, ou croix rouge si l'endroit est inaccessible ;
  - un clic sur l'interface ne déplace jamais le héros ; compagnons, combat automatique et caméra inchangés ;
  - fichiers : `scripts/world/path_grid.gd` (A* sur `MapData`), `scenes/characters/click_mover.gd`, `scenes/fx/click_marker.gd` ; le héros reçoit une direction (`Hero.steer`), comme du clavier.
- Indicateur de direction du campement (`scenes/ui/camp_compass.gd`) : validé le 22/10/2026 et publié (tag `camp-compass`).

## Problèmes connus / limites

- Performances : jamais mesurées sur secteur (ordinateur sur batterie pendant les lots 3B et 3C). Au lot 3B, 26 à 50 FPS selon les moments ; au lot 3C, 60 FPS stables, toujours sur batterie.
- Sauvegarde :
  - une seule partie (pas d'emplacements multiples), ce qui suffit pour l'instant ;
  - les fichiers mis de côté (`save.corrupt-…`, `save.v…-…`) s'accumulent sans être nettoyés ;
  - un ennemi blessé et le butin au sol ne sont pas enregistrés, ce qui est voulu : seule la progression compte.
- Les diagonales (chemins, rivière, flancs des grands plateaux) gardent un aspect « en marches » dû à la grille de 32 px. Pistes : tuiles diagonales, ou forme du terrain sur une sous-grille de 16 px.
- Petites faces de falaise en gradins aux coins des plateaux arrondis.
- Environ 5 500 arbres en sprites : correct sur PC. Pour le Web ou le mobile, prévoir MultiMesh ou des arbres en tuiles.
- La carte `.txt` et `props.json` ne sont pas des ressources Godot. À l'export, ajouter `*.txt, *.json` aux filtres de fichiers non-ressources.
- Pas d'exécutable exporté : les modèles d'export Godot ne sont pas installés.
- À 8 compagnons, les combats contre les jeunes sangliers deviennent très courts : l'équilibrage des ennemis devra suivre la croissance de l'armée (phases suivantes).
- Les villageois traversent les décors (ils n'ont pas de collision) : invisible la plupart du temps, leurs trajets étant choisis dans les espaces dégagés.
- L'outil de parcours piloté calcule ses chemins sur la carte d'origine : il ignore les bâtiments ajoutés par l'évolution du camp (placés hors des chemins).
- Profilage à faire sur secteur avant le Web et le mobile (avec le profileur de l'éditeur Godot), notamment la forêt et le module `Party`.
- Équilibrage provisoire (vie, dégâts, cadences) : à ajuster après tes essais, directement dans `data/units/*.tres`.
- Le butin non ramassé reste au sol indéfiniment (pas encore de disparition).

## Prochaines étapes

1. **Feuille de route `docs/ROADMAP.md`**, ordre revu le 22/10/2026 (rien de tout cela n'est développé) :
   1. ambiance sonore : bruitages et musique rétro originale ;
   2. art du monde jouable : d'abord une zone témoin soignée autour du campement, en partant de vrais assets pixel art ;
   3. comportement plus organique des troupes ;
   4. carte du monde et mini-carte, plus tard.
   Également reportée : l'amélioration VITESSE. Un lot à la fois, avec arrêt pour validation.
2. **Chantier artistique** :
   - priorité 2 du plan (`docs/ART_DIRECTION_PLAN.md`), sur demande : animation d'attaque dédiée, diagonales du terrain, végétation proche du camp, éclairage d'ambiance, décors des stades TRIBU et VILLAGE.
3. Ajustements d'équilibrage au fil des essais : `data/units/*.tres`, `scripts/progression/upgrades.gd`. À 8 compagnons, les sangliers deviennent trop faciles.
4. Profilage des performances sur secteur ; pistes : forêt en MultiMesh ou en tuiles, calculs du groupe (`Party`).
5. Plus tard, selon la bible : compétences actives du héros, classes militaires, nouvelles époques.
6. Plus tard : manette et tactile. Les actions `move_*`, `zoom_*` et `buy_*` sont déjà abstraites, et les lignes du panneau acceptent clic et toucher.

## Reprendre le développement

À lire en début de session Claude Code. Cette section donne le contexte suffisant pour reprendre sans réanalyser tout le projet.

### 1. Où en est-on

- Dépôt : https://github.com/adrienmazas33-create/INCR-AGE, branche `main`. Chaque lot validé porte un tag : `phase-1`, `phase-2a`, `phase-2b`, `phase-3a`, `phase-3b`, `phase-3c`, `art-pass-1`, `camp-compass`, `mouse-move`, `hero-id`.
- Copie locale : `C:\Users\Adrien\OneDrive\Bureau\INCR-AGE`. Identité Git définie **uniquement pour ce dépôt** (`user.name` « Adrien »).
- Bible créative : `Bible_creative_Jeu_incremental_2D_V01.md` / `.docx`, dans les Téléchargements de l'utilisateur, **hors dépôt**.
- **Chantier artistique** : étape 1 et passe visuelle 1 faites et validées (tag `art-pass-1`). Prochaine étape, sur demande : priorité 2 de `docs/ART_DIRECTION_PLAN.md`. Ne pas commencer d'autre phase sans demande explicite.
- **Indicateur du campement** : validé et publié (tag `camp-compass`).
- **Feuille de route** `docs/ROADMAP.md` : déplacement à la souris (**fait et validé**, tag `mouse-move`) ; identification du héros (**faite et validée**, tag `hero-id`). Ensuite, **prévus et non développés** : audio, art du monde (zone témoin au camp), troupes organiques, carte du monde ; amélioration VITESSE reportée.

### 2. Méthode de travail attendue

- Échanges et documentation en français.
- Travail **par lots**, avec un arrêt pour validation après chaque lot. Ne jamais élargir le périmètre de soi-même.
- Après validation : commit, tag `phase-…`, `git push origin main --follow-tags`. Pousser **seulement** les lots validés, sans jamais forcer.
- Tester réellement ce qui est fait (outil de test, captures d'écran lues) et dire clairement ce qui reste à vérifier par un humain.
- Économiser les tokens : explorations ciblées, pas de refonte non demandée.
- Garder les mécaniques validées intactes : héros dirigé au clavier, combat automatique, compagnons en laisse autour du héros, commandes minimales.

### 3. Environnement

- Godot 4.7.2 stable, installé via winget. Exécutables :
  - console (pour les scripts et tests) : `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe` ;
  - jeu et éditeur : `…\Godot_v4.7.2-stable_win64.exe`.
- Le dossier `.godot/` n'est pas versionné. Sur un clone neuf, lancer d'abord `godot --headless --path . --import`, ou `lancer_jeu.bat`, qui le fait. Sans cet import, les `class_name` et les images ne sont pas encore connus.
- Pas de Python sur la machine : tout l'outillage est en GDScript (`tools/`), lancé avec `--headless --script`.
- L'ordinateur est souvent sur batterie : les FPS peuvent y varier. Se fier à la **moyenne** affichée par l'outil de test et vérifier l'alimentation : `(Get-CimInstance Win32_Battery).BatteryStatus` (1 = batterie, 2 = secteur).
- **Tests et sauvegarde** :
  - toujours lancer l'outil de test avec `--no-save` ou `--save=<fichier temporaire>`, pour ne jamais toucher la vraie partie du joueur ;
  - les arguments `--give`, `--buy`, `--at` et `--route` coupent déjà l'écriture d'eux-mêmes ;
  - attention : `--no-save` empêche l'écriture mais **lit** quand même la vraie sauvegarde (le joueur peut avoir des recrues). Pour un état de départ neutre, utiliser `--save=<fichier temporaire inexistant>`.
- **Art** :
  - les règles visuelles sont dans `docs/ART_DIRECTION_PLAN.md` (palette, rôles des couleurs, contour sélectif `_outline_tinted()`) ;
  - personnages : gabarits `BODY_*` et `LEGS_*`, cape `CAPE_*` et arme `_weapon()` dans `tools/generate_art.gd` ;
  - vérifier chaque planche avec un aperçu agrandi avant de la juger en jeu.

### 4. Architecture (essentiel)

- **Entrée** : `scenes/main.tscn` + `main.gd`. Crée en code `Hero`, `Party`, `EnemySpawner`, `Hud` (avec `CampPanel`), `UpgradeEffects` et `CampVillage`. Gère le K.O. du héros (fondu, retour au camp).
- **Autoloads** :
  - `GameSettings` : options d'effets ;
  - `GameState` : ressources `food` / `materials` / `knowledge`, `upgrades` (id → niveau), signaux `resource_changed` et `upgrade_bought` ;
  - `CombatFx` : étincelles, arcs, chiffres, micro-pause, secousse ;
  - `SaveGame` : sauvegarde et restauration (`scripts/autoload/save_game.gd`, détail au point 5).
- **Monde** : `scenes/world/world.gd`
  - `MapData` lit la carte ASCII `data/maps/prototype.txt` ;
  - `TerrainBuilder` construit les tuiles et les collisions ;
  - `PropSpawner` place les décors (catalogue `PROPS`, `make_prop()`) ;
  - `World.add_entity()` et `entity_layer()` servent au tri en profondeur ;
  - `camp_position` donne la position du feu.
- **Personnages** :
  - `Combatant` (`scripts/combat/combatant.gd`) : vie, recul, flash, lueur, barre de vie, `receive_hit()` ;
  - `Hero` et `Follower` en héritent ; `Boar` (`scenes/enemies/`) aussi ;
  - `AutoAttack` gère l'attaque automatique, `Targeting` la cible la plus proche en vue ;
  - les caractéristiques sont dans `data/units/*.tres` (`UnitStats`).
- **Groupe** : `scenes/characters/party.gd` (le module le plus délicat)
  - trace de pas du héros, suivi de trajectoire, colonne par deux, places au repos, éventail de combat, laisses (110 / 150 px) ;
  - trot de rattrapage, raccrochage à la partie récente de la trace, replacement de secours.
- **Progression** :
  - `scripts/progression/upgrades.gd` : catalogue, coûts, effets, `prosperity()`, `camp_stage()` ;
  - `UpgradeEffects` : application en jeu et retours visuels ;
  - `scenes/ui/camp_panel*.gd` : panneau du feu ;
  - `scripts/world/camp_village.gd` : stades du camp, en données ;
  - `scenes/characters/villager.gd` : villageois.
- **Art** : `tools/generate_art.gd`, déterministe. Après modification, relancer le générateur puis `--import`. Les nouveaux sprites de décor s'ajoutent **à la fin** de la liste de `_gen_props()`, pour ne pas décaler l'atlas.

### 5. Sauvegarde (lot 3C) : fonctionnement

- **Fichiers** dans `user://`, soit `%APPDATA%\Godot\app_userdata\INCR-AGE (prototype)\` :
  - `save.json` : la sauvegarde principale ;
  - `save.json.tmp` : écriture en cours ;
  - `save.bak.json` : version précédente ;
  - fichiers mis de côté : `save.corrupt-<horodatage>.json`, `save.v<n>-<horodatage>.json`.
- **Format** (version 1) : `version`, `saved_at` (informatif), `resources`, `upgrades` (id → niveau), `companions` et `camp_stage` (déduits, pour contrôle), `hero` ({x, y} ou null).
- **Faire évoluer le format** :
  - incrémenter `FORMAT_VERSION` ;
  - compléter `_migrate()` pour convertir les anciennes versions ;
  - un fichier d'une version plus récente que le jeu est toujours mis de côté, jamais écrasé.
- **Ordre au lancement** (`main.gd`) :
  - `SaveGame.restore()` remplit `GameState` sans déclencher d'effets ;
  - création du héros (position validée), du groupe (nombre de compagnons d'après les améliorations) et du camp (`CampVillage` construit le stade sans animation) ;
  - `SaveGame.start()` active ensuite les sauvegardes automatiques ;
  - un contrôle différé replace le héros s'il est dans un obstacle.
- **Déclencheurs** : signal `upgrade_bought` (immédiat), `resource_changed` (différé de 4 s), relève au camp, toutes les 30 s, fermeture de la fenêtre ou Échap, mise en arrière-plan.
- **Ajouter une donnée à sauvegarder** : l'écrire dans `_snapshot()`, la valider et la borner dans `_apply()`, et prévoir une valeur par défaut pour les anciens fichiers.

### 6. Pièges déjà rencontrés (à ne pas refaire)

- **Autoload** : un autoload qui précharge (`preload`) une image plante au premier import d'un clone neuf. Charger à la demande, comme `CombatFx` et `PixelText`.
- **Bash et heredoc** : un long heredoc contenant `'` peut faire échouer la commande bash entière ; utiliser l'outil d'édition.
- **cmd (`.bat`)** : le joker `*` ne fonctionne pas dans un nom de dossier d'une boucle `for` ; il faut un `for /d` imbriqué. Les `.bat` sont en fins de ligne CRLF (voir `.gitattributes`).
- **Suivi du groupe** :
  - ne jamais viser la place finale en ligne droite (falaises, escaliers) ;
  - la trace repasse sur elle-même lors des allers-retours, il faut donc privilégier les points récents ;
  - sans trot, un retard ne se rattrape jamais.
- **Physique** : les nœuds déplacés dans `_process` (villageois, papillons) doivent désactiver l'interpolation physique.
- **Outil de test** : le parcours piloté (`--route`) ignore les bâtiments ajoutés par l'évolution du camp.

### 7. Commandes utiles

Depuis la racine du dépôt, `godot` désigne l'exécutable console.

- Lancer le jeu : `lancer_jeu.bat` ; l'éditeur : `lancer_jeu.bat editeur`.
- Contrôle sans affichage : `godot --headless --path . --quit-after 300`, sans aucune ligne `ERROR` attendue.
- Régénérer l'art : `godot --headless --path . --script res://tools/generate_art.gd`, puis `godot --headless --path . --import`.
- Vérifier la carte : `godot --headless --path . --script res://tools/check_map.gd -- --preview=apercu.png`.
- Réesquisser la carte (**écrase les retouches manuelles**) : `godot --headless --path . --script res://tools/draft_map.gd`.
- **Outil de test** : arguments placés après `--`, bilan affiché en console. Combinables :
  - `--at=x,y` : placer le héros sur une case ;
  - `--zoom=n` : choisir le palier de zoom ;
  - `--walk=move_up:1.5` : déplacement au clavier simulé ;
  - `--route=58,17/79,30/58,58` : parcours piloté par plus court chemin ;
  - `--click=100,18/s60,120:0.5` : vrais clics de souris, sur une case (`x,y`) ou un point d'écran en pixels logiques (`sx,y`) ; `:s` n'attend que s secondes, sinon l'outil attend l'arrêt du héros. La case doit être visible à l'écran ;
  - `--give=food:30,materials:10,knowledge:2` : donner des ressources ;
  - `--buy=recruit,damage` : acheter au lancement ;
  - `--hero-hp=6` : forcer un K.O. ;
  - `--settle=s` : durée d'attente avant le bilan ;
  - `--capture=C:/chemin/image.png` : capture d'écran ;
  - `--no-fx`, `--no-hitstop` : couper les effets.
  - `--save=<chemin>` ou `--no-save` : choisir le fichier de sauvegarde, ou n'en écrire aucun ;
  - le bilan donne la position du héros, les FPS (instantané et moyenne), les écarts et replacements du groupe, les ressources, les améliorations et le nombre d'ennemis ;
  - en fin d'essai, l'outil simule une vraie fermeture de fenêtre, donc la sauvegarde de sortie est déclenchée.
- **Tour de non-régression** : `--route=58,17/79,30/99,20/80,56/27,18/46,78/17,68/58,58`, environ 150 s.
  - Référence avec 3 compagnons : 1 ou 2 replacements (après combats).
  - Avec 8 compagnons (`--give=food:300,materials:200 --buy=recruit,recruit,recruit,recruit,recruit`) : 2 à 4 replacements.
