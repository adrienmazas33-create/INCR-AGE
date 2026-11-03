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
