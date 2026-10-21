class_name TileIds
## Disposition des atlas de terrain, partagée entre le générateur d'art
## (tools/generate_art.gd) et la construction du monde (TerrainBuilder).

const SIZE := 32

## Atlas "terrain.png" : tuiles uniques, 8 colonnes.
const GRASS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const GRASS_FLOWERS: Array[Vector2i] = [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0)]
## Herbe avec touffes hautes (2) ou cailloux (1).
const GRASS_DETAIL: Array[Vector2i] = [Vector2i(7, 0), Vector2i(5, 2), Vector2i(6, 2)]
## Faces de falaise : colonne = (extrémité gauche ? 1 : 0) | (extrémité droite ? 2 : 0).
const FACE_TOP_ROW := 1
const FACE_TOP_COL := 0
const FACE_BOTTOM_COL := 4
const STAIRS_TOP := Vector2i(0, 2)
const STAIRS_BOTTOM := Vector2i(1, 2)
const CLIFF_SHADOW := Vector2i(2, 2)
const LILY_PADS: Array[Vector2i] = [Vector2i(3, 2), Vector2i(4, 2)]
## Ponts : colonne = garde-corps (1 = haut/gauche, 2 = bas/droite), +4 pour un pont vertical.
const BRIDGE_ROW := 3

## Atlas auto-tuilés (16 x 16 tuiles), index = masque des 8 voisins de même type.
enum Auto { PATH, SAND, WATER, FOREST, PLATEAU }
const AUTO_FILES := {
	Auto.PATH: "path_auto.png",
	Auto.SAND: "sand_auto.png",
	Auto.WATER: "water_auto.png",
	Auto.FOREST: "forest_auto.png",
	Auto.PLATEAU: "plateau_auto.png",
}

const N := 1
const E := 2
const S := 4
const W := 8
const NE := 16
const SE := 32
const SW := 64
const NW := 128


static func mask_coords(mask: int) -> Vector2i:
	return Vector2i(mask & 15, mask >> 4)
