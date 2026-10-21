extends SceneTree
## Compose et rend la musique d'exploration, thème principal d'INCR-AGE (audio, lot C).
## Usage : godot --headless --path . --script res://tools/generate_music.gd, puis --import.
##
## Partition entièrement originale, écrite note par note ci-dessous, en sol majeur à 96 BPM,
## 40 mesures (100 s) : intro, thème A, variation A', pont B plus calme, retour du thème
## à la marimba, coda. La coda finit sur l'accord de ré (dominante) qui ramène à l'intro en sol :
## la boucle se referme comme une cadence. Les queues des notes et la réverbération débordent
## sur le début du fichier : aucune coupure audible.
##
## Motif signature, à réarranger plus tard pour chaque époque : ré-sol-la-si (D5 G5 A5 B5),
## quarte montante puis deux pas, rythme noire, noire, croche, noire pointée.
##
## Sons rétro doux (synthèse additive, pas d'onde carrée brute) : flûte « chiptune » pour la
## mélodie, marimba, nappe chaude, basse ronde, petit kick et shaker très discrets.

const OUT := "res://assets/audio/music/"
const RATE := 22050
const BPM := 96.0
const BEAT := 60.0 / BPM
## Durée prise en compte après la fin pour les queues des notes, repliée sur le début.
const TAIL := 4.0
## Mixage des voix (rééquilibré après écoute : marimba de tête et arpège moins saillants,
## kick plus discret, nappe un peu plus présente pour lier l'ensemble).
## Valeurs d'origine : flûte 0.30, flûte douce 0.22, marimba de tête 0.34, doublure 0.10,
## arpège 0.13, nappe 0.045, kick 0.22.
const LEVELS := {
	"flute": 0.27, "flute_soft": 0.21, "marimba_lead": 0.21, "flute_double": 0.12,
	"arpeggio": 0.105, "pad": 0.05, "kick": 0.15,
}

const CHORDS := {
	"G": [43, 55, 59, 62], "D": [38, 50, 54, 57], "Em": [40, 52, 55, 59],
	"C": [36, 48, 52, 55], "Am": [45, 57, 60, 64],
}

## Chaque section : accords par mesure (« C|D » : deux accords d'une demi-mesure), mélodie par
## mesure (note:temps), instrument de la mélodie, arpège (2 croches, 1 noires), basse, percussions.
const SECTIONS := [
	{"chords": ["G", "Em", "C", "D"], "melody": [], "voice": "", "arp": 1, "bass": "whole", "perc": 0},
	{"chords": ["G", "D", "Em", "C", "G", "Em", "C|D", "G"], "melody": [
		"D5:1 G5:1 A5:.5 B5:1.5", "A5:1.5 F#5:.5 D5:2", "E5:1 G5:.5 B5:1.5 A5:1", "G5:2 E5:1 r:1",
		"D5:1 G5:1 A5:.5 B5:1.5", "D6:1.5 B5:.5 G5:2", "E5:1 G5:1 F#5:1 A5:1", "G5:3 r:1"],
		"voice": "flute", "arp": 2, "bass": "half", "perc": 1},
	{"chords": ["G", "D", "Em", "C", "Am", "D", "C|D", "G"], "melody": [
		"D5:1 G5:1 A5:.5 B5:1.5", "A5:1 B5:.5 A5:.5 F#5:1 D5:1", "G5:1.5 B5:.5 E6:1 D6:1", "C6:1 B5:.5 A5:.5 G5:2",
		"A5:1 C6:1 B5:1 A5:1", "F#5:1.5 A5:.5 D6:2", "E6:1 D6:1 C6:1 A5:1", "B5:1 A5:.5 G5:2.5"],
		"voice": "flute", "arp": 2, "bass": "half", "perc": 2},
	{"chords": ["Em", "C", "G", "D", "Em", "C", "Am", "D"], "melody": [
		"B4:2 E5:2", "G5:3 E5:1", "D5:2 B4:2", "A4:3 r:1",
		"B4:1 E5:1 G5:2", "A5:2 G5:1 E5:1", "E5:2 C5:2", "D5:1 F#5:1 A5:2"],
		"voice": "flute_soft", "arp": 1, "bass": "whole", "perc": 0},
	{"chords": ["G", "D", "Em", "C", "G", "Em", "C|D", "G"], "melody": [
		"D5:1 G5:1 A5:.5 B5:1.5", "A5:1.5 F#5:.5 D5:2", "E5:1 G5:.5 B5:1.5 A5:1", "G5:2 E5:1 r:1",
		"D5:1 G5:1 A5:.5 B5:1.5", "D6:1.5 B5:.5 G5:2", "E5:1 G5:1 F#5:1 A5:1", "G5:3 r:1"],
		"voice": "marimba", "arp": 2, "bass": "half", "perc": 2},
	{"chords": ["G", "Em", "C", "D"], "melody": [
		"D5:1 G5:1 A5:.5 B5:1.5", "r:4", "E5:1 G5:1 A5:2", "F#5:2 r:2"],
		"voice": "flute_soft", "arp": 1, "bass": "whole", "perc": 0},
]

