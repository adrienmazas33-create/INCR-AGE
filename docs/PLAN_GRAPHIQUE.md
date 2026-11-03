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

## 10. Soldat de base PixelLab dans le groupe (03/11/2026, validé)

Consignes de la transmission (`POUR-CLAUDE.md`, préparée hors du dépôt) : intégrer le soldat validé
auprès du héros, avec ses **poses fixes** et un **balancement de marche calculé**, sans nouvelle
génération ; cohérence entre directions avant richesse d'animation.

**Sources** : `assets/source/pixellab/soldier/` (export complet ; le `prompt` des métadonnées est celui
du héros, hérité par PixelLab, mais les images sont bien le soldat). Poses fixes de 48 × 48, soldat de
**44 à 46 px**, la taille du héros : même base de corps. Le héros se distingue par son bandeau doré,
sa massue et sa tunique. Animations partielles (marche de face seulement, repos dans 4 directions)
gardées pour plus tard, non utilisées : elles ne couvrent pas le dos ni l'ouest.

**Intégration**
- `tools/pack_pixellab.gd -- soldier --poses` : planche des seules poses (face, dos, profil est),
  `assets/art/soldier_pixellab.png`, pieds aux rangées 45 à 46.
- `CharacterSprite.walk_sway` : en marche, le personnage monte de 2 px au milieu de chaque pas et se
  reporte d'1 px d'un côté puis de l'autre, en pixels entiers (pas de rotation : dessin net). Pas par
  seconde suivant la vitesse réelle, comme les autres marches.
- `Follower.apply_look` : planche, découpage, ancrage aux pieds, marche, barre de vie et ombre.
  Même soldat pour la lance et la fronde : les armes sont un travail visuel ultérieur.
- `Party` : la même apparence pour tous les compagnons, recrues comprises ; **espacement ×1,5** des
  écarts de la colonne et des places à la halte, sinon des personnages de 46 px s'empilent. Élargir
  aussi la séparation et l'écart latéral coinçait les soldats dans les passages étroits (43 retours
  forcés sur le tour de la carte) : ils restent d'origine. Les règles du suivi ne changent pas.
- **F3 bascule désormais le groupe entier** (héros et soldats) ; `-- --skin=pixellab` au lancement
  (`--hero-skin=pixellab` reste accepté). Rien n'est enregistré dans la sauvegarde.

**Vérifications** (copies de sauvegardes de test, à 4 et à 8 compagnons) : captures dans
`docs/art/soldat/` (camp, marche de dos et de profil, combat avec un soldat à terre) ; directions
justes (dos en montant, profil retourné à gauche) ; barre de vie et chevron du héros au-dessus de sa
tête en combat ; tour complet de la carte à 8 compagnons en PixelLab : 149,8 s, 60 FPS, 6 retours
forcés (référence : 4 à 6), aucune erreur ; F3 rend aux compagnons exactement leur apparence d'origine (planche, découpage,
décalage, marche, barre, espacement) ; vitesse et collisions inchangées.

**Limites visibles**
- Les soldats sont tous identiques et sans arme : lanciers et frondeurs ne se distinguent pas à l'œil.
- Le balancement ne remplace pas une vraie marche : les jambes restent immobiles.
- Le lanceur rival, les villageois, le décor et les huttes restent à l'ancienne échelle : ils paraissent
  minuscules à côté du groupe.
- À 8 compagnons au camp, des places de halte bloquées par les décors (feu, rondins) font qu'un soldat
  reste contre le héros ; c'était déjà le cas avant, mais cela se voit plus à cette taille.
- En colonne, les deux files se chevauchent : l'écart latéral est resté celui d'origine (8 px) pour
  que le suivi passe les ponts et l'escalier. Un écart plus grand demanderait de revoir le suivi
  dans les passages étroits.

## 11. Marche fabriquée sans PixelLab : prototype vers le bas (03/11/2026, en attente de validation)

Décision du porteur du projet : PixelLab ne sert plus à générer d'animations ; ses designs restent les
références. Les cycles de marche se fabriquent dans le dépôt, à partir des poses fixes.

**Méthode retenue : découpage des membres en pixels entiers** (`tools/animate_walk.gd`).
- Écartées : la déformation du personnage entier (le balancement actuel, jugé insuffisant) et les
  rotations de membres (pixels flous ou incohérents à cette taille). Un dessin image par image dans un
  éditeur local donnerait le meilleur résultat, mais demande un dessinateur.
- Jambes découpées sous le pagne : leur longueur change en retirant ou en dupliquant des rangées du
  tibia (raccourci de la jambe levée vers la caméra, jambe tendue en appui) ; cuisse, pied et contours
  restent ceux de l'original ; la jambe levée se rapproche du centre d'un pixel.
- Avant-bras décalés d'un pixel en opposition avec les jambes ; le corps monte d'un pixel quand une
  jambe passe.
- Chaque pixel affiché vient de la pose d'origine : rien n'est redessiné ni lissé. Les sources et les
  planches validées ne changent pas.

**Prototype** : soldat de base, marche vers le bas, cycle de 4 images (contact, passage, contact
inverse, passage inverse), 7 images par seconde à la vitesse des compagnons (2 pas par cycle).
- `assets/art/soldier_walk_south.png` : le cycle seul ; `assets/art/soldier_pixellab_walk.png` : la
  planche du jeu (les autres directions gardent leur pose et leur balancement).
