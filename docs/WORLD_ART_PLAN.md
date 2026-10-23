# INCR-AGE — Montée en qualité artistique du monde jouable

Étude du lot 2, rédigée le 22/10/2026. **Rien n'est encore transformé dans le jeu.**

Cette étude ne touche à rien de ce qui suit, aujourd'hui comme dans les étapes proposées :
- la géographie de la carte ;
- les collisions ;
- les règles de déplacement ;
- le gameplay.

Seul le **rendu** du sol, de l'eau, des reliefs et des décors est en jeu.

Captures de référence (état actuel) : `docs/art/zone_temoin/`.
- `avant_vue_large.png` : le camp et ses abords, zoom large.
- `avant_pont.png` : la rivière et le pont à l'est du camp.
- `avant_falaise.png` : le grand plateau et son escalier.

## 1. Limites visuelles actuelles (constat bref)

| Élément | Ce qui fait « prototype » |
|---|---|
| **Sol** | Herbe d'un seul vert, quelques points épars : de grandes surfaces plates, sans nuances ni touffes. Elles se lisent comme un tapis. |
| **Transitions** | Les chemins ont des bords en bulles réguliers (formes de nuage) et une seule teinte de terre. Pas de zone intermédiaire : herbe clairsemée, cailloux, terre tassée. |
| **Grille** | Les diagonales et les rives suivent les cases de 32 px : on voit des marches d'escalier. |
| **Végétation** | Trois modèles d'arbres répétés. Les forêts forment des blocs aux bords droits, sans sous-bois, fougères, souches ni arbres isolés en lisière. |
| **Eau** | Un bleu uniforme avec des tirets de reflet et une berge réduite à un trait brun. Pas de hauts-fonds, d'écume, de rochers ni de végétation de rive (à part quelques roseaux). |
| **Falaises** | Un mur droit et rectiligne, au motif répétitif proche d'une maçonnerie. Bord supérieur parfaitement plat, aucun angle arrondi. L'escalier ressemble à du béton. |
| **Lumière et couleurs** | Vert très saturé partout, aucune variation d'éclairage, pas d'ombres des arbres au sol. |
| **Composition** | De grandes étendues vides entre les éléments, peu de points d'intérêt pour guider le regard. |

**Cause profonde.** Tout est produit par des règles appliquées à une grille de 32 px. Ajouter des détails programmés améliore chaque tuile, mais pas l'ensemble.

Ce qui manque :
- des formes dessinées à la main ;
- des transitions pensées par paires de terrains ;
- une composition voulue.

## 2. Point technique décisif : la densité de pixels

Nos personnages sont dessinés à **32 px par tuile** : un pixel de dessin vaut un pixel de jeu. Tout nouveau décor doit garder cette densité, sinon le monde et les personnages ne vont pas ensemble.

- Un pack en **16 px** agrandi deux fois aurait des pixels deux fois plus gros que ceux des personnages. Il faudrait alors redessiner aussi les personnages en 16 px.
- Un pack en **32 px** s'intègre directement.

## 3. Trois voies de production

| | A. Pack libre en 32 px | B. Pack libre en 16 px | C. Jeu de tuiles original, dessiné à la main |
|---|---|---|---|
| Exemples | LPC (Liberated Pixel Cup) et ses extensions | Ninja Adventure, Kenney | À produire selon notre fiche technique |
| Qualité | Bonne, complète (sols, eaux, falaises, arbres) | Bonne, style « mignon » | La meilleure possible, selon l'auteur |
| Cohérence avec nos personnages | Directe | Demande de refaire les personnages | Totale |
| Identité propre | Faible : style très répandu | Faible : très répandu | Forte |
| Coût | Gratuit | Gratuit | Ton temps, ou un pixel artiste rémunéré (avec ton accord) |
| Licence | CC-BY-SA 3.0 ou GPL 3.0 : usage commercial permis, crédit obligatoire, tuiles modifiées à repartager sous la même licence | CC0 annoncée, sans obligation | Propriété du projet |
| Délai pour la zone témoin | Court | Court, puis long (personnages) | Moyen à long |

**État des licences vérifiées** (à confirmer dans les fichiers de licence avant toute intégration) :
- **LPC.** Les fiches OpenGameArt indiquent CC-BY-SA 3.0 et GPL 3.0, parfois aussi CC-BY. Exemples : [LPC Modified base tiles](https://opengameart.org/content/lpc-modified-base-tiles), [jeu de base LPC](https://opengameart.org/node/14897).
- **Ninja Adventure.** CC0 d'après une [réponse de l'auteur](https://itch.io/post/5390864) sur itch.io.
- **Cainos, « Pixel Art Top Down – Basic ».** Pack en 32 px souvent cité comme gratuit et utilisable commercialement. Sa page n'a pas pu être lue (accès refusé à l'outil) : **licence non vérifiée**.

