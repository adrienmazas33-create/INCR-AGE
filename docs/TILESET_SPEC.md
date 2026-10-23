# INCR-AGE — Fiche technique du jeu de tuiles original (voie C)

Rédigée le 23/10/2026, après l'essai LPC de la zone témoin (`docs/WORLD_ART_PLAN.md`, section 8).

Cette fiche sert de cahier des charges, que les tuiles soient dessinées :
- par toi ;
- par un pixel artiste ;
- par moi, pixel par pixel.

Elle couvre **le monde jouable de l'ère préhistorique** : sols, eau, reliefs, végétation et petits décors. Elle ne couvre ni les personnages, ni l'interface, ni les bâtiments du camp, qui viendront ensuite avec la même palette.

**Contraintes inchangées**
- La carte ASCII et sa géographie restent telles quelles.
- Les collisions restent à la case, comme dans `TerrainBuilder`.
- Les règles de déplacement et le gameplay ne bougent pas.

Seul le **rendu** change.

## 1. Intentions

- Une nature **chaude, organique, accueillante**, qu'on a envie d'explorer longtemps. Rien de géométrique, aucune grille visible.
- Trois couches de lisibilité, reprises de `docs/ART_DIRECTION_PLAN.md` :
  - le sol, calme et peu contrasté ;
  - les personnages, le butin et les ennemis, contrastés ;
  - les effets, lumineux et brefs.
- Ce que l'essai LPC a montré et qu'il faut obtenir :
  - herbe en touffes ;
  - berges herbeuses qui débordent sur l'eau ;
  - bords irréguliers ;
  - arbres en volume, avec leur ombre.
- Ce qu'il faut éviter (limites de LPC) :
  - des objets à une échelle plus grande que nos personnages ;
  - des transitions d'une case en blocs carrés ;
  - un style générique.

## 2. Format