var _rng := RandomNumberGenerator.new()
var _buf := PackedFloat32Array()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_rng.seed = 96
	var bars := 0
	for s: Dictionary in SECTIONS:
		bars += s["chords"].size()
	var n := int(round(bars * 4.0 * BEAT * RATE))
	_buf.resize(n + int(TAIL * RATE))
	var bar := 0
	var starts: Array[int] = []
	for s: Dictionary in SECTIONS:
		starts.append(int(bar * 4.0 * BEAT * RATE))
		_render_section(s, bar)
		bar += s["chords"].size()
	# Boucle : ce qui dépasse la fin (queues des notes) se mélange au début.
	for i in _buf.size() - n:
		_buf[i] += _buf[n + i]
	_buf.resize(n)
	var mix := _with_reverb(_buf, 0.2)
	_save(mix, "theme_exploration.wav", 0.5)
	_report(mix, starts)
	quit()


func _render_section(s: Dictionary, first_bar: int) -> void:
	var chords: Array = s["chords"]
	for b in chords.size():
		var t0: float = (first_bar + b) * 4.0 * BEAT
		var parts: PackedStringArray = String(chords[b]).split("|")
		var span := 4.0 / parts.size()
		for k in parts.size():
			var chord: Array = CHORDS[parts[k]]
			var t := t0 + k * span * BEAT
			_pad(t, chord, span * BEAT)
			_bass_line(t, chord[0], span, s["bass"])
			_arpeggio(t, chord, span, s["arp"])
		_percussion(t0, s["perc"])
	var melody: Array = s["melody"]
	for b in melody.size():
		var t: float = (first_bar + b) * 4.0 * BEAT
		var total := 0.0
		for token in String(melody[b]).split(" "):
			var q := token.split(":")
			var beats := float(q[1])
			if q[0] != "r":
				_melody_note(t, _midi(q[0]), beats * BEAT, s["voice"])
			t += beats * BEAT
			total += beats
		# Contrôle de la partition : chaque mesure fait exactement 4 temps.
		if not is_equal_approx(total, 4.0):
			push_error("generate_music : mesure %d de %.2f temps" % [first_bar + b + 1, total])


func _melody_note(t: float, midi: int, dur: float, voice: String) -> void:
	var vel := _rng.randf_range(0.92, 1.05)
	match voice:
		"flute":
			_flute(t, midi, dur, LEVELS["flute"] * vel)
		"flute_soft":
			_flute(t, midi, dur, LEVELS["flute_soft"] * vel)
		"marimba":
			# Retour du thème : marimba en tête, flûte très douce une octave plus bas.
			_marimba(t, midi, LEVELS["marimba_lead"] * vel, 3.5)
			_flute(t, midi - 12, dur, LEVELS["flute_double"] * vel)


## Basse ronde : fondamentale à la blanche (et quinte au 3e temps), ou à la ronde.
func _bass_line(t: float, root: int, beats: float, style: String) -> void:
	if style == "half" and beats >= 4.0:
		_bass(t, root, 2.0 * BEAT, 0.22)
		_bass(t + 2.0 * BEAT, root + 7, 2.0 * BEAT, 0.18)
	else:
		_bass(t, root, beats * BEAT, 0.2)


## Arpège de marimba sur les notes de l'accord, une octave au-dessus de la nappe.
func _arpeggio(t: float, chord: Array, beats: float, density: int) -> void:
	var tones := [chord[1] + 12, chord[2] + 12, chord[3] + 12]
	var pattern := [0, 1, 2, 1, 0, 1, 2, 1]
	var step := 0.5 if density == 2 else 1.0
	var count := int(beats / step)
	for i in count:
		var accent := 1.0 if i % int(2.0 / step) == 0 else 0.8
		_marimba(t + i * step * BEAT, tones[pattern[i % 8]], LEVELS["arpeggio"] * accent * _rng.randf_range(0.9, 1.05), 6.0)


