# INCR-AGE — Feuille de route des prochaines améliorations

Document de cadrage rédigé le 22/10/2026 à partir des retours de test du porteur du projet.

> **Tout ce qui suit est PRÉVU, rien n'est développé.** Seul l'indicateur de direction du campement (section 0) a été fait ; il attend la validation.

Règles communes à chaque lot :
- un lot indépendant, testable seul, avec arrêt pour validation ;
- aucune mécanique validée modifiée sans accord (héros, combat automatique, compagnons en laisse, sauvegarde) ;
- aucune dépendance ni service payant ; ressources libres de droits pour un usage commercial, licence vérifiée fichier par fichier ;
- pas de refonte technique générale.

## 0. Indicateur de direction du campement — FAIT, en attente de validation

- `scenes/ui/camp_compass.gd`, ajouté à l'interface par `scenes/main.gd`.
- Quand le feu de camp sort de l'écran : un médaillon (flamme) glisse le long du bord, une flèche dorée pointe vers le camp, la distance s'affiche en tuiles du côté opposé à la flèche.
- La flèche suit 16 directions (rendu net en pixels). Le médaillon s'efface en fondu quand le camp redevient visible, et passe sous le compteur de ressources.
- Purement visuel : aucune règle de jeu touchée.

## Ordre proposé pour les prochaines sessions

1. Déplacement à la souris.
2. Carte du monde et navigation.
3. Audio.
4. Qualité artistique des personnages et animations.

## 1. Déplacement à la souris (lot suivant)

**Comportement attendu**
- Clic gauche sur le sol : le héros va à l'endroit cliqué.
- Un nouveau clic remplace la destination précédente.
- Une touche de déplacement au clavier interrompt aussitôt le trajet : le clavier garde la priorité.
- Les compagnons suivent comme aujourd'hui (même traînée, même laisse) ; le combat automatique reste inchangé, y compris pendant un trajet.
- Distinguer trois cas de clic :
  - sur l'interface (panneau du camp, futurs boutons) : le clic est pour l'interface et le héros ne bouge pas ;
  - sur un élément interactif (plus tard : feu, bâtiment, ressource) : réservé à une interaction ; le héros s'en approchera ;
  - sur le sol : déplacement.
- Petit repère visuel au point cliqué (bref, discret, pixel art), et repère « impossible » si la case n'est pas atteignable.

**Approche technique prévue**
- Recherche de chemin A* sur la grille de `MapData` (cases de 32 px), en réutilisant les règles déjà écrites pour les déplacements (rebords de plateaux, escaliers, ponts, eau, forêt).
- Cases occupées par les bâtiments et décors du camp ajoutées comme obstacles, selon le stade du camp (l'outil de parcours de test les ignore aujourd'hui).
- Lissage du chemin : on saute les cases intermédiaires tant qu'une ligne droite est libre (test de collision), pour éviter les zigzags.
- Si le clic tombe dans une case bloquée : destination ramenée à la case libre la plus proche.
- Si le héros reste bloqué (poussé par un sanglier, par exemple) : nouveau calcul du chemin, puis abandon au bout de quelques essais.
- Entrée : `_unhandled_input`, si bien que les contrôles d'interface reçoivent le clic en premier.
- Le héros reçoit une « direction voulue », comme celle du clavier aujourd'hui : rien ne change pour la caméra, le groupe et le combat.
- Base existante à réutiliser : le parcours en largeur de l'outil de test (`DevCapture`, option `--route`).

**Tests prévus** : clics à travers ponts, escaliers, berges et autour des bâtiments ; clic sur l'eau, sur une falaise, sur l'interface ; interruption par le clavier ; trajet pendant un combat ; groupe de 8 compagnons ; aucun blocage sur un long parcours.

## 2. Carte du monde et navigation

**Comportement attendu**
- Touche `M` : ouvre et ferme une carte consultable en plein écran (de préférence à une minicarte permanente). Plus tard, une icône cliquable fera de même.
- Contenu :
  - la géographie (eau, forêts, plateaux, chemins, ponts) ;
  - la position du joueur et celle du campement ;
  - les lieux et points d'intérêt découverts (repaires, menhirs, totems…) ;
  - plus tard, les territoires.