Une remarque sur la voie C : je peux dessiner des tuiles pixel par pixel (à la main, pas par bruit procédural). Mais mon niveau n'égale pas celui d'un pixel artiste confirmé. Pour viser la qualité d'un jeu indépendant soigné, la voie C passe idéalement par toi ou par un artiste.

## 4. Améliorations techniques nécessaires, quelle que soit la voie

Elles ne changent que l'affichage. Les collisions restent celles de `TerrainBuilder`.

1. **Grille double (dual grid).** Les tuiles sont posées décalées d'une demi-case et choisies d'après les 4 coins.
   - Chaque paire de terrains (herbe/terre, herbe/eau, herbe/plateau) se dessine avec 16 tuiles aux bords organiques.
   - Fini les marches d'escalier et les bords en bulles.
2. **Couche de décalques au sol.** Touffes, fleurs, cailloux, feuilles mortes, posés en grappes, avec quelques variations de teinte de l'herbe. Le sol cesse d'être un tapis uniforme.
3. **Lisières de forêt.** Arbres isolés, buissons et souches devant les blocs de forêt, pour casser les bords droits.
4. **Eau.** Bande de hauts-fonds plus claire, écume animée le long des rives, rochers et plantes de berge.
5. **Falaises.**
   - Tuiles en strates de roche, avec une lèvre herbeuse irrégulière en haut.
   - Angles arrondis, quelques variantes de hauteur apparente.
   - Escalier taillé dans la roche.
6. **Lumière.** Ombres portées douces des arbres et des huttes, légère teinte d'ambiance chaude.

## 5. Zone témoin proposée

- **Zone principale** : de la case (44, 44) à la case (82, 66). C'est le camp, ses chemins, la prairie fleurie, les lisières de forêt ouest, est et sud, la rivière avec ses roseaux et le pont. Cela fait environ deux écrans au zoom moyen.
- **Échantillon de relief** : la falaise et l'escalier du grand plateau, de (96, 22) à (106, 30), puisqu'il n'y a pas de relief près du camp.

**Méthode**
1. Produire un jeu de tuiles minimal pour cette zone seulement :
   - herbe, 3 variantes et des touffes ;
   - terre ;
   - eau, avec rives et écume ;
   - pont ;
   - lisière de forêt et 4 arbres ;
   - une dizaine de décalques ;
   - une falaise et son escalier.
2. Afficher ce nouveau rendu **dans la zone témoin uniquement**, par un réglage activable. Le reste du monde ne change pas.
3. Refaire les trois captures aux mêmes endroits et aux mêmes zooms, pour une comparaison avant/après côte à côte.
4. T'arrêter pour validation avant toute extension au reste du monde.

## 6. Recommandation

1. **Pour mesurer vite le saut de qualité possible : la voie A (LPC en 32 px) dans la zone témoin.** C'est gratuit, à la même densité que nos personnages, et sous une licence compatible avec une vente, à condition de créditer les auteurs. Cet essai sert de banc de comparaison.
2. **Pour l'identité à long terme : la voie C.** Un jeu de tuiles original, dessiné à la main, d'après une fiche technique qui reste à écrire : densité, palette, perspective, liste des tuiles, format pour la grille double. Il serait produit par toi ou par un artiste.

   L'essai de la voie A garde son utilité : il montre précisément quel niveau viser.
3. La voie B est déconseillée : elle obligerait à redessiner les personnages pour un style moins proche de notre direction.

## 7. Décisions à prendre avant la suite

1. Quelle voie pour la zone témoin : A, C, ou A puis C ?
2. Si A ou B : ton accord pour télécharger le pack retenu, en précisant la source et la taille. Les fichiers de licence et de crédits seront lus avant tout usage, et les auteurs crédités dans un fichier dédié.
3. Si C : qui dessine. De mon côté, je peux écrire la fiche technique et un premier essai de tuiles pixel par pixel, avec la limite de qualité indiquée plus haut.

Idées gardées pour plus tard, sans changement :
- amélioration VITESSE ;
- troupes aux mouvements plus organiques ;
- personnages plus aboutis ;
- carte du monde consultable.

