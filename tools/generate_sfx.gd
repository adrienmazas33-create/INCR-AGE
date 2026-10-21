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
	# Lot B (ajoutés après le lot A pour ne pas changer ses sons).
	_save(_step_grass(), "step_grass.wav", 0.5)
	_save(_step_dirt(), "step_dirt.wav", 0.5)
	_save(_step_wood(), "step_wood.wav", 0.55)
	_save(_step_stone(), "step_stone.wav", 0.45)
	_save(_boar_down(), "boar_down.wav", 0.75)
	_save(_camp_stage(), "camp_stage.wav", 0.6)
	_save(_meadow_loop(), "meadow_loop.wav", 0.5)
	_save(_water_loop(), "water_loop.wav", 0.5)
	for k in 4:
		_save(_bird(k), "bird_%d.wav" % k, 0.5)
	quit()


## Pas dans l'herbe : froissement doux, sans claquement.
func _step_grass() -> PackedFloat32Array:
	var out := _buffer(0.1)
	var lp := 0.0
	var lp2 := 0.0
	for i in out.size():
		var t := float(i) / RATE
		lp += 0.35 * (_rng.randf_range(-1.0, 1.0) - lp)
		lp2 += 0.04 * (lp - lp2)
		out[i] = (lp - lp2) * minf(t / 0.008, 1.0) * exp(-t * 38.0)
	return out


## Pas sur la terre battue : petit crissement granuleux et appui sourd.
func _step_dirt() -> PackedFloat32Array:
	var out := _buffer(0.09)
	var lp := 0.0
	var grain := 1.0
	for i in out.size():
		var t := float(i) / RATE
		if i % 40 == 0:
			grain = _rng.randf_range(0.2, 1.0)
		lp += 0.45 * (_rng.randf_range(-1.0, 1.0) - lp)
		out[i] = (lp * grain + 0.5 * sin(TAU * 95.0 * t)) * minf(t / 0.003, 1.0) * exp(-t * 48.0)
	return out


## Pas sur un pont : planche creuse.
func _step_wood() -> PackedFloat32Array:
	var out := _buffer(0.14)
	for i in out.size():
		var t := float(i) / RATE
		var knock := sin(TAU * 210.0 * t) * exp(-t * 32.0) + 0.5 * sin(TAU * 455.0 * t) * exp(-t * 55.0)
		out[i] = (knock + _rng.randf_range(-1.0, 1.0) * exp(-t * 400.0) * 0.4) * minf(t / 0.002, 1.0)
	return out


## Pas sur la roche du plateau : tapotement sec et bref.
func _step_stone() -> PackedFloat32Array:
	var out := _buffer(0.07)
	var lp := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var x := _rng.randf_range(-1.0, 1.0)
		lp += 0.2 * (x - lp)
		out[i] = ((x - lp) * exp(-t * 90.0) + 0.3 * sin(TAU * 820.0 * t) * exp(-t * 110.0)) * minf(t / 0.002, 1.0)
	return out


## Sanglier abattu : dernier grognement qui retombe, puis la masse qui touche le sol.
func _boar_down() -> PackedFloat32Array:
	var out := _buffer(0.55)
	var phase := 0.0
	var lp := 0.0
	var puff := 0.0
	for i in out.size():
		var t := float(i) / RATE
		phase = fmod(phase + (125.0 - 70.0 * minf(t / 0.3, 1.0)) / RATE, 1.0)
		lp += 0.18 * (phase * 2.0 - 1.0 - lp)
		var groan := lp * 1.4 * minf(t / 0.02, 1.0) * clampf((0.3 - t) / 0.12, 0.0, 1.0)
		var land := 0.0
		if t >= 0.2:
			var u := t - 0.2
			puff += 0.1 * (_rng.randf_range(-1.0, 1.0) - puff)
			land = sin(TAU * 70.0 * u) * exp(-u * 16.0) + puff * exp(-u * 12.0) * 1.5
		out[i] = groan + land
	return out


## Le camp grandit : trois coups de tambour de peau, puis un accord de marimba qui résonne.
func _camp_stage() -> PackedFloat32Array:
	var out := _buffer(2.0)
	for k in 3:
		var start := int(k * 0.18 * RATE)
		var phase := 0.0
		for i in range(start, int(start + 0.4 * RATE)):
			var t := float(i - start) / RATE
			phase += TAU * (78.0 + 70.0 * exp(-t * 25.0)) / RATE
			out[i] += (sin(phase) + _rng.randf_range(-1.0, 1.0) * exp(-t * 200.0) * 0.3) * exp(-t * 10.0) * (0.7 if k < 2 else 1.0)
	for f in [261.63, 329.63, 392.0, 523.25]:
		_marimba(out, 0.56, f, 0.45, 3.2)
	return _echo(out, 0.16, 0.25)


