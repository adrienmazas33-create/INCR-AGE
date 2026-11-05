extends Node2D
## Lieu à découvrir (lot G3), dessiné pixel par pixel dans la palette du jeu, trié en profondeur avec les
## personnages, sans collision : pierre levée, ancien foyer ou ossements de mammouth. Tant qu'il n'est pas
## découvert, une étincelle dorée le signale de temps en temps ; découvert, il reste en place, sans éclat.

## Motifs, ancrés en bas au centre (« . » transparent). k contour, 1 à 5 pierre (sombre à claire),
## m lichen, a cendre, c braise éteinte, e braise encore rouge, T V bûche calcinée, o os (ivoire), s ombre d'os.
const ART := {
	"menhir": [
		"....kkkk....",
		"...k4455k...",
		"..k434455k..",
		"..k344545k..",
		"..k3m4455k..",
		"..k33m445k..",
		".k334m4455k.",
		".k3334m455k.",
		".k3334445k..",
		".k333m4455k.",
		".k33334445k.",
		".k2333m445k.",
		".k23334445k.",
		".k2333mm44k.",
		".k22333445k.",
		".k223334455k",
		"k2223333445k",
		"k2223333444k",
		"k22223333m4k",
		"k22223333mmk",
		"k22222333mmk",
		".kkkkkkkkkk.",
	],
	"hearth": [
		".......kkkk...kkkk.......",
		"..kkk.k4554k.k4554k.kkk..",
		".k455kk3443kkk3443kk554k.",
		".k3443kkkkkaaaakkkk3443k.",
		"kkk33kaaaaTTTTTaaaak33kkk",
		"k455kaaacaTVVVTaacaak554k",
		"k3443kaaaaaTTTTTaaaak3443",
		"kk33kkaaeaaaaaaeaaakk33kk",
		".kkkk4554kaaaaak4554kkkk.",
		"....k3443kkkkkkk3443k....",
		".....k33k.......k33k.....",
		"......kk.........kk......",
	],
	"bones": [
		"..kk..................kk..",
		".kook................kook.",
		".kook................kook.",
		"..kook.......kkkk...kook..",
		"...kook....kkooook.kook...",
		"....kook..koooooookook....",
		".....koookoookooooook.....",
		"......kookoskosooook......",
		".......kkkoooooooook......",
		"..........kkkkkkkk........",
	],
}
const INK := {
	"k": Color8(42, 32, 28), "1": Color8(58, 53, 64), "2": Color8(82, 74, 82), "3": Color8(109, 100, 102),
	"4": Color8(139, 130, 124), "5": Color8(173, 162, 150), "m": Color8(107, 150, 72),
	"a": Color8(74, 66, 66), "c": Color8(122, 86, 56), "o": Color8(226, 220, 200), "s": Color8(173, 162, 150),
	"T": Color8(42, 30, 26), "V": Color8(90, 63, 44), "e": Color8(232, 116, 52),
}
const SHADOW := Color(26 / 255.0, 26 / 255.0, 46 / 255.0, 0.35)
## Intervalle entre deux étincelles d'un lieu non découvert (s).
const GLINT_EVERY := 1.8

var kind := "menhir"
var discovered := false:
	set(value):
		discovered = value
		queue_redraw()
var _glint := 0.0


func _ready() -> void:
	_glint = randf() * GLINT_EVERY


func _process(delta: float) -> void:
	if discovered:
		return
	_glint -= delta
	if _glint <= 0.0:
		_glint = GLINT_EVERY
		var rows: Array = ART[kind]
		CombatFx.sparkle(global_position + Vector2(randf_range(-6, 6), -rows.size() + randf_range(0, 6)), CombatFx.HERO_TINT)


func _draw() -> void:
	var rows: Array = ART[kind]
	var w: int = (rows[0] as String).length()
	draw_rect(Rect2(Vector2(-w * 0.5 - 1, -2), Vector2(w + 2, 3)), SHADOW)
	var top := Vector2(-w / 2, -rows.size())
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != ".":
				draw_rect(Rect2(top + Vector2(x, y), Vector2.ONE), INK[row[x]])
