# INCR-AGE — Diagnostic de l'expérience de jeu et feuille de route (03/11/2026)

Réorientation décidée par le porteur du projet : le gameplay avant les ressources graphiques. Les
travaux PixelLab restent dans le dépôt à titre d'archives (`assets/source/pixellab/`, `tools/pack_pixellab.gd`,
`tools/animate_walk.gd`, `tools/transfer_walk.gd`, touches F3 et F4) ; le jeu se lance toujours avec
les personnages classiques et leurs animations d'origine, sans rien à rétablir.

## 1. Ce que le jeu offre aujourd'hui

- **Boucle** : on part du camp, on cherche des ennemis, le groupe combat seul, on ramasse le butin, on
  revient acheter une amélioration au feu de camp.
- **Sources de ressources** : uniquement les ennemis (8 jeunes sangliers, 3 grands, 3 lanceurs, qui
  réapparaissent 45 s après leur mort, hors de vue) et le revenu du camp capturé (1 vivre + 1 matériau
  par minute, plafonné à 10).
- **Améliorations** : 4 lignes (RECRUE, FORCE, AIMANT, VIGUEUR), 18 niveaux en tout. Tout acheter coûte
  environ **118 vivres, 89 matériaux et 8 savoirs**.
- **Rythme estimé** : un tour de carte (2 min 30 de marche, plus les combats) rapporte environ 30 vivres,
  20 matériaux et 2 savoirs. Tout est donc acheté en **15 à 25 minutes**, et le campement atteint son
  dernier stade (VILLAGE) vers la moitié de ce temps.
- **Après** : plus rien à acheter, à découvrir ni à conquérir. Le jeu s'arrête de fait.

## 2. Diagnostic

**Ce qui fonctionne**
- Les déplacements (clavier et souris), la caméra, la boussole du camp : précis et agréables.
- La lisibilité des combats : charge annoncée du sanglier, pierres esquivables, impacts, butin qui jaillit.
- Le groupe qui suit, se met en formation et combat seul : l'armée existe vraiment à l'écran.
- La progression strictement active, sans gestion fastidieuse : conforme aux piliers.

**Ce qui manque le plus**
1. **Le héros n'agit pas** : il se déplace, mais il attaque seul. Aucune décision en combat, aucun geste
   spectaculaire. Avec 8 compagnons, les combats durent moins d'une seconde.
2. **L'exploration ne rapporte rien en soi** : la carte de 120 × 100 cases n'a ni lieux à découvrir, ni
   récompenses cachées, ni dangers croissants. Seuls comptent les repaires et le camp rival.
3. **La progression est courte et plate** : 4 lignes d'améliorations en pourcentage, terminées en
   20 minutes ; les stades du campement ne débloquent rien de jouable ; aucun horizon (âge suivant).
4. **L'armée ne fait pas de choix** : lance ou fronde changent peu l'issue ; pas de progression des
   soldats ; rien ne demande d'adapter sa troupe.
5. **Le monde ne résiste pas** : mêmes ennemis partout, même difficulté près du camp et au bout de la
   carte ; la difficulté « géographique » voulue par la conception n'existe pas encore.

## 3. Les cinq améliorations proposées

Classées par rapport plaisir / effort. Chacune tient en un ou deux lots testables et s'appuie sur des
décisions déjà actées dans `docs/BIBLE_SYNTHESE.md`.

1. **Un monde qui se durcit avec la distance** (difficulté géographique). Trois cercles autour du camp :
   ennemis plus solides, plus nombreux et mieux récompensés à mesure qu'on s'éloigne ; un champion par
   zone (grand sanglier, chef lanceur), visible de loin. Rééquilibrage de l'armée à 8 compagnons du
   même coup. *Effet : chaque sortie a un but, l'armée redevient nécessaire.*
2. **Une compétence active du héros** (prévue par la conception : « une ou deux compétences actives »).
   Une seule pour commencer, à la souris ou à la barre d'espace, avec un temps de recharge : par
   exemple un coup de massue circulaire qui renverse les ennemis proches, ou un cri qui galvanise la
   troupe quelques secondes. *Effet : une décision en combat, un moment spectaculaire, le héros compte.*
