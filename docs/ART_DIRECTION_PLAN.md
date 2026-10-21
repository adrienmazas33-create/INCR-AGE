# INCR-AGE — Direction artistique (tranche préhistorique)

Document de cadrage du chantier artistique.

- Il ne change **aucune mécanique** : mêmes tailles de collision, portées, vitesses et règles.
- Tout l'art reste produit par `tools/generate_art.gd`, de façon procédurale, déterministe et original, en attendant d'éventuels sprites dessinés à la main.
- Les formats de planches et d'atlas sont conservés, pour pouvoir remplacer l'art sans toucher au code.

## A. Bilan visuel du prototype (relevé le 21/10/2026, captures en jeu)

**Ce qui fonctionne déjà**
- Le décor : forêts denses en canopée, herbe variée, chemins et berges en auto-tuiles, falaises en blocs rocheux, eau qui scintille.
- La palette générale, chaude et cohérente.
- Le rendu net, en pixels entiers.
- Le tri en profondeur : on passe derrière les arbres et les huttes.

**Ce qui fait trop « prototype »**
- Personnages à grosse tête (environ 1 : 1,2), construits sur la même base, avec un ombrage plat et un contour brun uniforme. Le héros ne se distingue des compagnons que par sa barbe.
- Personne ne porte d'arme : un combat se lit comme des corps qui se bousculent.
- Le sanglier : la tête se confond avec le corps et l'œil est presque invisible. Sous le flash d'impact, il devient une tache blanche illisible.
- Le feu : petit, flammes en tiges, aucune lumière posée au sol. Ce n'est pas le cœur du camp qu'il devrait être.
- Les huttes : chaume régulier sans relief ; les portes manquent de profondeur.
- L'interface : panneau et compteur en rectangles plats, sans matière ni cadre.

**Ce qui nuit à la lisibilité**
- Arcs de coup trop fins et trop brefs, étincelles minuscules : le coup porté ne se voit pas.
- Barres de vie de 8 compagnons visibles en même temps pendant leur régénération : un empilement de traits verts au-dessus du groupe.
- Butin : petites icônes sans éclat, qui se perdent dans l'herbe fleurie.

**Ce qui nuit à l'identité**
- Aucun signe distinctif du héros (silhouette, couleur d'accent).
- Aucune « grande » image lors des moments forts : un achat ou un changement de stade du camp restent discrets.

**Acceptable pour l'instant** (on n'y touche pas dans ce chantier)
- Terrain, eau, falaises, arbres, ponts : bon niveau de prototype ; les diagonales en marches sont un sujet séparé.
- Décors secondaires (rochers, menhirs, totem, palissade, maison longue), papillons, police pixel.

## B. Direction cible (tranche préhistorique)

**Style général**
- Pixel art 32 px par tuile, lumière venant d'en haut à gauche, vue 3/4.
- Trois couches de lisibilité :
  - le sol, doux, peu contrasté, désaturé de 10 à 20 % ;
  - les personnages et le butin, saturés, contrastés, avec un contour sombre ;
  - les effets, lumineux, brefs, en couleurs chaudes ou en blanc.
- Une exploration chaleureuse et organique, des combats arcade lisibles, et des moments forts « cinématographiques » courts (rayons, éclat, bandeau).

**Héros**
- Proportions plus naturelles : environ 26 px de haut, tête d'environ un tiers.
- Chevelure en crinière, barbe, tunique de fourrure portée sur une épaule.
- **Signature** : une cape de fourrure claire sur les épaules et une **massue à tête de pierre** tenue en main.
- Couleur d'accent : or et ocre (rappels dans la barre de vie et les effets de ses coups).

**Compagnons**
- Même gabarit que le héros, en un peu plus sobre : pas de cape.
- Ils portent une **lance à pointe de silex** qui dépasse de leur silhouette : on lit immédiatement « une troupe ».
- Huit variantes de cheveux et de fourrures, déjà en place, à conserver.
- Lisibles à 8 dans une mêlée grâce à la lance verticale et au contour.