- En jeu, dans l'apparence PixelLab (F3) : **F4** bascule entre la marche balancée validée et ce
  prototype, ou `-- --skin=pixellab --walk-proto` au lancement. Apparence seulement, rien
  n'est enregistré.
- Comparaison dans `docs/art/soldat/` : `marche_bas_prototype.png` (pose d'origine puis les 4 images,
  agrandies six fois), `marche_bas_reference_pixellab.png` (la marche de face exportée par PixelLab
  avant l'arrêt, pour mémoire) et `marche_bas_en_jeu.png` (groupe descendant, taille réelle).

**Limites, à juger en jeu**
- L'amplitude est faible à cette taille : 1 à 3 px de jeu de jambes, 1 px de bras. Plus ample, la
  jambe levée devient une jambe trop courte au lieu d'un genou plié.
- Vue de face, le raccourci suffit. **De profil**, une jambe doit passer devant l'autre en
  s'inclinant : il faudra décaler les rangées de la jambe progressivement (pixels entiers, sans
  rotation) et redessiner quelques pixels de genou. C'est la direction la plus difficile ; à essayer
  avant de généraliser.

**Profil (ajouté le 03/11/2026, en attente de validation)** : même outil, mode « profile ».
- Dans la pose, les deux jambes se superposent. La jambe proche (pied compris) sert de modèle et est
  dessinée deux fois : la jambe éloignée en est la copie, assombrie avec les teintes de la jambe
  elle-même, et dessinée derrière le corps.
- Chaque jambe s'incline par un décalage progressif de ses rangées, de la hanche au pied (jusqu'à
  5 px), en marches d'un pixel : au contact, les jambes forment un compas ouvert ; au passage, la
  jambe levée perd deux rangées de tibia et le corps monte d'un pixel. La main avance et recule d'un
  pixel, en opposition avec la jambe proche.
- La gauche est le miroir de la droite, comme pour tous les profils du jeu.
- Captures : `docs/art/soldat/marche_profil_prototype.png` (pose puis 4 images, ×6) et
  `marche_profil_en_jeu.png` (groupe vers la droite, puis vers la gauche, taille réelle).
- Premier essai écarté : un modèle de jambe trop large (il prenait une partie de la jambe éloignée) et
  un pas de ±3 px, plus petit que la largeur de la jambe, donnaient des jambes emmêlées au contact.
- **Limites** : les jambes inclinées restent droites (pas de genou fléchi au contact) ; le dos du soldat
  garde le balancement ; il reste le dos (même technique que la face, attendue plus simple).

## 12. Marche du soldat reprise de celle du héros (03/11/2026, en attente de validation)

Décision du porteur du projet : les prototypes des sections 10 et 11 (balancement, puis membres
découpés) ne sont pas satisfaisants. Le soldat et le héros ont presque les mêmes proportions, et le
héros a une vraie marche PixelLab de 8 images : on la réutilise pour le soldat, sans rien générer.

**Méthode** (`tools/transfer_walk.gd`), image par image, sur la marche de face du héros :
- les **jambes** du héros sont gardées, chaque couleur ramenée à la plus proche de la palette du
  soldat (la jupe de la tunique devient un pagne un peu plus long que celui du soldat) ;
- la **tête**, le **torse** et les **bras** du soldat remplacent ceux du héros, recalés à chaque image
  sur son mouvement : le décalage de chaque partie est mesuré en la comparant à la pose fixe du héros
  (balancement de la tête, du buste, des bras). Ni bandeau, ni collier, ni tunique, ni
  protège-poignets ; mains vides ;
- la **massue** : tout ce qui dépasse sous le bras qui la tenait est effacé. Là où son manche croise
  la jambe gauche, cette jambe est refaite avec la jambe droite de l'image opposée du cycle (k + 4),
  jamais masquée, retournée en miroir autour de l'axe du corps de chaque image. Un premier essai, qui
  effaçait les couleurs du manche, entamait la jambe : écarté ;
- **case de 48 × 52** : la marche du héros, rebond compris, dépasse 48 px de haut ; les poses fixes y
  sont posées 2 px plus bas, si bien que l'ancrage aux pieds du jeu ne change pas (pieds à 1 px près
  de la ligne de la pose).

**En jeu** : apparence PixelLab (F3), puis **F4** pour cette marche vers le bas (8 images, 16 images par
seconde, comme le héros) ; dos et profil gardent le balancement. Le prototype de la section 11 est mis
de côté : ses fichiers restent dans le dépôt, il n'est plus affiché. Captures :
`docs/art/soldat/marche_bas_transfert.png` (pose du soldat puis les 8 images, ×4, ligne des pieds en
jaune) et `marche_bas_transfert_en_jeu.png` (groupe descendant, taille réelle).

**Limites** : pieds un peu plus foncés que ceux de la pose du soldat (ceux du héros, recolorés) ;
pagne un peu plus long ; la main gauche (à l'écran), refaite en miroir aux rangées basses, a l'ombrage
inversé. Pour les autres directions, la même méthode demandera ses réglages : de dos, la massue est
moins visible ; de profil, elle passe devant le corps, ce sera la direction la plus délicate.
