extends SceneTree
## Génère les bruitages du prototype par synthèse (sons originaux, aucun échantillon extérieur).
## Usage : godot --headless --path . --script res://tools/generate_sfx.gd, puis --import.
## Le résultat est déterministe. Timbres doux (bois, peau, marimba), jamais de bip carré ; assez de médiums
## pour rester audibles sur des haut-parleurs de portable.

const OUT := "res://assets/audio/sfx/"
const RATE := 22050

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_rng.seed = 2026
	_save(_hit(), "hit.wav", 0.8)
	_save(_pickup(), "pickup.wav", 0.55)
	_save(_buy(), "buy.wav", 0.6)
	_save(_grunt(), "boar_grunt.wav", 0.8)
	_save(_fire_loop(), "fire_loop.wav", 0.5)
	quit()


## Coup de massue sur une bête : bruit sourd qui descend, petit claquement de bois, attaque feutrée.
func _hit() -> PackedFloat32Array:
	var out := _buffer(0.18)
	var phase := 0.0
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase += TAU * (80.0 + 160.0 * exp(-t * 30.0)) / RATE
		var body := sin(phase) * exp(-t * 26.0)
		lp += 0.3 * (_rng.randf_range(-1.0, 1.0) - lp)
		var thud := lp * exp(-t * 110.0) * 0.7
		var knock := sin(TAU * 300.0 * t) * exp(-t * 60.0) * 0.4
		out[i] = tanh((body + thud + knock) * 1.2) * minf(t / 0.002, 1.0)
	return out


## Butin ramassé : deux notes de marimba montantes (sol, ré), brèves et rondes.
func _pickup() -> PackedFloat32Array:
	var out := _buffer(0.32)
	_marimba(out, 0.0, 784.0, 1.0, 22.0)
	_marimba(out, 0.065, 1175.0, 0.8, 18.0)
	return out


## Amélioration achetée : arpège do-mi-sol-do en marimba, dernière note qui chante, léger écho.
func _buy() -> PackedFloat32Array:
	var out := _buffer(1.0)
	var notes := [523.25, 659.25, 783.99, 1046.5]
	for k in notes.size():
		_marimba(out, k * 0.085, notes[k], 0.8 if k < 3 else 1.0, 14.0 if k < 3 else 6.0)
	return _echo(out, 0.12, 0.28)


## Grognement de sanglier (avant la charge) : souffle grave et rauque, hauteur qui retombe.
func _grunt() -> PackedFloat32Array:
	var out := _buffer(0.42)
	var phase := 0.0
	var lp := 0.0
	var breath := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase = fmod(phase + (130.0 - 40.0 * t / 0.42 + _rng.randf_range(-6.0, 6.0)) / RATE, 1.0)
		var saw := phase * 2.0 - 1.0
		lp += 0.2 * (saw - lp)
		breath += 0.08 * (_rng.randf_range(-1.0, 1.0) - breath)
		var rasp := 0.6 + 0.4 * sin(TAU * 31.0 * t)
		var env := minf(t / 0.03, 1.0) * clampf((0.42 - t) / 0.14, 0.0, 1.0)
		out[i] = (lp * rasp * 1.6 + breath * 1.2) * env
	return out


## Crépitement du feu, en boucle sans couture : souffle grave très doux et petits craquements épars.
func _fire_loop() -> PackedFloat32Array:
	var n := int(4.0 * RATE)
	var fade := int(0.25 * RATE)
	var bed := PackedFloat32Array()
	bed.resize(n + fade)
	var lp := 0.0
	for i in bed.size():
		lp += 0.015 * (_rng.randf_range(-1.0, 1.0) - lp)
		bed[i] = lp * 2.2
	var out := _buffer(4.0)
	for i in n:
		out[i] = bed[i]
	# Fondu de la fin du souffle sur son début : la boucle ne s'entend pas.
	for i in fade:
		var w := float(i) / fade
		out[i] = bed[i] * w + bed[n + i] * (1.0 - w)
	var pops := 38
	for k in pops:
		var start := _rng.randi_range(0, n - 1)
		var length := int(_rng.randf_range(0.004, 0.03) * RATE)
		var amp := _rng.randf_range(0.15, 0.55) * (1.8 if _rng.randf() < 0.12 else 1.0)
		var prev := 0.0
		for j in length:
			var x := _rng.randf_range(-1.0, 1.0)
			var crack := (x - prev) * 0.5
			prev = x
			# Les craquements qui dépassent la fin reprennent au début (boucle).
			out[(start + j) % n] += crack * amp * exp(-float(j) / length * 5.0)
	return out


## Note de marimba : fondamentale ronde, harmonique 4 qui s'éteint vite (attaque boisée).
func _marimba(out: PackedFloat32Array, at: float, freq: float, amp: float, decay: float) -> void:
	var start := int(at * RATE)
	for i in range(start, out.size()):
		var t := float(i - start) / RATE
		var v := sin(TAU * freq * t) * exp(-t * decay) + 0.3 * sin(TAU * freq * 4.0 * t) * exp(-t * decay * 4.0)
		out[i] += v * amp * minf(t / 0.003, 1.0)


func _echo(out: PackedFloat32Array, delay: float, gain: float) -> PackedFloat32Array:
	var d := int(delay * RATE)
	for i in range(d, out.size()):
		out[i] += out[i - d] * gain
	return out


func _buffer(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	return out


## Normalise au niveau `peak`, adoucit les derniers millisecondes, écrit un WAV 16 bits mono.
func _save(samples: PackedFloat32Array, file: String, peak: float) -> void:
	var top := 0.0001
	for s in samples:
		top = maxf(top, absf(s))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	var tail := int(0.005 * RATE)
	for i in samples.size():
		var v := samples[i] / top * peak
		if file != "fire_loop.wav" and i > samples.size() - tail:
			v *= float(samples.size() - i) / tail
		data.encode_s16(i * 2, clampi(roundi(v * 32767.0), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.save_to_wav(OUT + file)
	print("generate_sfx : %s (%.2f s)" % [file, samples.size() / float(RATE)])
