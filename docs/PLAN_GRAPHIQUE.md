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

## 3. Plan

### Personnages : une base, des variantes

- **Une seule base** pour tous les humains : mêmes proportions, même tête, même pagne de peau, même
  manière d'ombrer et de détourer. Dans PixelLab : un personnage de référence, puis chaque unité créée
  à partir de lui (même style, même taille, même direction de lumière).
- **Héros** : la base, plus imposante (épaules, cape de fourrure claire), **massue à tête de pierre**,
  plume, et l'**or** comme couleur d'accent, réservée au héros (déjà le cas de l'anneau, de la barre de
  vie et de ses coups). On le reconnaît à sa silhouette avant sa couleur.
- **Armée** : la base, sans cape, avec un **bandeau ocre** commun (la couleur de la tribu).
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