## 0 : aucune ; 1 : shaker léger sur les contretemps ; 2 : shaker et petit kick au 1er temps.
func _percussion(t: float, level: int) -> void:
	if level == 0:
		return
	for k in 4:
		_shaker(t + (k + 0.5) * BEAT, 0.05 if k % 2 == 1 else 0.035)
	if level == 2:
		_kick(t, LEVELS["kick"])


# --- Instruments -------------------------------------------------------------

## Flûte rétro : sinus et quelques harmoniques impaires (couleur « chiptune » adoucie),
## attaque souple, vibrato qui arrive après le début de la note. Dans l'aigu, la note est un peu
## plus douce et moins brillante (l'oreille y est plus sensible).
func _flute(t: float, midi: int, dur: float, amp: float) -> void:
	var f := _freq(midi)
	var gain := _tame(midi, 74, 88, 0.72)
	var bright := _tame(midi, 72, 88, 0.55)
	var start := int(t * RATE)
	var hold := int(dur * 0.94 * RATE)
	var rel := int(0.12 * RATE)
	var phase := 0.0
	for j in hold + rel:
		var u := float(j) / RATE
		var vib := 1.0 + 0.0035 * sin(TAU * 5.2 * u) * clampf((u - 0.18) / 0.2, 0.0, 1.0)
		phase += TAU * f * vib / RATE
		var env := minf(u / 0.025, 1.0) * (0.8 + 0.2 * exp(-u * 4.0))
		if j > hold:
			env *= 1.0 - float(j - hold) / rel
		var w := sin(phase) + (0.08 * sin(2.0 * phase) + 0.16 * sin(3.0 * phase) + 0.05 * sin(5.0 * phase)) * bright
		_add(start + j, w * env * amp * gain)


## Marimba : attaque boisée (harmonique 4 qui s'éteint vite), adoucie dans l'aigu.
func _marimba(t: float, midi: int, amp: float, decay: float) -> void:
	var f := _freq(midi)
	var gain := _tame(midi, 74, 88, 0.75)
	var bright := _tame(midi, 67, 86, 0.5)
	var start := int(t * RATE)
	var length := int(minf(5.0 / decay, 1.6) * RATE)
	for j in length:
		var u := float(j) / RATE
		var v := sin(TAU * f * u) * exp(-u * decay) + 0.25 * bright * sin(TAU * f * 4.0 * u) * exp(-u * decay * 5.0)
		_add(start + j, v * amp * gain * minf(u / 0.003, 1.0))


## Nappe chaude : trois voix (accord sans la basse), deux oscillateurs légèrement désaccordés,
## montée lente et longue extinction qui se fond dans l'accord suivant.
func _pad(t: float, chord: Array, dur: float) -> void:
	var start := int(t * RATE)
	var hold := int(dur * RATE)
	var rel := int(0.9 * RATE)
	for k in range(1, 4):
		var f := _freq(chord[k])
		for j in hold + rel:
			var u := float(j) / RATE
			var env := minf(u / 0.6, 1.0) * (1.0 - clampf(float(j - hold) / rel, 0.0, 1.0))
			var v := sin(TAU * f * u) + 0.3 * sin(TAU * f * 2.003 * u) + 0.12 * sin(TAU * f * 3.0 * u)
			_add(start + j, v * env * LEVELS["pad"])


## Basse ronde, avec une 2e harmonique pour rester audible sur de petits haut-parleurs.
func _bass(t: float, midi: int, dur: float, amp: float) -> void:
	var f := _freq(midi)
	var start := int(t * RATE)
	var hold := int(dur * 0.95 * RATE)
	var rel := int(0.08 * RATE)
	for j in hold + rel:
		var u := float(j) / RATE
		var env := minf(u / 0.01, 1.0) * exp(-u * 0.6)
		if j > hold:
			env *= 1.0 - float(j - hold) / rel
		var p := TAU * f * u
		_add(start + j, (sin(p) + 0.3 * sin(2.0 * p) + 0.08 * sin(3.0 * p)) * env * amp)


func _kick(t: float, amp: float) -> void:
	var start := int(t * RATE)
	var phase := 0.0
	for j in int(0.25 * RATE):
		var u := float(j) / RATE
		phase += TAU * (55.0 + 70.0 * exp(-u * 35.0)) / RATE
		_add(start + j, sin(phase) * exp(-u * 16.0) * amp * minf(u / 0.002, 1.0))