## 8. Essai de la voie A (LPC) dans la zone témoin — résultats (23/10/2026)

**Ce qui a été fait.**
- Le pack `lpc_base_assets.zip` a été téléchargé avec ton accord. Seules cinq planches de Lanea Zimmerman (« Sharm ») sont copiées dans `assets/art/lpc/` : herbe, terre, eau avec berge herbeuse, couronnes d'arbres, troncs. Licence OGA-BY 3.0 : usage commercial permis, crédit obligatoire. Les crédits sont dans `assets/art/lpc/README.md`.
- `scripts/world/zone_temoin.gd` redessine la zone de (44,44) à (82,66) seulement :
  - herbe en fond ;
  - plaques de terre et d'eau, dont chaque case choisit son bord ou son coin d'après ses voisines ;
  - arbres LPC à la place des arbres d'origine, ceux-ci étant masqués, pas supprimés.
- La carte, les collisions et le gameplay ne changent pas.
- **F2** active ou désactive l'essai en jeu, pour comparer sur place. L'argument `-- --zone-temoin=off` le désactive au lancement.

**Comparaison** (mêmes endroits, mêmes zooms) :
- `docs/art/zone_temoin/avant_vue_large.png` et `apres_vue_large.png` ;
- `avant_pont.png` et `apres_pont.png`.

**Ce que l'essai démontre**

| Gagné | Révélé comme limite |
|---|---|
| Herbe texturée, en touffes : le sol ne fait plus « tapis » | **Échelle** : les arbres LPC (3 cases de large, 4 de haut) sont dessinés pour des personnages deux fois plus grands que les nôtres. Notre groupe paraît minuscule. |
| Berges herbeuses qui débordent sur l'eau, eau profonde avec reflets : la rivière devient organique | **Transitions d'une seule case** (diagonales des chemins, abords du pont) : blocs carrés. Le format LPC de base n'a que 13 tuiles par terrain ; il faudrait l'extension « LPC terrain » ou nos propres tuiles (grille double). |
| Chemins aux bords caillouteux irréguliers | Huttes, rochers et buissons d'origine : contour et palette un peu différents de LPC |
| Arbres en volume, avec tronc et ombre : la forêt devient crédible | Plaque d'herbe claire LPC (prairie) : contour sombre peu naturel, retirée de l'essai |
| 60 FPS en moyenne, sans changement | Falaises **non testées** : pas de tuile adaptée retenue dans le pack de base |

**Conclusion.** L'essai confirme d'où vient le saut de qualité :
- des textures dessinées à la main ;
- des transitions par plaques aux bords irréguliers ;
- des arbres en volume, avec leur ombre.

Il confirme aussi les limites d'un pack générique pour notre jeu : l'échelle, les transitions d'une case et l'identité.

**Suite recommandée (voie C).** Un jeu de tuiles original en 32 px, à l'échelle de nos personnages, qui reprend ces qualités :
- herbe en touffes ;
- berges débordantes ;
- bords irréguliers ;
- arbres de 2 à 3 cases de haut, avec ombre ;
- tuiles de transition complètes (grille double).

En attendant, l'essai LPC reste en place, activable par F2, comme banc de comparaison.

## 9. Suite : fiche technique de la voie C

L'essai LPC a été validé le 23/10/2026 comme banc de comparaison (F2). La fiche technique de notre propre jeu de tuiles est rédigée : `docs/TILESET_SPEC.md`. Elle couvre :
- le format ;
- la palette ;
- l'échelle ;
- la grille double ;
- l'eau et les falaises ;
- la végétation et les décalques ;
- l'intégration dans Godot ;
- l'ordre de production ;
- les critères d'acceptation.

## 10. Voie C, étape 1 : palette et herbe (23/10/2026, validée)

**Livrables**
- `assets/art/tiles/palette.gpl` : les 44 couleurs de la fiche, lisibles par LibreSprite, Aseprite, Pixelorama et GIMP.
- `assets/art/tiles/grass_fill.png` : 6 remplissages d'herbe de 32 px, dessinés pixel par pixel dans `tools/draw_tiles.gd`. Chaque motif y est écrit point par point, et sa place dans chaque tuile est choisie à la main, sans aucun bruit aléatoire :
  - grande touffe, petite touffe et brin ;
  - plaque claire et creux d'ombre ;
  - motte ;
  - fleurs jaune et blanche.
- Les variantes 0 à 3 sont courantes (20 % chacune), la motte et les fleurs plus rares (10 % chacune). Les bords de chaque tuile restent du vert de fond, si bien que les variantes se raccordent sans couture.
- L'outil vérifie que toutes les couleurs viennent de la palette.