3. **Des récompenses d'exploration**. Des lieux à découvrir une fois (pierre levée, grotte, ancien
   foyer) qui donnent du savoir ou un bonus durable, et des ressources à récolter en passant (buissons à
   baies, gisements de silex) qui repoussent lentement. *Effet : marcher vers l'inconnu paie, la carte
   devient une carte au trésor ; les matériaux ne dépendent plus que des combats.*
4. **Une civilisation qui débloque, pas seulement qui grandit**. Chaque stade du campement ouvre
   quelque chose de jouable (une nouvelle ligne d'amélioration, un nouveau rôle, la compétence du héros
   améliorée), et le dernier stade fixe le grand objectif de l'âge : préparer le passage à l'âge
   suivant. Courbe de coûts allongée en conséquence. *Effet : un horizon, des paliers attendus.*
5. **Une armée qui évolue avec le joueur**. Les soldats gagnent de l'expérience et passent vétérans
   (marque visible, un peu plus forts), et les rôles se complètent nettement (lances contre les
   charges, frondes contre les tireurs). *Effet : attachement à sa troupe, choix de composition.*

Volontairement écartés pour l'instant : arbres de technologie, gestion d'économie, quêtes, carte du
monde, nouvelles époques complètes. Ils viendront une fois cette boucle solide.

## 4. Feuille de route priorisée

Un lot à la fois, testé, poussé sur GitHub, avec arrêt pour validation.

| Lot | Contenu | Pourquoi d'abord |
|---|---|---|
| **G1** | Zones de difficulté autour du camp, ennemis renforcés selon la zone, champion visible par zone, rééquilibrage à 8 compagnons | Effet immédiat sur l'intérêt des sorties et des combats, peu de nouveaux systèmes |
| **G2** | Première compétence active du héros (une seule), avec son effet visuel et sonore | Rend les combats vivants et le héros acteur |
| **G3** | Lieux à découvrir et ressources à récolter, signalés sobrement | L'exploration récompensée, les matériaux moins dépendants des combats |
| **G4** | Stades du campement qui débloquent (une nouveauté jouable par stade), courbe de coûts allongée, objectif « âge suivant » annoncé | Le sentiment de progression sur la durée |
| **G5** | Expérience et vétérans, rôles mieux différenciés | Profondeur de l'armée, une fois que le monde la met à l'épreuve |

Ensuite seulement : le passage effectif au deuxième âge (nouvelle apparence du camp et de l'armée,
nouveaux ennemis, thème musical réarrangé).

## 5. Méthode graphique retenue

- Personnages classiques et leurs animations d'origine, générés par `tools/generate_art.gd`.
- Les nouveautés visuelles (champions, lieux, ressources, effet de la compétence) sont produites de la
  même façon : pixel art procédural, scripts Godot, retouches locales, dans la palette de la voie C.
- Priorité à la lisibilité et à l'homogénéité ; animations volontairement simples.

## 6. Lot G1 : un monde qui se durcit avec la distance (03/11/2026, validé)

**Ce qui change** (`scripts/world/danger_zones.gd`, `scripts/world/enemy_spawner.gd`,
`scenes/enemies/champion_mark.gd`) :
- Trois cercles autour du feu de camp, en cases :
  - **terres proches** (moins de 40) : rien ne change (3 repaires de jeunes sangliers, le lanceur isolé) ;
  - **terres sauvages** (40 à 50) : vie ×1,6, dégâts ×1,3, butin ×1,5, chance de savoir ×1,5 ;
  - **terres hostiles** (au-delà de 50, dont le camp rival) : vie ×2,4, dégâts ×1,6, butin ×2, savoir ×2.
- **Deux champions**, des grands sangliers : au nord-ouest (terres sauvages) et à l'est (terres hostiles).
  En plus du renfort de leur zone : vie ×1,8, butin ×2, savoir toujours lâché, réapparition après
  3 minutes au lieu de 45 s. Un crâne cornu flotte au-dessus d'eux et un cercle rouge marque le sol :
  on les repère de loin.