## Prairie, en boucle de 12 s : vent très doux qui respire, sans oiseaux (ils sont joués à part,
## à intervalles irréguliers, pour qu'aucune répétition ne s'entende).
func _meadow_loop() -> PackedFloat32Array:
	var n := 12 * RATE
	var out := _loop_bed(n, 0.012, 1.0)
	for i in n:
		# Souffle qui monte et descend deux fois par boucle (période qui tombe juste).
		out[i] *= 0.65 + 0.35 * sin(TAU * 2.0 * i / n)
	return out


## Chants d'oiseaux, quatre motifs distincts : 0 trois notes montantes, 1 trille rapide,
## 2 sifflement en deux notes descendantes, 3 roulade avec vibrato.
func _bird(kind: int) -> PackedFloat32Array:
	var out := _buffer([0.5, 0.6, 0.55, 0.5][kind])
	match kind:
		0:
			for c in 3:
				_chirp(out, c * 0.11, 2700.0 + c * 260.0, 700.0, 0.06, 0.0)
		1:
			for c in 9:
				_chirp(out, c * 0.055, 3500.0 if c % 2 == 0 else 3150.0, 150.0, 0.035, 0.0)
		2:
			_chirp(out, 0.0, 2550.0, -300.0, 0.17, 0.0)
			_chirp(out, 0.24, 2050.0, -200.0, 0.2, 0.0)
		3:
			_chirp(out, 0.0, 3000.0, 250.0, 0.42, 18.0)
	return out


## Note d'oiseau : sinus qui glisse de `sweep` Hz, enveloppe en cloche, vibrato facultatif.
func _chirp(out: PackedFloat32Array, at: float, freq: float, sweep: float, length: float, vibrato: float) -> void:
	var start := int(at * RATE)
	var phase := 0.0
	for j in int(length * RATE):
		var u := float(j) / (length * RATE)
		var f := freq + sweep * u + (sin(TAU * vibrato * u * length) * 220.0 if vibrato > 0.0 else 0.0)
		phase += TAU * f / RATE
		if start + j < out.size():
			out[start + j] += sin(phase) * sin(PI * u)


## Eau vive, en boucle de 6 s : murmure clair et petites bulles.
func _water_loop() -> PackedFloat32Array:
	var n := 6 * RATE
	var low := _loop_bed(n, 0.03, 1.0)
	var out := _loop_bed(n, 0.3, 0.35)
	for i in n:
		out[i] -= low[i] * 0.3
	for k in 50:
		var start := _rng.randi_range(0, n - 1)
		var length := _rng.randf_range(0.02, 0.05)
		var f0 := _rng.randf_range(380.0, 820.0)
		var amp := _rng.randf_range(0.12, 0.3)
		var phase := 0.0
		for j in int(length * RATE):
			var u := float(j) / (length * RATE)
			phase += TAU * f0 * (1.0 + 1.4 * u) / RATE
			out[(start + j) % n] += sin(phase) * sin(PI * u) * amp
	return out


## Bruit filtré (passe-bas `a`) de `n` échantillons dont la fin est fondue sur le début (boucle).
func _loop_bed(n: int, a: float, gain: float) -> PackedFloat32Array:
	var fade := int(0.3 * RATE)
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var lp := 0.0
	for i in raw.size():
		lp += a * (_rng.randf_range(-1.0, 1.0) - lp)
		raw[i] = lp
	var top := 0.0001
	for v in raw:
		top = maxf(top, absf(v))
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = raw[i] / top * gain
	for i in fade:
		var w := float(i) / fade
		out[i] = (raw[i] * w + raw[n + i] * (1.0 - w)) / top * gain
	return out


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
		if not file.ends_with("_loop.wav") and i > samples.size() - tail:
			v *= float(samples.size() - i) / tail
		data.encode_s16(i * 2, clampi(roundi(v * 32767.0), -32768, 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.save_to_wav(OUT + file)
	print("generate_sfx : %s (%.2f s)" % [file, samples.size() / float(RATE)])
