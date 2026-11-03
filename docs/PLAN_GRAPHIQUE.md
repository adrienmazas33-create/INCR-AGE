# INCR-AGE — Audit graphique et plan simplifié (03/11/2026)

Objectif : une vraie cohérence visuelle de jeu indépendant avant de reprendre le gameplay. Un héros
qui se distingue, une armée faite sur une même base, un monde plus beau, et une petite **vitrine**
autour du campement validée avant toute généralisation.

Captures de l'état actuel : `docs/art/audit/` (camp, groupe de près, hors de la zone témoin).

## 1. Audit

**Ce qui fonctionne déjà**
- Le sol de la voie C dans les deux zones témoins (camp, grand plateau) : herbe calme, chemins aux bords
  organiques, eau animée, falaises en strates, arbres, décalques. C'est la base du style.
- L'interface du camp (panneau, bande TROUPE), la boussole, les effets de combat, la lisibilité du
  feu de camp et du butin.
- Le groupe en mouvement : colonne vivante, haltes naturelles (troupes organiques).

**Ce qui fait encore prototype**
- **Deux styles dans le même monde** : hors des zones témoins, l'herbe vert vif saturée, les chemins
  en gros pavés arrondis et les falaises en « mur de pierres » de l'ancien rendu. On passe d'un jeu à
  l'autre en marchant (`hors_zone.png`, `hors_zone_falaise.png`).
- **Les personnages** (26 px, générés par programme) : une même silhouette brune pour tous. Le héros
  ne se reconnaît qu'à son anneau doré et à sa plume ; en groupe, les compagnons forment une masse
  (`groupe.png`) ; un frondeur ne se distingue d'un lancier que par l'absence de lance.
- **Les décors du camp** : deux familles de huttes qui ne se ressemblent pas (dôme de peau, cône de
  paille), rondins, caisses et séchoir de la passe 1, plus contrastés et plus « programme » que le sol.
- **L'ennemi humain** (lanceur rival) est un compagnon recoloré : rien ne dit « autre tribu ».

**Ce qui nuit le plus au rendu**
1. Les personnages, parce qu'on les regarde en permanence et qu'ils sont le point faible.
2. La coupure entre les deux styles de sol.
3. L'échelle des arbres face aux personnages (étude `ECHELLE_PERSONNAGES.md` : arbres deux fois trop
   courts).

**À traiter en priorité** : fixer l'échelle des personnages avec un vrai sprite, puis faire la base
commune de l'armée. Le sol, lui, est presque prêt à être étendu.

## 2. La décision qui conditionne tout : la taille des personnages

Le héros PixelLab est fait sur une toile de 48 px (animations sur 68 px). Selon sa hauteur visible,
réelle, mesurée sur les exports :

| Hauteur visible | Conséquence pour le monde |
|---|---|
| 26 à 32 px (comme aujourd'hui) | Rien à changer, sauf les arbres (à agrandir de 1,5 environ). |
| **36 à 42 px (hypothèse la plus probable)** | Cases de 32 et sol de la voie C inchangés ; huttes à peine justes (une hutte fait environ 1,7 fois un humain) ; **arbres à agrandir** ; espacements du groupe à élargir un peu. Règles, collisions, vitesses et portées inchangées. |
| 47 px et plus | Option C de l'étude : décors ×1,7, plan du camp à refaire, constantes à revoir. Trop lourd pour maintenant. |

**Recommandation** : viser une hauteur visible de **36 à 42 px**, la confirmer dans la vitrine avec le
vrai héros, et n'agrandir que ce qui le demande (arbres d'abord, huttes seulement si elles paraissent
des tentes). Si le héros validé dépasse cette taille, en reparler avant de produire l'armée.

**Mise à jour du 03/11/2026** : le héros PixelLab retenu mesure **46 à 50 px** (section 7). C'est
l'échelle de l'option C de l'étude, celle que l'essai LPC avait jugée juste pour les personnages.
La question est rouverte : voir la section 7.

## 3. Plan

### Personnages : une base, des variantes