**Dans le jeu.** F2 fait maintenant défiler trois rendus de la zone témoin, avec un bandeau qui annonce lequel est affiché :
- **TUILES INCR-AGE**, le rendu au lancement ;
- **RENDU ORIGINAL** ;
- **ESSAI LPC**.

L'étape 1 ne change que l'herbe (prairie et sol des forêts compris) ; le reste garde le rendu actuel.

**Captures** : `docs/art/zone_temoin/incr_vue_large.png` (zoom large) et `incr_proche.png` (zoom proche), à comparer avec `avant_vue_large.png` et `apres_vue_large.png` (LPC).

**Constat**
- Le sol est plus calme et moins saturé, et les personnages ressortent mieux.
- Les touffes et les fleurs se lisent au zoom proche, sans grille visible.
- La densité reste un peu régulière : 3 ou 4 éléments par tuile. À ajuster si tu le souhaites, avec plus de tuiles presque vides.
- **Raccords encore visibles, attendus** : un liseré vert vif borde les chemins et la rivière. Il vient des anciennes tuiles de chemin et d'eau, qui contiennent l'ancien vert, et disparaîtra avec les étapes 2 (terre sur herbe) et 3 (eau sur herbe). La bordure de la zone témoin reste visible aussi.

## 11. Voie C, étape 2 : terre sur herbe (23/10/2026, validée)

**Livrables** (dessinés dans `tools/draw_tiles.gd`)
- `assets/art/tiles/dirt_fill.png` : 3 remplissages de terre, avec cailloux éclairés, terre tassée, terre sèche et fissures, placés à la main.
- `assets/art/tiles/dirt_on_grass.png` : les 16 tuiles « terre sur herbe » en grille double, en planche 4 × 4 selon la fiche.
  - Le bord suit deux lignes ondulées tracées à la main (décalages pixel par pixel), qui coupent chaque côté à 16 px pour se raccorder.
  - Les coins sont arrondis : le terrain est pondéré entre les 4 coins, de sorte que les coins saillants et rentrants s'adoucissent tandis que les bords entre deux coins pareils restent droits.
  - Frange : la terre fonce d'un ton contre l'herbe, et de deux sous un bord d'herbe situé au-dessus (ombre). L'herbe s'assombrit le long du bord, avec quelques pointes claires.
- Les couleurs sont contrôlées contre la palette, et l'herbe de l'étape 1 est inchangée au pixel près.

**Dans le jeu** (zone témoin, rendu TUILES INCR-AGE)
- Les chemins et le sol du camp sont en terre.
- Une tuile de transition est posée à chaque sommet où se croisent herbe et terre.
- Les sommets qui touchent l'eau ou le pont sont laissés à l'étape 3.
- 60 FPS.

**Captures** : `incr_vue_large.png`, `incr_proche.png`, `incr_chemin.png` dans `docs/art/zone_temoin/`.

**Constat**
- Les chemins deviennent organiques : coins arrondis, diagonales lues comme des diagonales et non plus comme des escaliers.
- Le liseré vert vif d'origine a disparu le long des chemins.
- Il reste à traiter :
  - les berges de la rivière, encore dans l'ancien rendu (étape 3) ;
  - des bouts de chemin carrés aux abords du pont, dont les sommets sont laissés à l'étape 3 ;
  - la bordure de la zone témoin.
- La même ondulation se répète le long des bords droits, toutes les 32 px. Elle est discrète ; on pourra ajouter une seconde série de tuiles de bord si elle se remarque.

## 12. Voie C, étape 3 : eau sur herbe, eau animée, écume (23/10/2026, validée)

**Livrables** (dessinés dans `tools/draw_tiles.gd`)
- `assets/art/tiles/water_fill.png` : l'eau profonde en 4 images qui bouclent.
  - Zones plus profondes posées à la main.
  - 7 reflets qui « respirent » sur place (1, 3, 5 puis 3 pixels), décalés entre eux : l'eau scintille sans glisser ni sauter.
- `assets/art/tiles/water_on_grass.png` : les 16 tuiles « eau sur herbe » pour chacune des 4 images (4 planches 4 × 4).
  - Berges sur deux lignes ondulées tracées à la main, différentes de celles des chemins.
  - Coins arrondis.
  - En partant du bord : côté terre, une lèvre d'herbe sombre avec des pointes claires ; côté eau, 1 px de berge sombre, 2 px d'écume qui scintille d'une image à l'autre, 4 px de hauts-fonds clairs (le dernier en damier), puis l'eau profonde.
  - Côté terre, la tuile est transparente : on y voit l'herbe ou la terre dessous.