func _shaker(t: float, amp: float) -> void:
	var start := int(t * RATE)
	var lp := 0.0
	for j in int(0.07 * RATE):
		var u := float(j) / RATE
		var x := _rng.randf_range(-1.0, 1.0)
		lp += 0.25 * (x - lp)
		_add(start + j, (x - lp) * minf(u / 0.008, 1.0) * exp(-u * 55.0) * amp)


# --- Outils --------------------------------------------------------------------

## Facteur 1 jusqu'à la note `from`, puis décroissant jusqu'à `floor` à la note `to` (en MIDI).
func _tame(midi: int, from: int, to: int, floor: float) -> float:
	return lerpf(1.0, floor, clampf(float(midi - from) / (to - from), 0.0, 1.0))


func _add(i: int, v: float) -> void:
	if i < _buf.size():
		_buf[i] += v


func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## « F#5 » -> numéro MIDI.
func _midi(name: String) -> int:
	var base: int = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}[name[0]]
	var i := 1
	if name[1] == "#":
		base += 1
		i = 2
	elif name[1] == "b":
		base -= 1
		i = 2
	return base + 12 * (int(name.substr(i)) + 1)


## Réverbération légère (4 filtres en peigne amortis, 2 passe-tout), calculée sur la boucle
## précédée de sa propre fin : la queue de réverbération se raccorde exactement au bouclage.
func _with_reverb(dry: PackedFloat32Array, wet_gain: float) -> PackedFloat32Array:
	var n := dry.size()
	var warm := int(TAIL * RATE)
	var combs := [558, 594, 639, 678]
	var wet := PackedFloat32Array()
	wet.resize(n)
	for d: int in combs:
		var line := PackedFloat32Array()
		line.resize(d)
		var pos := 0
		var damp := 0.0
		for k in warm + n:
			var x := dry[(k - warm + n) % n]
			var y := line[pos]
			damp = y * 0.7 + damp * 0.3
			line[pos] = x + damp * 0.8
			pos = (pos + 1) % d
			if k >= warm:
				wet[k - warm] += y * 0.25
	for d: int in [113, 278]:
		var line := PackedFloat32Array()
		line.resize(d)
		var pos := 0
		var out := PackedFloat32Array()
		out.resize(n)
		for k in warm + n:
			var x := wet[(k - warm + n) % n]
			var b := line[pos]
			var y := -x + b
			line[pos] = x + b * 0.5
			pos = (pos + 1) % d
			if k >= warm:
				out[k - warm] = y
		wet = out
	var mix := PackedFloat32Array()
	mix.resize(n)
	for i in n:
		mix[i] = dry[i] + wet[i] * wet_gain
	return mix


func _save(samples: PackedFloat32Array, file: String, peak: float) -> void:
	var top := 0.0001
	for s in samples:
		top = maxf(top, absf(s))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, clampi(roundi(samples[i] / top * peak * 32767.0), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.save_to_wav(OUT + file)
	_scale = peak / top


var _scale := 1.0


## Contrôles : durée, niveau moyen par section, continuité du raccord de boucle.
func _report(mix: PackedFloat32Array, starts: Array[int]) -> void:
	var n := mix.size()
	print("generate_music : %.1f s, %d mesures à %d BPM" % [n / float(RATE), roundi(n / (4.0 * BEAT * RATE)), BPM])
	starts.append(n)
	var names := ["intro", "A", "A'", "B (pont)", "A'' (marimba)", "coda"]
	for k in names.size():
		var acc := 0.0
		var top := 0.0
		for i in range(starts[k], starts[k + 1]):
			acc += mix[i] * mix[i]
			top = maxf(top, absf(mix[i]))
		var rms := sqrt(acc / (starts[k + 1] - starts[k])) * _scale
		# Écart crête / moyenne : plus il est grand, plus des notes isolées « dépassent ».
		print("  %-14s niveau moyen %.1f dBFS, crête %.1f dBFS (écart %.1f dB)" % [names[k], linear_to_db(rms),
			linear_to_db(top * _scale), linear_to_db(top * _scale) - linear_to_db(rms)])
	var jump := absf(mix[0] - mix[n - 1]) * _scale
	var typical := 0.0
	for i in range(1, n):
		typical = maxf(typical, absf(mix[i] - mix[i - 1]) * _scale)
	print("  raccord de boucle : écart %.4f (plus grand écart entre deux échantillons du morceau : %.4f)" % [jump, typical])