- Un bandeau annonce le passage d'une zone à l'autre (avec une marge, pour éviter les annonces en rafale).
- Chaque ennemi reçoit une copie renforcée de ses caractéristiques à son apparition : les fiches de
  `data/units/` ne changent pas. Rien de nouveau dans la sauvegarde.

**Essais en jeu** (8 compagnons, héros immobile : il n'esquive aucune charge) :

| Groupe | Champion des terres sauvages | Champion des terres hostiles |
|---|---|---|
| 8 compagnons, aucune amélioration de force ni de vigueur | abattu | le héros tombe, retour au camp sans rien perdre |
| Améliorations au maximum | abattu | abattu (héros à 90/96 PV) |

Un premier réglage (vie ×2,5, dégâts ×1,25) rendait les deux champions imbattables même avec un groupe
au maximum : écarté. Le butin du champion, d'abord ×3, rapportait près de 30 vivres d'un coup : ramené
à ×2.

**À juger en jouant** : la difficulté réelle en esquivant les charges, la lisibilité des marques, le
rythme de l'économie. Les zones lointaines rapportent plus : la progression actuelle (environ 20 min)
raccourcit un peu, ce que le lot G4 rallongera.

Tour complet de la carte (8 compagnons, parcours de test qui ne s'arrête pas pour combattre) :
149,8 s comme avant, 60 FPS, aucune erreur ; 7 retours forcés (référence : 4 à 6) et un compagnon
une fois distancé de 771 px : les combats plus longs des zones lointaines retiennent la troupe pendant
que le héros poursuit sa route. Captures : `docs/art/g1/` (bandeau des terres sauvages, champion de
l'est et son crâne vu de loin).

## 7. Lot G2 : FRAPPE CIRCULAIRE, première compétence active du héros (03/11/2026, validé)

**Commandes** : **ESPACE**, ou le **clic droit** (le clic gauche reste au déplacement à la souris).

**Effet** (`scripts/combat/sweep_strike.gd`) : le héros tourne sur lui-même et frappe tous les ennemis
à portée de massue autour de lui (26 px entre les corps, environ une case), sans viser :
- dégâts : 2,5 fois son coup (amélioration FORCE comprise), soit 17 à 31 ;
- recul net de chaque ennemi touché ;
- **interruption** : un sanglier qui prépare ou mène sa charge est arrêté et reste étourdi 0,9 s ; un
  lanceur qui arme son tir le perd, et le suivant est retardé d'autant ;
- recharge de **6 secondes**.

**Sensations** : tour sur lui-même avec les images classiques (droite, face, gauche, dos), lueur dorée,
arc blanc et or qui balaie le sol en un éclair puis s'efface, poussière soulevée, étincelles sur chaque
ennemi touché ; une seule micro-pause (0,06 s) et une légère secousse, quel que soit le nombre
d'ennemis ; son de souffle et choc sourd (`assets/audio/sfx/sweep.wav`, produit par
`tools/generate_sfx.gd` ; les autres sons restent identiques).

**Indicateur** (`scenes/ui/skill_slot.gd`) : petite case en bas au centre, avec une flèche circulaire et
le rappel « ESPACE » ; en recharge, un voile sombre la couvre et se retire ; prête, elle brille un instant.

**Code réutilisable** : `ActiveSkill` (recharge, déclenchement, signaux) porte tout ce qui est commun ;
une compétence ne décrit que son effet. Les ennemis exposent `stagger()` pour être interrompus.

**Essais au contact** (héros posé sur le repaire, la compétence déclenchée dès qu'un ennemi est à portée,
option `--auto-skill` de l'outil de test) :

| Situation | Sans la compétence | Avec |
|---|---|---|
| Jeune sanglier, 4 compagnons | abattu, héros à 52/60 PV | abattu, héros intact (charge brisée) |
| Lanceur isolé, 4 compagnons | abattu | abattu, frappé une fois |
| Champion de l'est, groupe au maximum | le héros tombe, le champion survit | champion abattu ; la frappe ne lui retire qu'environ 9 % de sa vie par coup |

La compétence sert à se dégager et à briser une attaque ; les compagnons font l'essentiel des dégâts,
et un champion ne tombe pas sous la seule frappe.

**Sans régression** : tour complet de la carte (sans utiliser la compétence) identique à celui du lot
G1 : 149,8 s, 60 FPS, mêmes chiffres de suivi, aucune erreur. Déplacements, attaques automatiques,
formation et sauvegarde inchangés ; rien de nouveau n'est enregistré. Captures : `docs/art/g2/`
(frappe en pleine mêlée ; indicateur prêt, puis en recharge).

**Non vérifié par un vrai clic** : le déclenchement au clic droit (seules les touches sont simulées par
l'outil de test) ; à confirmer en jouant.

## 8. Lot G3 : récompenses d'exploration (05/11/2026, validé et publié le 06/11/2026)

**Lieux à découvrir** (`scripts/world/exploration.gd`, `scenes/props/landmark.gd`) : sept lieux posés
sur des clairières dégagées, dans les trois zones. Le héros qui passe à moins de 40 px découvre le lieu :
bandeau à son nom, éclat de lumière, arpège, et la récompense jaillit au sol, ramassée par l'aimant du
groupe comme le butin. Tant qu'il n'est pas découvert, une étincelle dorée le signale de temps en temps.

| Lieu | Où | Terres proches / sauvages / hostiles |
|---|---|---|
| Pierre levée (3) | ouest, nord, sous le plateau à l'est | savoir 1 / 2 / 3 |
| Ancien foyer (2) | sud, sud-est | vivres 3 / 5 / 8, savoir 1 / 1 / 2 |
| Ossements de mammouth (2) | ouest lointain, est | matériaux 3 / 5 / 8, savoir 1 / 1 / 2 |

Une seule récompense par lieu : les découvertes sont enregistrées (champ facultatif `discoveries` de
la sauvegarde, identifiants validés au chargement ; une ancienne sauvegarde n'en a aucun).

**Ressources à récolter** (`scenes/props/harvest_spot.gd`) : 29 buissons portent des baies, 7 rochers des
éclats de silex. En les frôlant, le héros les cueille : 1 vivre ou 1 matériau dans les terres proches,
2 au-delà, qui jaillissent au sol. Les baies repoussent en 90 s, le silex en 120 s. Dans les zones
témoins, ce sont les buissons que la voie C dessine déjà avec des baies : cueillis, ils les perdent,
puis les retrouvent. Leur état n'est pas enregistré (tout est mûr au lancement).

**Essais** (copies de sauvegardes de test) :
- ancien foyer du sud découvert : +3 vivres et +1 savoir ramassés ; découverte enregistrée aussitôt, et
  toujours là après une relance (pas de seconde récompense) ;
- baies hors zone témoin : 1 récolte, +1 vivre ; dans le camp : 1 récolte ;
- silex au pied du plateau (terres sauvages) : 1 récolte, +2 matériaux.
- Premier dessin du foyer trop discret dans l'herbe (`docs/art/g3/lieux_avant_retouche.png`) : redessiné
  avec un cercle de pierres éclairées, une bûche calcinée et deux braises ; éclats de silex grossis.

**Non vérifié à l'œil** : l'échange d'image d'un buisson à baies de la voie C une fois cueilli (le
buisson testé était caché par les arbres ; la récolte, elle, est comptée).

**Sans régression** : tour complet de la carte identique à celui du lot G2 (149,8 s, 60 FPS, mêmes
chiffres de suivi, aucune erreur ; 46 nœuds de plus pour les lieux et les ressources). Le parcours de
test suit les chemins et ne frôle ni lieu ni ressource. Captures : `docs/art/g3/` (pierre levée,
ossements, ancien foyer ; baies ; silex avant et après la cueillette).

## 9. Lot G4 : une civilisation qui débloque (06/11/2026, en attente de validation)

**Un déblocage par stade** (`scripts/progression/upgrades.gd`, `scenes/ui/camp_panel*.gd`) : le panneau
du feu de camp montre désormais sept lignes (touches 1 à 7). Celles qu'un stade n'a pas encore ouvertes
restent visibles, grisées, avec le stade qui les ouvrira : le joueur voit ses prochains paliers.

| Stade (prospérité) | Ce qu'il ouvre |
|---|---|
| CAMPEMENT (0) | RECRUE, FORCE, AIMANT, VIGUEUR (inchangées) |
| TRIBU (3) | **FRAPPE** : la recharge de la FRAPPE CIRCULAIRE passe de 6 s à 5,25 / 4,5 / 3,75 / 3 s (4 niveaux) |
| VILLAGE (8) | **RECOLTE** : +1 vivre ou matériau par cueillette et repousse 20 % plus rapide, par niveau (3 niveaux) ; **AGE DES METAUX**, le grand objectif de l'âge |

Les seuils des stades n'ont pas bougé (les campements déjà construits restent au même stade). Chaque
passage de stade annonce ce qu'il ouvre (« NOUVELLE AMELIORATION - FRAPPE », puis au village
« NOUVELLE AMELIORATION - RECOLTE » et « OBJECTIF - AGE DES METAUX ») ; les bandeaux rapprochés passent
désormais l'un après l'autre au lieu de se recouvrir.

**Objectif « âge suivant »** : AGE DES METAUX, dernière ligne du panneau, détachée par un filet doré, en
trois étapes (60 / 90 / 135 vivres et matériaux, 6 / 10 / 14 savoirs). Chaque étape a son bandeau
(« AGE DES METAUX 1/3 ») ; la dernière est un grand moment (rayons, éclat d'écran, son du stade,
« AGE DES METAUX - TRIBU PRETE »). Le passage effectif à l'âge suivant n'est **pas développé** : l'objectif
atteint est enregistré (niveau 3 de la ligne `age` dans la sauvegarde) et le panneau affiche
« TRIBU PRETE ». Il ne compte pas dans la prospérité.

**Courbe allongée** : FORCE monte à 8 niveaux (au lieu de 5), VIGUEUR à 6 (au lieu de 4), mêmes formules
de coût ; les niveaux déjà achetés coûtent exactement pareil. Tout acheter demande désormais environ
**580 vivres, 570 matériaux et 72 savoirs**, contre 118, 89 et 8 avant le lot (dont 280, 280 et 30 pour
l'objectif de l'âge). Estimation, à juger en jouant : avec les zones lointaines et les récoltes, une
heure de jeu environ au lieu de 20 minutes ; le savoir (ennemis, lieux à découvrir) devient la ressource
qui rythme la fin.

**Sauvegardes** : aucun champ nouveau ; les lignes `skill`, `harvest` et `age` s'ajoutent aux
améliorations enregistrées. Une ancienne partie se charge telle quelle (essai : groupe au maximum de
l'ancienne courbe, FORCE et VIGUEUR rachetables au-delà, coûts conformes).

**Essais** (copies de sauvegardes de test) :
- stade TRIBU : FRAPPE ouverte, RECOLTE et AGE DES METAUX grisées « STADE VILLAGE » ;
- passage au VILLAGE par un achat de FRAPPE : bandeau du stade puis les deux annonces, dans l'ordre ;
  RECOLTE puis les trois étapes de l'objectif achetées, ressources débitées exactement, objectif
  enregistré, panneau « TRIBU PRETE » ;
- FRAPPE au maximum : recharge de 3 s ;
- RECOLTE au maximum : silex à +5 matériaux (contre +2), repoussé et recueilli avant 50 s (120 s sans).

**Sans régression** : tour complet de la carte inchangé (149,6 s, 60 FPS, 7 retours forcés comme aux lots
G1 à G3, aucune erreur).

Captures : `docs/art/g4/` (panneau au stade TRIBU, panneau au VILLAGE avec l'objectif atteint, bandeau
de l'objectif).
