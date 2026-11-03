# Soldat de base PixelLab : sources (export du 03/11/2026)

Soldat commun de l'armée, validé par le porteur du projet : pagne de peau, cheveux ébouriffés, pieds
nus, mains vides ; ni bandeau doré, ni cape, ni massue (réservés au héros). Les armes des rôles (lance,
fronde) viendront plus tard.

- `rotations/` : 8 poses fixes, toile 48 × 48, personnage de 44 à 46 px. **Ce sont elles que le jeu
  utilise** (face, dos, profil est ; l'ouest en miroir).
- `animations/Walking/south/` : marche de face seulement (8 images, toile 80 × 80).
- `animations/Breathing_Idle/` : repos, 4 images, sud, sud-est, est et nord-est seulement (toiles de
  64 et 80).
- Les autres directions n'ont pas été générées (quota PixelLab du jour atteint). Ces animations
  partielles sont gardées pour plus tard : le jeu ne les utilise pas, pour ne pas jouer une marche de
  face quand le soldat avance de dos.

Attention : le champ `prompt` de `metadata.json` reprend le texte du héros d'origine (héritage de
PixelLab). Les images sont bien celles du soldat.

Sources brutes, non importées par Godot (`assets/source/.gdignore`). Planche du jeu :
`tools/pack_pixellab.gd -- soldier --poses`.
