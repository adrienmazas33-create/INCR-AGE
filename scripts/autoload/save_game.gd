extends Node
## Sauvegarde locale de la progression (lot 3C) : ressources, améliorations (dont compagnons et stade
## du camp, qui en découlent), dernière position valide du héros. Fichier JSON dans user://.
##
## Fiabilité :
## - écriture dans un fichier temporaire, relu et vérifié, puis l'ancienne sauvegarde devient la copie
##   de secours et le temporaire prend sa place : à tout instant, une version complète existe ;
## - au chargement : principale, puis temporaire, puis secours ; chaque champ est validé et borné ;
## - un fichier illisible ou d'une version plus récente est mis de côté (jamais écrasé ni effacé).
## Rien ne progresse jeu fermé : la date d'enregistrement est purement informative.
##
## Arguments : « -- --save=<chemin> » pour un autre fichier, « -- --no-save » pour ne rien écrire.
## Les lancements de l'outil de test (--give, --buy, --at, --route...) n'écrivent pas dans la vraie
## sauvegarde, sauf si --save est indiqué.

signal saved(path: String)

const FORMAT_VERSION := 1
const DEFAULT_PATH := "user://save.json"
## Délai après un gain de ressources avant d'enregistrer (regroupe les ramassages).
const RESOURCE_DEBOUNCE := 4.0
## Enregistrement périodique (position du héros).
const PERIODIC := 30.0
const MAX_RESOURCE := 1_000_000_000

var path := DEFAULT_PATH
var enabled := true
## Fournit la position actuelle du héros, ou null s'il n'en a pas de valide (K.O.).
var hero_position_provider: Callable
## Résumé du dernier chargement (journal et outil de test).
var last_load_report := ""

var _dirty_timer := -1.0
var _periodic_timer := PERIODIC
var _active := false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var test_run := false
	for arg in args:
		if arg.begins_with("--save="):
			path = arg.trim_prefix("--save=")
		elif arg == "--no-save":
			enabled = false
		elif arg.begins_with("--give") or arg.begins_with("--buy") or arg.begins_with("--at") or arg.begins_with("--route"):
			test_run = true
	if test_run and path == DEFAULT_PATH:
		enabled = false


## Charge la sauvegarde dans GameState et renvoie la position du héros enregistrée (ou null).
## À appeler avant la création du groupe et du camp, qui se construisent d'après les améliorations.
func restore() -> Variant:
	var data: Variant = null
	var notes: Array[String] = []
	for candidate in [path, _tmp_path(), _backup_path()]:
		if not FileAccess.file_exists(candidate):
			continue
		var parsed := _read(candidate)
		if parsed.is_empty():
			notes.append("%s illisible" % candidate.get_file())
			_set_aside(candidate, "corrupt")
			continue
		var version := int(parsed.get("version", 0))
		if version > FORMAT_VERSION or version < 1:
			notes.append("%s : version %d incompatible" % [candidate.get_file(), version])
			_set_aside(candidate, "v%d" % version)
			continue
		data = _migrate(parsed)
		notes.append("chargée depuis %s" % candidate.get_file())
		break
	if data == null:
		last_load_report = "aucune sauvegarde valide : nouvelle partie" + (" (%s)" % ", ".join(notes) if not notes.is_empty() else "")
		print("SaveGame : " + last_load_report)
		return null
	_apply(data)
	last_load_report = "; ".join(notes) + " — " + GameState.summary()
	print("SaveGame : " + last_load_report)
	var hero: Variant = data.get("hero")
	if hero is Dictionary and _is_number(hero.get("x")) and _is_number(hero.get("y")):
		return Vector2(hero["x"], hero["y"])
	return null


## Démarre les sauvegardes automatiques (après restauration et mise en place de la partie).
func start() -> void:
	_active = true
	GameState.upgrade_bought.connect(func(_id, _level): save_now())
	GameState.resource_changed.connect(func(_kind, _total): _mark_dirty())


