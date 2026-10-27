# Échelle des personnages — étude et décision

Document de cadrage rédigé le 27/10/2026, après l'essai LPC de la zone témoin et l'étude d'échelle
laissée en plan dans `docs/art/echelle/` (planches 26 / 34 / 48 px).

**Question posée : faut-il augmenter la taille des personnages ?**

Réponse courte : oui, si l'on veut le rendu de l'essai LPC — mais **les personnages ne peuvent pas
grandir seuls**. Ce document chiffre le problème, compare trois combinaisons cohérentes et propose un
essai avant décision.

## 1. Mesures (état actuel)

| Élément | Taille | Rapport au héros |
|---|---|---|
| Héros | 26 px (31 avec la plume et l'ombre) | 1 |
| Cadre de sprite | 32 × 32 px, planches 6 × 3 | — |
| Case de terrain | 32 px | héros = **0,81 case** |
| Hutte (`hut_0`, `hut_1`) | 64 × 64 px | 2,46 |
| Chêne (`oak`) | 64 × 80 px | 3,08 |
| Bouleau (`birch`) | 56 × 88 px | 3,38 |
| Sapin (`pine`) | 44 × 96 px | 3,69 |
| Arbres de l'essai LPC | 130 à 150 px | 5 à 5,8 |
| Sanglier | 44 × 30 px | — |

Figure : `docs/art/echelle/scenarios_echelle.png` (trois panneaux, même décor, même échelle).
Références réelles : `docs/art/zone_temoin/incr_vue_large.png` (nos arbres) et
`docs/art/zone_temoin/apres_vue_large.png` (essai LPC, mêmes personnages).

## 2. Le constat

Rapports réalistes : une hutte fait environ 1,8 fois la taille d'un humain, un arbre 6 à 9 fois.

- **Héros / hutte = 2,46** : le héros n'est donc **pas** trop petit pour les huttes. Il est même
  relativement plus petit qu'en vrai ; c'est acceptable et lisible.
- **Héros / arbre = 3,1** : là, le rapport est faux. Nos arbres sont **deux fois trop courts**.

C'est ce qui explique l'impression laissée par l'essai LPC : ses arbres de 130 à 150 px rétablissent
un rapport de 5 à 6, et le monde paraît soudain grand. Le héros, lui, n'a pas changé.

**Conséquence directe** : agrandir le héros sans toucher au décor (panneau B de la figure) ne règle
pas le problème, il l'inverse — la hutte devient une tente et l'arbre un buisson. La bonne question
n'est pas « quelle taille pour le héros ? » mais **« quelle échelle pour le monde ? »**.

Le palier 34 px de l'étude précédente tombe entre deux combinaisons cohérentes et coûte exactement
le même prix qu'un passage à 48 ou 52 (mêmes planches à refaire, mêmes constantes à revoir) : il n'est
pas retenu comme candidat.

## 3. Trois combinaisons cohérentes

| | A — statu quo | B — héros seul ×2 | C — monde à l'échelle LPC |
|---|---|---|---|
| Héros | 26 px | 52 px | 48 à 52 px |
| Hutte | 64 | 64 (inchangée) | 96 à 120 |
| Arbres | 64 à 96 | 64 à 96 (inchangés) | 130 à 160 |
| Case | 32 | 32 | 32 (ou 48) |
| Lecture | style « Pikmin », assumé | monde en miniature | cohérent, proche de l'essai LPC |
| Coût | nul | élevé, pour un mauvais résultat | **élevé, mais c'est la seule voie cohérente** |

## 4. Ce que coûte réellement l'option C

**À redessiner**
- **20 planches de personnages** de 18 images (héros, 8 compagnons, 8 frondeurs, 2 villageois,
  1 lanceur rival) : 360 images à passer de 32 × 32 à 48 × 48, plus les 2 planches de sanglier.
- **7 végétaux** (3 feuillus, 1 sapin, 2 buissons, 1 souche) et leurs ombres.
- **25 décors** de `props.json` : huttes, maison longue, palissade, feu, totem, caisses, séchoir,
  rochers, roseaux, torches, bannière…

**À revoir dans le code** (constantes en pixels, pas en cases)
- portées de combat (88, 110, 130 px), laisses (110 / 150 px), rayon de ramassage (96 px) et de
  récolte (40 px), distances de détection et de fuite ;
- emprises de collision et tri en profondeur (`Entities`), points d'ancrage des décors ;
- paliers de zoom et cadrage de la caméra ;
- outil de test (`--route`, `--at`) : rien à changer, il raisonne en cases.

**À revoir dans la carte**
- densité : environ 5 500 arbres ; à l'échelle LPC, les forêts doivent être éclaircies et les
  sentiers élargis, sinon le monde devient un mur de feuillage ;
- campement : la place entre les huttes, les caisses et le feu a été composée pour des huttes de
  2 cases ; avec des huttes de 4 cases, tout le plan du camp est à refaire ;
- champ visuel : à 640 × 360, on voit 20 × 11 cases. Un héros de 52 px occupe 1,6 case au lieu de
  0,8 : le champ relatif diminue de moitié, ce qui change la sensation de exploration et de combat.

**Ce qui ne bouge pas** : la carte ASCII, la grille de collision en cases, la sauvegarde, les règles.

## 5. Recommandation

**Ne pas lancer la refonte sur une intuition, même juste.** Un lot d'essai, court et réversible,
répond à la question avec de vrais pixels :

1. **Lot d'essai (1 séance)** : personnages LPC (64 px, licence OGA-BY 3.0, usage commercial permis,
   crédits déjà en place) à la place du héros et de deux compagnons dans la zone témoin, arbres LPC
   déjà en place, **huttes et décors agrandis ×1,5** à titre provisoire. On joue cinq minutes.
2. **Si l'essai convainc** : plan de conversion en un lot par famille (personnages, végétaux, décors,
   constantes), avec arrêt pour validation à chaque fois. La question du dessinateur se pose alors :
   redessiner 360 images à la main n'est pas à ma portée au niveau attendu ; un pack libre en 32 px
   (personnages de 64 px) ou un pixel artiste payant sont les deux options réalistes.
3. **Si l'essai ne convainc pas** : rester à 26 px, et corriger uniquement les arbres (les monter à
   110-130 px) — c'est le seul défaut de proportion réellement mesuré.

## 6. Décision

- [ ] à remplir après l'essai