| Point | Règle |
|---|---|
| Taille de tuile | **32 × 32 px**, dessinées à l'échelle 1 : un pixel de dessin vaut un pixel de jeu, comme nos personnages |
| Vue | Vue de dessus en 3/4, comme aujourd'hui : les faces verticales (falaises, troncs, huttes) se voient de face |
| Lumière | En haut à gauche. Ombres portées vers le bas à droite. |
| Contours | **Aucun contour noir sur le terrain.** Les formes se lisent par la valeur (clair / foncé). Contour sombre teinté seulement sur les objets qui se détachent : arbres isolés, rochers, souches. |
| Couleurs | Palette fermée de **48 couleurs au plus** (proposition de la section 3 : 44). Toute couleur hors palette est refusée. |
| Tramage | Seulement pour de petites zones (reflets d'eau, mousse). Pas de tramage sur de grandes surfaces. |
| Format de fichier | PNG 32 bits, fond transparent, sans compression avec perte. Import Godot : filtre « Nearest », sans mipmaps (réglage déjà par défaut du projet). |

## 3. Palette (proposition à valider)

Les dégradés suivent un **décalage de teinte** : les tons foncés tirent vers le bleu-violet, les tons clairs vers le jaune. Les sols sont 10 à 20 % moins saturés que les personnages.

| Matière | Du plus foncé au plus clair |
|---|---|
| Herbe | `#2f4f2c` `#3e6a35` `#527f3d` `#6b9648` `#8fae58` `#b8c46e` |
| Feuillage | `#1f3a2e` `#2d5236` `#3f6d3c` `#5e8a44` `#86a650` |
| Conifères | `#1b3330` `#274a3d` `#376147` `#4f7a52` |
| Terre / chemins | `#4a3226` `#6b4a33` `#8c6542` `#ab8456` `#c7a26e` |
| Sable / berge sèche | `#9c8358` `#bfa676` `#dbc796` |
| Roche (falaises) | `#3a3540` `#524a52` `#6d6466` `#8b827c` `#ada296` `#cfc4b2` |
| Eau | `#1d3b52` `#24557a` `#2f6f96` `#4a8fb0` `#7db6c8` `#cfe8e6` (écume) |
| Écorce et bois | `#3b2a22` `#5a3f2c` `#7a5638` |
| Accents | Fleurs : `#e8d36a` `#e39a5b` `#c9a3d6` `#f2efe2`. Champignons : `#c4573f`. |
| Ombre portée | `#1a1a2e` à 35 % d'opacité, une seule couleur pour tout le monde |

Livrable : un fichier `palette.gpl`, lisible par LibreSprite, Aseprite, Pixelorama et GIMP, à créer **avant** de dessiner.

## 4. Échelle de référence

Notre personnage mesure **26 px** (environ 0,8 case). Tout se dessine par rapport à lui.

| Élément | Taille visée |
|---|---|
| Touffe d'herbe, caillou, fleur | 4 à 10 px |
| Buisson | 20 à 28 px de large (moins d'une case) |
| Rocher | 16 à 32 px |
| Souche, tronc couché | 1 à 2 cases de long |
| Arbre feuillu | Couronne de 48 à 64 px de large, **64 à 88 px** de haut au total (2 à 2,75 cases). Tronc de 8 à 10 px de large. |
| Conifère | 32 à 44 px de large, 80 à 96 px de haut |
| Hutte (rappel) | 2 cases de large environ |
| Face de falaise | 2 rangées de cases de haut, comme la carte actuelle (`v`) |

Les arbres LPC (96 px de large, 130 à 150 px de haut) sont la mesure de **ce qu'il ne faut pas faire**.

## 5. Système de terrain : la grille double (dual grid)

**Principe.** La carte reste découpée en cases (herbe, terre, eau, etc.), et les collisions restent à la case. Seul l'affichage change :
- on pose les tuiles d'affichage **décalées d'une demi-case** ;
- chaque tuile d'affichage est choisie d'après les **4 cases** qui l'entourent.

Pour une paire de terrains (un « dessus » posé sur un « fond »), il suffit donc de **16 tuiles**, une par combinaison des 4 coins. Les transitions d'une seule case, les diagonales et les coins rentrants sont tous couverts. Ce sont les défauts de LPC qui disparaissent.

**Planche d'une paire** : 4 × 4 tuiles (128 × 128 px). La position de chaque tuile est donnée par son numéro de coins :
- coin haut-gauche = 1 ;
- haut-droite = 2 ;
- bas-gauche = 4 ;
- bas-droite = 8.

La tuile d'indice `n` (somme des coins couverts par le terrain du dessus) se place à la colonne `n % 4`, rangée `n / 4`. La tuile 0 est le fond seul, la tuile 15 le dessus plein.

**Règles de dessin des bords**
- Le bord ne suit jamais le milieu exact de la tuile : il ondule de ± 3 à 5 px.
- Il doit pourtant **raccorder** exactement d'une tuile à l'autre. Les points d'entrée sur chaque côté sont fixes, à 10 et 22 px.
- Une frange de 2 à 3 px de transition : touffes d'herbe qui débordent, cailloux sur le bord des chemins.

**Paires nécessaires**

| Paire (dessus sur fond) | Usage | Priorité |
|---|---|---|
| Terre sur herbe | Chemins, camp | Zone témoin |
| Eau sur herbe | Rivière, lac (berge herbeuse débordante) | Zone témoin |
| Sable sur herbe | Plages, sable de la carte | Ensuite |
| Eau sur sable | Berges sableuses | Ensuite |
| Plateau sur herbe | Sommet des plateaux (lèvre herbeuse) | Avec les falaises |

**Remplissages** (tuile 15, pleine) : **4 à 6 variantes** par terrain, dont 1 ou 2 « à détail » plus rares (motte, petite fleur), choisies au hasard mais de façon reproductible. Leur placement est pondéré pour qu'aucun motif répété ne se voie.

## 6. Eau

- **Eau profonde** : 4 images d'animation, en boucle, à 6 ou 8 images par seconde. Reflets en petits traits clairs qui se déplacent lentement, sans clignotement.
- **Hauts-fonds** : une bande plus claire d'environ 6 px le long des berges, intégrée aux tuiles de la paire « eau sur herbe ».
- **Écume** : une couche par-dessus, animée sur 4 images, qui suit la berge.
- **Décors d'eau** (objets, pas tuiles) : nénuphars (2), roseaux (3), rocher dans l'eau (2), bois flotté (1).
- Le **pont** reste un objet posé par-dessus, redessiné plus tard dans la même palette.

## 7. Falaises et plateaux

La carte a des plateaux (`#`), une face de 2 rangées sous leur bord sud (`v`), des escaliers (`^`) et des rebords fins à l'est, à l'ouest et au nord. Les collisions ne changent pas : les rebords restent des bandes de 6 px.

| Tuile | Variantes |
|---|---|
| Lèvre supérieure (herbe qui déborde sur l'arête) | 3 |
| Face haute (strates de roche horizontales, irrégulières) | 3 |
| Face basse (pied, avec éboulis) | 3 |
| Coins convexes arrondis, gauche et droite, haut et bas | 4 |
| Coins rentrants | 2 |
| Rebords est, ouest et nord (arête vue de dessus, pierres) | 3 × 2 |
| Escalier taillé dans la roche (haut, bas) | 2 |
| Ombre portée au pied de la face | 1, en couche séparée |

Pour rompre la ligne droite d'une longue face, on ajoute :
- des **décors de falaise** : racines, lierre, touffe accrochée, rocher tombé ;
- des variantes de face posées sans motif régulier.

## 8. Végétation et décors

**Arbres** (objets triés en profondeur, chacun avec son ombre au sol dessinée à part)

| Élément | Nombre |
|---|---|
| Feuillus | 3 formes |
| Conifères | 2 formes |
| Arbre mort ou chandelle | 1 |
| Buissons | 3, dont 1 à baies |
| Souche | 1 |
| Tronc couché | 1 |
| Fougères | 2 |

**Forêts denses.** Un bloc de forêt n'est plus « un arbre par case ». C'est :
- une **canopée** en tuiles, avec la paire « canopée sur herbe » de la grille double ;
- des **arbres de lisière** posés devant, en objets, de façon irrégulière ;
- quelques buissons et fougères au pied.

Le bord de la forêt devient ainsi un contour végétal, plus du tout un rectangle.

**Décalques au sol** (sans collision, posés en grappes) :
- touffes d'herbe (6) ;
- fleurs (4 couleurs) ;
- cailloux (4) ;
- feuilles mortes (2) ;
- champignons (2) ;
- trous ou terriers (1) ;
- ossements (1, pour la touche préhistorique).

**Règles de placement**
- En grappes, jamais en semis régulier.
- Plus denses en lisière de forêt et le long des chemins.
- Rares au milieu des prairies.
- Absents sous les bâtiments et sur les chemins tassés du camp.

## 9. Lumière et ombres

- Une seule couleur d'ombre (section 3), toujours portée vers le bas à droite.
- Chaque arbre, rocher, buisson et bâtiment a son ombre, dessinée à part pour pouvoir l'ajuster.
- Sous la canopée, une ombre douce assombrit légèrement le sol.
- Plus tard, éventuellement, une teinte d'ambiance globale (fin d'après-midi) : hors de cette fiche.

## 10. Fichiers et intégration dans Godot

| Fichier | Contenu |
|---|---|
| `assets/art/tiles/palette.gpl` | Palette (section 3) |
| `assets/art/tiles/grass_fill.png` | Remplissages d'herbe |
| `assets/art/tiles/dirt_on_grass.png`, `water_on_grass.png`… | Une planche 4 × 4 par paire (section 5) |
| `assets/art/tiles/water_anim.png`, `foam_anim.png` | Animations d'eau (4 images côte à côte) |
| `assets/art/tiles/cliffs.png` | Falaises et escaliers (section 7) |
| `assets/art/props/nature.png` + `nature.json` | Arbres, buissons, décors d'eau, décalques : rectangle et point d'ancrage (aux pieds) de chaque objet, sur le modèle de l'atlas actuel `props.json` |

**Côté code**, pour la mise en place :
1. Une couche d'affichage en grille double, décalée de (-16, -16) px, construite depuis `MapData`. Les couches et collisions actuelles restent en place, masquées.
2. Une couche de décalques au sol.
3. Les forêts recomposées en canopée et lisière.

Le tout s'appliquera d'abord à la zone témoin, avec la même bascule **F2** que l'essai LPC pour comparer.

## 11. Production

**Outils gratuits** : LibreSprite ou Pixelorama (libres), ou Aseprite compilé depuis ses sources. GIMP pour vérifier la palette.

**Ordre de production** (zone témoin d'abord, validation à chaque étape) :
1. Palette, puis 6 remplissages d'herbe. On juge le « tapis » : doit être calme, vivant, sans motif répété.
2. Terre sur herbe (16) et 3 remplissages de terre : les chemins du camp.
3. Eau sur herbe (16), eau animée, écume : la rivière.
4. 3 feuillus, 1 conifère, 2 buissons, 1 souche, et leurs ombres : l'échelle face au groupe.
5. 12 décalques au sol.
6. Échantillon de falaise : lèvre, faces, coins, escalier (environ 14 tuiles) sur le plateau témoin.

C'est environ **90 tuiles et objets** pour la zone témoin complète.

**Qui dessine**
- **Toi** : cette fiche suffit pour démarrer ; je fais l'intégration et la bascule F2.
- **Un pixel artiste** : cette fiche sert de cahier des charges. C'est un service payant, qui demande ton accord.
- **Moi, pixel par pixel** : possible par étapes, en commençant par l'étape 1. Mon niveau reste inférieur à celui d'un pixel artiste confirmé ; chaque étape serait soumise à ta validation par comparaison F2.

## 12. Critères d'acceptation de la zone témoin

1. Aucune grille visible à aucun zoom : ni marches d'escalier, ni blocs carrés, ni motif répété.
2. Personnages, butin et sangliers restent les éléments les plus lisibles de l'écran.
3. Arbres et décors à l'échelle de nos personnages (section 4).
4. Toutes les couleurs appartiennent à la palette.
5. 60 FPS maintenus.
6. Carte, collisions et gameplay inchangés. Bascule F2 fonctionnelle.
7. Validation à l'œil par le porteur du projet, en comparant avec l'ancien rendu et l'essai LPC.