- Brouillard sur les zones non explorées.

**Approche technique prévue**
- Image de la carte calculée à partir de `MapData` avec une palette dédiée, une case par pixel (120×100), affichée agrandie en pixels entiers dans un cadre `UiFrame`.
- Exploration : grille de cases découvertes autour du héros, enregistrée dans la sauvegarde (nouvelle version du format, avec migration des anciennes sauvegardes).
- Points d'intérêt déclarés dans les données (comme les décors), et non codés en dur : ils resteront compatibles avec une future génération semi-procédurale des cartes.
- Le jeu peut continuer derrière la carte ou être mis en pause : à décider au début du lot.
- Minicarte : optionnelle, plus tard, si le besoin se confirme.

## 3. Audio

**Contenu prévu**
- Effets sonores :
  - pas selon le terrain (herbe, chemin, pont, plateau) ;
  - coups de massue, impacts ;
  - grognements et charge des sangliers ;
  - ramassage du butin, recrue, achat, évolution du camp ;
  - crépitement du feu près du camp ;
  - ambiances de nature (vent, oiseaux, eau près des rivières et du lac).
- Musique : une boucle principale originale de 90 à 150 s.
  - Rétro / chiptune aux instruments doux, dans l'esprit des anciens Zelda, des anciens Pokémon ou de Minecraft, mais entièrement originale (aucune mélodie reprise).
  - Boucle sans coupure audible, volume modéré.
  - Thème conçu pour évoluer avec les époques (mêmes motifs, autre instrumentation).
- Réglages : volumes séparés pour la musique, les effets et les ambiances, chacun désactivable, enregistrés dans un fichier de réglages distinct de la sauvegarde de partie.

**Approche technique prévue**
- Un gestionnaire audio (autoload) et trois bus Godot : Musique, Effets, Ambiance.
- Lecteurs d'effets réutilisés, avec une légère variation de hauteur pour éviter la répétition.
- Sons de pas choisis selon la case de `MapData` sous le héros ; ambiances selon la région.
- Sources gratuites et utilisables commercialement :
  - effets générés par un petit synthétiseur maison de type sfxr, entièrement original ;
  - ou banques CC0 (Kenney, Freesound filtré sur CC0), avec licence notée fichier par fichier dans un `CREDITS.md` ;
  - musique composée et rendue avec un outil gratuit (BeepBox, Furnace…) ou par synthèse en GDScript, puis exportée en OGG.
- Pas de génération de toute la bande-son d'un coup : d'abord le système et quelques sons, validés à l'écoute, puis le reste.

## 4. Qualité artistique des personnages et animations

**Constat** : ajouter encore des détails par programme a atteint ses limites. Le saut de qualité viendra de planches de sprites dessinées à la main.

**Méthode à définir avant toute production**
- Étudier de vraies planches de jeux pixel art de référence (proportions, nombre de couleurs, poses clés, timing des animations), sans rien copier.
- Fiche technique des planches :
  - taille d'image ;
  - palette restreinte, commune au décor ;
  - pied du personnage comme point d'ancrage ;
  - animations : attente, marche, attaque, coup reçu, K.O. ;
  - 4 directions, avec la gauche obtenue en miroir de la droite.
- Pistes de production :
  - dessin dans un éditeur pixel art (Aseprite, ou LibreSprite, gratuit) ;
  - esquisses ou concepts comme simple base, puis reprise entière à la main ;
  - planches modulaires en couches (corps, tenue, arme) pour les équipements et les époques futures.
- Intégration : `SpriteFrames` de Godot, ou adaptateur vers le format actuel de `CharacterSprite`, pour remplacer l'art sans toucher aux mécaniques.
- Commencer par un seul personnage (le héros) comme prototype à valider, avant de produire le reste.

**À ne pas faire maintenant** : aucune refonte des personnages avant que cette méthode soit validée.