- L'écume est intégrée aux tuiles de berge animées plutôt que posée en couche séparée : le rendu est le même, avec une couche de moins.
- Les couleurs sont contrôlées contre la palette ; l'herbe et la terre sont inchangées au pixel près.

**Dans le jeu** (zone témoin, rendu TUILES INCR-AGE)
- Toute l'eau est posée en grille double, tuiles pleines comprises. Les cases d'eau reçoivent de l'herbe dessous, si bien que la partie « terre » d'une berge arrondie montre bien de l'herbe.
- Le chemin rejoint la berge et le pont.
- La zone témoin passe sous la couche du pont d'origine, qui reste visible par-dessus. Les anciens décors de cette couche (sous les roseaux) sont masqués dans la zone et rétablis dans les autres rendus.
- L'eau est sur son propre calque, seul redessiné 6 fois par seconde : **60 FPS**, comme le rendu original.

**Captures** : `incr_vue_large.png`, `incr_pont.png`, `incr_berge.png` dans `docs/art/zone_temoin/`.

**Constat**
- La rivière devient organique : berges ondulées, coins arrondis, écume, hauts-fonds, eau profonde qui scintille.
- Le liseré vert d'origine a disparu partout dans la zone.
- Il reste à traiter :
  - la bordure de la zone témoin, visible ;
  - le pont, les roseaux, les arbres et les décors, encore dans l'ancien style ;
  - la même ondulation qui revient toutes les 32 px le long des longues berges droites, discrète.

## 13. Voie C, étape 4 : arbres, buissons, souche et ombres (23/10/2026, en attente de validation)

**Livrables** (dessinés dans `tools/draw_nature.gd`)
- `assets/art/tiles/nature.png` et `nature.json` (rectangle et point d'ancrage aux pieds de chaque objet) :
  - 3 feuillus : chêne rond (64 × 73 px), arbre élancé (56 × 84), arbre large (72 × 68) ;
  - 1 sapin (44 × 92) ;
  - 2 buissons, dont un à baies ;
  - 1 souche ;
  - l'ombre de chaque objet, sur une rangée à part pour pouvoir l'ajuster.
- **Échelle** : de 2 à 3 cases de haut pour les arbres, soit trois fois la taille de nos personnages de 26 px, contre plus de quatre cases pour les arbres LPC.
- **Fait à la main** :
  - la silhouette de chaque feuillu, en 4 à 7 touffes rondes (centre et rayon choisis un à un) ;
  - les 5 étages du sapin ;
  - l'écorce et la souche, écrites pixel par pixel ;
  - les taches de lumière, les creux d'ombre et les baies, posés un à un ;
  - un motif de petites feuilles et un motif d'aiguilles répétés dans les feuillages.
- **Calculé** : l'éclairage venu d'en haut à gauche, le relief entre touffes (plus sombre sous une touffe placée devant) et le contour, plus foncé en bas et à droite.
- Les couleurs sont contrôlées contre la palette.
- Le fichier est rangé dans `assets/art/tiles/` avec le reste de la voie C, plutôt que dans un nouveau dossier `props/`.

**Dans le jeu** (zone témoin, rendu TUILES INCR-AGE)
- Forêts : un arbre par case en quinconce, comme les arbres d'origine, mêlant chênes, arbres élancés, arbres larges et sapins, un peu assombris au cœur de la forêt.
- Arbres et buissons isolés de la carte remplacés par les nôtres.
- Deux souches décoratives en lisière, sans collision.
- Seuls les dessins d'origine sont masqués : les collisions ne changent pas.
- 60 FPS ; environ 630 nœuds de plus.

**Captures** : `incr_vue_large.png`, `incr_foret.png` (zoom proche), `incr_pont.png` dans `docs/art/zone_temoin/`.

**Constat**
- Les forêts se lisent comme de vraies forêts : silhouettes variées, volumes, palette commune avec le sol, et l'échelle reste juste face au groupe.
- Restent dans l'ancien style : huttes, feu, pont, rochers, caisses, totem, roseaux.
- Les ombres des arbres ne se voient qu'en lisière, la forêt dense les couvre.
- La canopée continue et les arbres de lisière posés devant (fiche, section 8) ne sont pas encore faits : pour l'instant, c'est toujours un arbre par case.