- **Une seule base** pour tous les humains : mêmes proportions, même tête, même pagne de peau, même
  manière d'ombrer et de détourer. Dans PixelLab : un personnage de référence, puis chaque unité créée
  à partir de lui (même style, même taille, même direction de lumière).
- **Héros** : la base, plus imposante (épaules, cape de fourrure claire), **massue à tête de pierre**,
  plume, et l'**or** comme couleur d'accent, réservée au héros (déjà le cas de l'anneau, de la barre de
  vie et de ses coups). On le reconnaît à sa silhouette avant sa couleur.
- **Armée** : la base, sans cape ni bandeau doré (réservé au héros, voir section 7), avec un même
  signe de tribu discret (cordelette de cuir au front ou peinture ocre sur l'épaule).
  - **Mêlée** : longue lance à pointe de silex, qui dépasse au-dessus de la tête.
  - **Distance** : fronde à la main, sacoche de pierres à la hanche, pas de lance ; posture plus droite.
  - Variété limitée à **2 ou 3 teintes de peau et de cheveux**, par simple changement de couleurs, pas
    par huit dessins différents.
- **Ennemi représentatif** : le lanceur rival, **même base**, autre palette : peintures **violet sourd**
  (celui de sa bannière), collier d'os, pas d'ocre. On lit « autre tribu » d'un coup d'œil, pour presque
  rien.
- **Animations minimales** : repos (2 à 4 images) et marche (4 à 6), face, dos et profil (l'autre profil
  en miroir). L'attaque garde son élan actuel ; la mise à terre garde la rotation. Une animation
  d'attaque viendra plus tard, une fois la base validée.
- Le sanglier reste tel quel pour la vitrine ; il sera repris avec la faune.

### Monde

1. **Vitrine** (zone témoin du camp, déjà en voie C) : arbres agrandis selon la taille retenue, et une
   seule famille de huttes et de décors dessinée dans la palette de la voie C (lumière en haut à gauche,
   pas de contour noir sur le décor).
2. **Ensuite seulement, après validation de la vitrine** : étendre la voie C à toute la carte. C'est le
   plus gros gain visible pour le moins de travail : les tuiles existent toutes (sol, eau, falaises,
   arbres, décalques), c'est surtout de l'intégration.

## 4. Méthode de production (à suivre pour chaque unité)

1. **Génération** dans PixelLab par le porteur du projet (je ne dépense jamais de crédits), à partir du
   personnage de référence, même toile, mêmes directions.
2. **Exports** rangés dans `assets/source/pixellab/<unité>/`, avec leurs métadonnées (taille, nombre
   d'images, cadence, point des pieds) et la mention de la licence de l'offre PixelLab utilisée.
3. **Assemblage** par un outil du dépôt : planche au format du jeu (face, dos, profil), **pieds alignés
   au même point** dans toutes les images, contrôle automatique de cet alignement, aucune mise à
   l'échelle.
4. **Intégration à l'essai**, par une bascule (argument de lancement et touche, comme F2) : l'ancien
   sprite reste à un geste ; rien n'est enregistré dans la sauvegarde.
5. **Vérification** : captures avant et après aux mêmes endroits, tour complet de la carte (mêmes
   durées, mêmes statistiques), combat, 60 FPS.
6. **Validation** par le porteur du projet, unité par unité, avant de passer à la suivante.

Règles communes : personnages plus saturés que le sol, contour sombre sélectif sur les personnages
seulement, lumière en haut à gauche, or réservé au héros, violet sourd au clan rival, rouge au danger.

## 5. La vitrine, dans l'ordre

| Étape | Contenu | Dépend de |
|---|---|---|
| 1 | Héros PixelLab à l'essai (bascule), mesure de sa hauteur visible | exports du héros |
| 2 | Décision de taille (section 2) | étape 1 |
| 3 | Lancier, frondeur, lanceur rival, sur la même base | génération PixelLab |
| 4 | Arbres et huttes de la vitrine à la bonne échelle, espacements du groupe | étape 2 |
| 5 | Captures de référence, arrêt pour validation | tout ce qui précède |

Hors vitrine : aucun changement. Pas de nouvelle mécanique, règles et sauvegarde inchangées.

## 6. Ce qu'il me faut pour avancer

- Les **exports du héros** (face, profil, dos) et leurs métadonnées.
- Le **personnage de référence** de l'armée et ses déclinaisons : lancier, frondeur, lanceur rival
  (mêmes réglages que le héros).
- La **licence** de l'offre PixelLab utilisée (usage commercial).

## 7. Héros PixelLab : examen des exports (03/11/2026)

Sources retenues : `assets/source/pixellab/hero/` (non importées par Godot). Planche de contrôle,
agrandie trois fois : `docs/art/heros/pixellab_examen.png` (ligne 1 : version écartée ; ligne 2 :
version retenue ; lignes 3 à 5 : sa marche de face, de profil, de dos ; en bas : héros et compagnon
actuels à la même échelle).

**Les deux versions de l'export**

| Dossier du ZIP | Ce que c'est | Contenu | Décision |
|---|---|---|---|
| `Idle` | Première version : manteau de fourrure, ceinture verte, bottes | 8 orientations, aucune animation | **Écartée** (malgré son nom, ce n'est pas un repos) |
| `Transform_ONLY_the_o` | Version simplifiée : tunique de peau, bandeau ocre doré, massue, pieds nus | 8 orientations + marche | **Retenue** |

**Mesures de la version retenue**
- Orientations : toile de 48 × 48, personnage de **45 à 48 px** de haut, pieds à la rangée 45 à 47,
  15 couleurs.
- Marche : 8 images en face, de dos et de profil est (il regarde vers la droite), toile de 68 × 68,
  personnage de **46 à 50 px**, 28 à 45 couleurs.
- Les orientations sont centrées dans la toile de la marche : avec un décalage de 10 px, leurs pieds
  tombent au même endroit (rangées 55 à 57 contre 55 à 59). Un seul point d'ancrage par toile suffit.
- Aucune cadence n'est fournie : elle sera réglée sur la vitesse réelle (pas de glissement).

**Incohérences et manques**
- **Échelle** : 1,8 fois le héros et les compagnons actuels (26 px), et autant face aux huttes et aux
  arbres. C'est le point principal, voir ci-dessous.
- **Pas d'animation de repos** : seule une pose fixe par direction. Le héros resterait immobile à
  l'arrêt (pas de respiration) ; un repos peut être généré plus tard dans PixelLab.
- **Pas de marche vers l'ouest** : le profil est sera retourné, comme aujourd'hui. La massue change
  alors de main ; c'est peu visible à cette taille.
- **Couleurs** : la marche a 2 à 3 fois plus de nuances que les poses fixes ; au passage du repos à la
  marche, le rendu change très légèrement.
- **Rebond** : le pied le plus bas varie de 4 px au cours d'un pas ; avec un ancrage fixe, le corps
  monte et descend un peu, ce qui est naturel. À juger en jeu.
- Diagonales disponibles en poses fixes seulement ; le jeu n'utilise que face, dos et profil.
- **Licence** : celle de l'offre PixelLab utilisée reste à confirmer pour un usage commercial.

**Identité** : le bandeau ocre doré et la massue font la signature du héros, ce qui rejoint l'or
réservé au héros. L'armée ne portera donc pas ce bandeau (section 3 corrigée).

**La question d'échelle**
- Réduire le héros pour l'adapter au monde actuel n'est pas une option : une réduction de pixel art
  détruit le dessin.
- Le héros à sa taille réelle (47 px) correspond à l'option C de l'étude d'échelle : à terme, armée à
  la même taille (même toile de 48 px), arbres et huttes agrandis d'environ 1,7, par lots validés.
- Pour l'essai, le héros est affiché **à sa taille réelle**, monde et armée inchangés : il dominera
  nettement le groupe. Cela sert à juger le personnage et la taille cible, pas encore la cohérence
  d'ensemble.
- La refonte du monde n'est pas lancée sans ta validation.

## 8. Intégration (faite et validée le 03/11/2026 ; le sprite actuel reste le défaut)

Tout se fait derrière une bascule : le sprite actuel reste le défaut et rien n'est enregistré.

1. **Outil d'assemblage** `tools/pack_pixellab.gd` : lit un dossier de sources PixelLab et écrit une
   planche au format du jeu, `assets/art/hero_pixellab.png`. Cases de 68 × 68 ; rangées face, dos,
   profil (l'ordre de `CharacterSprite`) ; une image de repos (la pose fixe, recentrée de 10 px) puis
   les 8 images de marche. Il vérifie que tous les pieds tombent dans la même bande.
2. **`CharacterSprite`** : les listes d'images et les cadences deviennent des réglages, avec les
   valeurs actuelles par défaut. Compagnons, villageois et lanceur ne changent pas.
3. **`Hero`** : bascule par l'argument `-- --hero-skin=pixellab` et par la touche F3, avec un bandeau
   comme pour F2. Elle ne change que l'apparence : texture, grille, décalage aux pieds, cadence,
   hauteur de la barre de vie, du chevron et des étincelles de coup, taille de l'ombre et de l'anneau.
4. **Inchangés** : collisions, vitesse, portée, combat, caméra, sauvegarde, monde, armée.

Réglages de l'apparence, à ajuster à l'œil : `Hero.PIXELLAB_SKIN` (marche à 16 images/s, barre de vie
à 54 px, anneau de 14 × 5, chevron à 59 px, ombre ×1,6). Régénérer la planche :
`godot --headless --path . --script res://tools/pack_pixellab.gd -- hero`, puis `--import`.

**Vérifications** (sauvegardes de test isolées) :
- assemblage : pieds de toutes les images aux rangées 55 à 59 de la case (bande commune) ;
- captures dans `docs/art/heros/` : repos de face et marche vers la gauche (profil retourné), combat
  avec le héros blessé, ancien et nouveau côte à côte ;
- bascule : F3, F3 puis F3 depuis l'argument : l'état du sprite revient exactement à l'origine
  (image, grille, décalage, images, cadences, barre, ombre). Une comparaison au pixel près n'a pas de
  sens : deux lancements identiques diffèrent déjà (troupe, feu, gestes à la halte) ;
- vitesse (100), portée (14) et collision des pieds (rayon 5) identiques dans les deux apparences ;
- barre de vie au-dessus de la nouvelle tête en combat ;
- tour complet de la carte avec le héros PixelLab : 149,8 s comme avec l'ancien, 60 FPS, 4 retours
  forcés (comme la référence), frondes et lanceurs inchangés, aucune erreur ;
- **non vérifié, à juger en jeu** : glissement éventuel des pieds à la cadence choisie, chevron de
  combat (le combat de test s'est terminé avant), mise à terre.

## 9. Production de l'armée : méthode réutilisable

Le héros retenu est lui-même né d'une retouche PixelLab (« Transform ONLY the… ») appliquée à un
premier personnage. C'est la méthode à réutiliser pour l'armée :

1. **Un soldat de base**, créé une fois dans PixelLab avec les mêmes réglages que le héros : modèle
   « mannequin », toile de 48 px, vue « low top-down », 8 directions, même bloc de style dans la
   consigne (« Handcrafted RPG pixel art… light from upper left… selective dark colored outlines »).
   Plus simple que le héros : pagne de peau, pas de bandeau doré, pas de massue, cheveux différents.
2. **Les variantes par retouche** de ce soldat (« Transform ONLY the weapon… ») : une lance à pointe de
   silex pour la mêlée, une fronde et une sacoche de pierres pour le frondeur. Mêmes proportions, même
   tenue, même lumière par construction.
3. **Une seule animation** par variante au départ : la marche, face, dos et profil est, comme le héros.
4. **Variété dans le jeu, pas dans PixelLab** : 2 ou 3 teintes de peau et de cheveux par changement de
   couleurs à l'affichage, au lieu de huit dessins.
5. **Même chaîne** que le héros : dossier de sources, `tools/pack_pixellab.gd`, essai derrière une
   bascule, validation.

Les unités ne sont pas créées tant que le héros et la taille cible ne sont pas validés.