func save_now() -> bool:
	if not enabled or not _active:
		return false
	_dirty_timer = -1.0
	_periodic_timer = PERIODIC
	var text := JSON.stringify(_snapshot(), "\t")
	var tmp := _tmp_path()
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame : écriture impossible (%s)" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(text)
	file.flush()
	file.close()
	# Relecture : on ne remplace la sauvegarde que par un fichier complet et valide.
	if _read(tmp).is_empty():
		push_warning("SaveGame : fichier temporaire invalide, sauvegarde abandonnée")
		return false
	var dir := DirAccess.open(path.get_base_dir())
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(_backup_path()):
			dir.remove(_backup_path().get_file())
		dir.rename(path.get_file(), _backup_path().get_file())
	var err := dir.rename(tmp.get_file(), path.get_file())
	if err != OK:
		push_warning("SaveGame : renommage impossible (%s)" % error_string(err))
		return false
	saved.emit(path)
	return true


func _notification(what: int) -> void:
	# Fermeture de la fenêtre (et, plus tard sur mobile, mise en arrière-plan) : on enregistre.
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_now()


func _process(delta: float) -> void:
	if not _active:
		return
	if _dirty_timer >= 0.0:
		_dirty_timer -= delta
		if _dirty_timer < 0.0:
			save_now()
	_periodic_timer -= delta
	if _periodic_timer <= 0.0:
		save_now()


func _mark_dirty() -> void:
	if _dirty_timer < 0.0:
		_dirty_timer = RESOURCE_DEBOUNCE


func _snapshot() -> Dictionary:
	var data := {
		"version": FORMAT_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"resources": GameState.resources.duplicate(),
		"upgrades": GameState.upgrades.duplicate(),
		# Déduits des améliorations ; enregistrés pour lecture et contrôle de cohérence.
		"companions": Upgrades.companion_count(),
		"camp_stage": Upgrades.camp_stage(),
		"hero": null,
	}
	var pos: Variant = hero_position_provider.call() if hero_position_provider.is_valid() else null
	if pos is Vector2:
		data["hero"] = {"x": roundf(pos.x), "y": roundf(pos.y)}
	return data


## Applique des données validées à GameState (sans déclencher d'effets d'achat).
func _apply(data: Dictionary) -> void:
	var resources: Variant = data.get("resources", {})
	for kind in GameState.KINDS:
		var value: Variant = resources.get(kind, 0) if resources is Dictionary else 0
		# Borné avant conversion : un nombre démesuré ne doit pas déborder en entier.
		GameState.resources[kind] = int(clampf(float(value), 0.0, MAX_RESOURCE)) if _is_number(value) else 0
	GameState.upgrades.clear()
	var upgrades: Variant = data.get("upgrades", {})
	for id in Upgrades.DEFS:
		var value: Variant = upgrades.get(id, 0) if upgrades is Dictionary else 0
		var lvl := int(clampf(float(value), 0.0, Upgrades.DEFS[id]["max"])) if _is_number(value) else 0
		if lvl > 0:
			GameState.upgrades[id] = lvl
	var expected := Upgrades.companion_count()
	if _is_number(data.get("companions")) and int(data["companions"]) != expected:
		push_warning("SaveGame : nombre de compagnons enregistré (%d) incohérent, %d retenu d'après les améliorations"
			% [int(data["companions"]), expected])


## Mise à niveau des anciennes versions du format (aucune pour l'instant : version 1).
func _migrate(data: Dictionary) -> Dictionary:
	return data


func _read(file_path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(file_path)
	if text.is_empty():
		return {}
	# Analyse silencieuse : un fichier abîmé est un cas prévu, pas une erreur du moteur.
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	return json.data if json.data is Dictionary else {}


## Met de côté un fichier inutilisable (jamais effacé) pour ne pas l'écraser à la prochaine sauvegarde.
func _set_aside(file_path: String, reason: String) -> void:
	var target := "%s.%s-%d.json" % [file_path.get_basename(), reason, Time.get_unix_time_from_system()]
	DirAccess.rename_absolute(file_path, target)
	push_warning("SaveGame : %s mis de côté sous %s" % [file_path.get_file(), target.get_file()])


func _tmp_path() -> String:
	return path + ".tmp"


func _backup_path() -> String:
	return path.get_basename() + ".bak.json"


static func _is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
