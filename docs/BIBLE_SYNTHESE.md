# Synthèse de la conception — export ChatGPT du 27/10/2026

Source : `ChatGPT_INCR-AGE_20261027-1844.pdf`, 197 pages, conversation du 21/10/2026 00 h 05 au
23/10/2026 17 h 58. Ce document ne recopie que **les décisions de conception** ; il ne remplace pas la
conversation d'origine, il la rend utilisable.

Limite connue : l'export s'arrête au 23/10 au soir, au moment où les limites d'utilisation de Claude
ont été atteintes. **La fin de la conception et le début du chantier ne sont donc pas couverts** ;
`PROGRESS.md` prend le relais pour tout ce qui est construit.

## Le jeu en une phrase

Un jeu incrémental de conquête : un chef de tribu, suivi de sa petite armée, explore une planète,
fait évoluer sa civilisation de la préhistoire à l'espace et repousse les civilisations rivales.

## Les piliers, dans les mots du porteur du projet

- « Une idée de jeu qui me motiverait à être développée sur la durée, pas comme les autres essais » (21/10, 00 h 49).
- « J'aime bien le côté incrémental […] gérer des petites armées qui s'affrontent, pouvoir les agrandir et les améliorer » (21/10, 00 h 30).
- « Ça reste plutôt léger » : une mécanique doit apporter du plaisir, sinon elle sort (21/10, 01 h 36 et 02 h 10).
- « Le design général n'est pas le rendu final » : l'art actuel est provisoire (21/10, 16 h 25).

## Décisions validées

| Sujet | Décision | Source |
|---|---|---|
| Monde | Petite planète que l'on peut faire le tour **en 20 à 30 minutes à pied**, hors obstacles et combats | 21/10, 01 h 51 |
| Exploration | Libre, par visibilité naturelle et reliefs ; de nouveaux environnements s'ouvrent avec la technologie | 21/10, 02 h 03 et 02 h 06 |
| Évolution | Ères technologiques façon *Age of War* : hommes des cavernes, puis métal, machines, jusqu'à l'espace ; transitions visibles | 21/10, 00 h 49 |
| Armée | Croissance par trois systèmes combinés (civilisation, recrutement, événements) ; pertes hybrides entre simples soldats et vétérans ; pas de microgestion | 21/10, 01 h 12 et 01 h 15 |
| Dynastie | Le héros vieillit ; succession choisie parmi **2 ou 3 descendants maximum** ; temps hybride (naturel pendant l'aventure, sauts aux grandes étapes) | 21/10, 01 h 23 à 01 h 31 |
| Progression | **Exclusivement active** : rien n'avance jeu fermé, la civilisation travaille pendant l'exploration | 21/10, 01 h 39 |
| Difficulté | Principalement **géographique** ; les civilisations ennemies évoluent légèrement avec le temps | 21/10, 01 h 48 |
| Ton | Charmant et légèrement humoristique, devenant épique et mystérieux ; aliens verts sur Mars pour la blague ; **boss final : l'Univers lui-même** | 21/10, 01 h 55 et 02 h 10 |
| Boucle | Grands objectifs de civilisation, pas de quêtes secondaires ni de marqueurs partout | 21/10, 02 h 14 |
| Rendu | **2D pixel art à plat**, après abandon de la 3D sphérique : « intemporel, plus simple à faire et à adapter aux différents formats PC, consoles et smartphones » | 21/10, 02 h 40 |
| Contrôles | Le héros se déplace, l'attaque est automatique, une ou deux compétences actives selon la progression ; la souris doit suffire à la majorité des actions | 21/10, 13 h 47 et 23 h 43 |
| Audio | Ambiance douce et répétitive façon *Minecraft*, teinte rétro *Zelda* / *Pokémon* ; réglages de volume par catégorie | 21/10, 23 h 53 et 22/10, 01 h 39 |

## Ce que le prototype fait déjà

Déplacements, caméra, suivi de troupe, combat automatique, butin, améliorations au feu, évolution du
camp en trois stades, camps ennemis capturables, sauvegarde, audio complet. Conforme aux piliers :
léger, sans microgestion, sans progression hors jeu.

## Ce qui reste, et qui vient de cette conception

1. **Les ères technologiques** : c'est le cœur de l'identité du jeu et rien n'en est construit. Le
   motif musical signature ré-sol-la-si a été écrit pour être réarrangé par époque.
2. **La dynastie** : âge du héros, descendants, choix de l'héritier. Touchera la sauvegarde (génération).
3. **Les classes militaires et les machines** : aujourd'hui il n'y a que lance et fronde.
4. **Les compétences actives** du héros (une ou deux).
5. **La planète** : la 3D sphérique a été abandonnée, mais la circularité et les biomes débloqués par la
   technologie restent dans la conception. Le prototype est une carte plate de 120 × 100 cases.
6. **La carte du monde et la mini-carte** : reportées, et toujours pas faites.

## Points à trancher

- **La forme du monde.** Une planète dont on fait le tour en 20-30 minutes suppose un monde **bouclé**
  (bords qui se rejoignent), alors que la carte actuelle est un rectangle borné. À décider avant
  d'étendre le monde : bouclage horizontal, monde fini avec bords, ou île unique.
- **La référence visuelle.** *When Chests Rain Tons of Loot* est un jeu **isométrique** en pixel art,
  alors que le prototype est en vue 3/4. Si c'est bien son rendu qui plaît, la question de la
  projection (isométrique ou non) se pose avant celle de la taille des personnages.
- **L'échelle.** Liée à la cible « PC, consoles, smartphones » : voir `docs/ECHELLE_PERSONNAGES.md`.

## Ce qui manque de l'export

Rien d'essentiel. L'export s'arrête au 23/10 17 h 58, quand les limites d'utilisation de Claude ont
été atteintes ; le fil a repris dans Claude Code, puis dans la session du 27/10. Les décisions prises
entre-temps ne sont pas perdues : elles sont dans le dépôt, sous forme de lots validés, de tags et de
plans (`PROGRESS.md`, `docs/ROADMAP.md`, `docs/WORLD_ART_PLAN.md`, `docs/ART_DIRECTION_PLAN.md`).

Autrement dit : la conception de ce document s'arrête avant la campagne artistique, mais **la
campagne artistique elle-même est documentée ailleurs**. Ce fichier ne la remplace pas ; il rappelle
seulement pourquoi le jeu existe et où il va.