**Ennemi primitif principal : le sanglier**
- Masse sombre et compacte, tête bien séparée du corps.
- Groin clair, défenses blanches, œil avec un reflet, oreille dressée, crinière hérissée aux pointes claires, sabots sombres.
- Signal de danger : œil et lueur rouges pendant la préparation de la charge.
- Le flash d'impact ne doit pas effacer la silhouette : il éclaircit, sans blanchir entièrement.

**Campement**
- Matières lisibles : chaume en rangs, avec des mèches claires et des ombres entre les rangs.
- Portes profondes : intérieur sombre, montants de bois éclairés.
- Le feu est le centre lumineux du camp.

**Sol et végétation proche** : inchangés pour ce chantier (contraste modéré pour laisser ressortir personnages et butin).

**Feu de camp**
- Flammes en langues qui s'enroulent, cœur jaune pâle, bords orange puis rouges.
- Braises qui s'élèvent.
- **Halo posé au sol** en ellipse (perspective 3/4), en bandes tramées, et non plus un disque.

**Butin**
- Icônes plus grandes et plus brillantes : reflet, ombre portée.
- **Scintillement** périodique au sol.
- Le savoir (rare) baigne dans une aura violette.
- Au ramassage, une petite gerbe d'éclats de la couleur de la ressource.

**Impacts et retours de combat**
- Arc de coup épais en dégradé blanc-or ; doré pour le héros, blanc pour les compagnons.
- Étincelle en étoile avec anneau, sur 4 images.
- Mort d'un ennemi : nuage de poussière en volute, avec un anneau.
- Barres de vie visibles seulement juste après un coup, ou quand la vie est basse.

**Interface essentielle**
- Panneaux en **cuir tendu dans un cadre de bois** : biseau clair et sombre, coins cloutés, bandeau de titre plus sombre.
- Même cadre pour le compteur de ressources et pour le bandeau d'annonce, qui devient un ruban.
- Rien de plus : l'interface reste minimale.

**Palette et lisibilité**
- Contours sombres teintés de la couleur voisine (contour « sélectif ») plutôt qu'un brun uniforme.
- Trois ou quatre tons par matière.
- Le rouge est réservé au danger : ennemis, dégâts subis, coûts manquants.
- L'or est réservé au héros, aux gains et aux améliorations ; le violet au savoir et à la rareté.

**Touches épiques**
- Achat d'amélioration : rayons de lumière dorés brefs autour du feu.
- Changement de stade du camp : rayons plus amples, léger éclat de l'écran, ruban d'annonce.
- Toujours courts (moins d'une seconde) et sans bloquer le jeu.

## C. Priorités

**1. Améliorer d'abord** : passe 1, ce chantier.
- Héros, compagnons et villageois : nouvelles proportions, armes, ombrage, contour sélectif.
- Sanglier redessiné ; flash d'impact qui garde la silhouette.
- Impacts (arc, étincelle, mort), butin (éclat, scintillement, ramassage), feu (flammes et halo au sol).
- Touches épiques à l'achat et au changement de stade.
- Interface du camp, compteur et ruban ; barres de vie moins envahissantes.
- Huttes : chaume et portes.

**2. Améliorer ensuite**
- Animation d'attaque dédiée (geste de massue ou de lance) plutôt que le seul élan.
- Diagonales du terrain (tuiles de transition ou sous-grille de 16 px).
- Variété de la végétation proche du camp.
- Éclairage d'ambiance léger (tons de fin d'après-midi).
- Décors des stades TRIBU et VILLAGE retouchés au même niveau que les huttes.

**3. Laisser pour plus tard**
- Art des époques suivantes.
- Grand sanglier distinct (aujourd'hui une variante de couleur), nouveaux ennemis.
- Écran titre, menus, sons et musique.
- Sprites dessinés à la main pour remplacer le procédural, si le projet le justifie.

## État d'avancement

- **Étape 1** (ce document) : faite.
- **Passe visuelle 1** (tout le « améliorer d'abord ») : faite et validée (tag `art-pass-1`) ; détail dans `PROGRESS.md`, section « Chantier artistique — passe visuelle 1 ».
- **Priorités 2 et 3** : non commencées.
