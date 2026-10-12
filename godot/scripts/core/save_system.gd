extends Node
## SaveSystem — save versionado, escrita atômica (tmp -> rename), .bak com
## fallback, checksum (M15). Save principal: perfil/economia/pergessão.
## Checkpoint de partida: arquivo separado, retomável no meio da onda (M04).
## Autoload: SaveSystem

const SAVE_PATH := "user://save.json"
const SAVE_TMP := "user://save.tmp"
const SAVE_BAK := "user://save.bak"
const CHECKPOINT_PATH := "user://checkpoint.json"
const SAVE_VERSION := 2

var profile: Dictionary = {}

func _ready() -> void:
	load_profile()

func default_profile() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"bank_coins": 250,
		"gems": 0,
		"buy_level": 1,              # nível de compra (5.1) — gato comprado sai em C{buy_level}
		"extra_slots": 0,            # slots extras comprados (máx. 4: 12 -> 16)
		"melee_unlocked": 0,         # bitmask: 1 = Guardian, 2 = Boxing
		"cat_upgrades": {},          # {"4": 2} -> gato tier 4 no nível de upgrade 2 (cada nível +5% dano)
		"unlocked_addons": [],       # ids de addons destravados na Oficina
		"stage_progress": {},        # {"P1": {"stars": 3, "completed": true}, ...}
		"tutorial_seen": false,
		"settings": {},
	}

func load_profile() -> void:
	profile = _read_json(SAVE_PATH)
	if profile.is_empty() and FileAccess.file_exists(SAVE_BAK):
		push_warning("SaveSystem: save principal corrompido; usando .bak")
		profile = _read_json(SAVE_BAK)
	if profile.is_empty():
		profile = default_profile()
		save_profile()
		return
	profile = migrate(profile)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = parsed
	if int(d.get("checksum", -1)) != _checksum_of(d):
		push_warning("SaveSystem: checksum inválido em " + path)
		return {}
	return d

func _checksum_of(d: Dictionary) -> int:
	var copy := d.duplicate(true)
	copy.erase("checksum")
	return copy.hash()

func save_profile() -> void:
	profile["version"] = SAVE_VERSION
	profile["settings"] = GameSettings.to_dict()
	profile["checksum"] = _checksum_of(profile)
	_atomic_write(SAVE_PATH, JSON.stringify(profile))

func _atomic_write(path: String, content: String) -> void:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: falha ao abrir " + tmp)
		return
	f.store_string(content)
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		DirAccess.remove_absolute(path)
		DirAccess.rename_absolute(tmp, path)

func migrate(d: Dictionary) -> Dictionary:
	## Migrações de versão — nunca quebrar save antigo.
	var v := int(d.get("version", 1))
	if v < 2:
		# v1 -> v2: cat_upgrades passou a ser dict {tier: level}
		if typeof(d.get("cat_upgrades", {})) == TYPE_ARRAY:
			d["cat_upgrades"] = {}
	if int(d.get("buy_level", 0)) < 1:
		d["buy_level"] = 1
	d["version"] = SAVE_VERSION
	var s: Dictionary = d.get("settings", {})
	GameSettings.from_dict(s)
	return d

# ---------------- Perfil / progressão ----------------

func stage_stars(stage_id: String) -> int:
	return int(profile.get("stage_progress", {}).get(stage_id, {}).get("stars", 0))

func stage_completed(stage_id: String) -> bool:
	return bool(profile.get("stage_progress", {}).get(stage_id, {}).get("completed", false))

func record_stage_result(stage_id: String, stars: int, won: bool) -> Dictionary:
	var sp: Dictionary = profile.get("stage_progress", {})
	var entry: Dictionary = sp.get(stage_id, {"stars": 0, "completed": false})
	entry["completed"] = entry["completed"] or won
	entry["stars"] = maxi(int(entry.get("stars", 0)), stars)
	sp[stage_id] = entry
	profile["stage_progress"] = sp
	save_profile()
	return entry

func stage_unlocked(_stage_id: String) -> bool:
	# Regra definida em StageDatabase (P1 sempre aberta; demais dependem da anterior).
	return true

func add_bank(n: int) -> void:
	profile["bank_coins"] = int(profile.get("bank_coins", 0)) + n
	save_profile()

func add_gems(n: int) -> void:
	profile["gems"] = int(profile.get("gems", 0)) + n
	save_profile()

# ---------------- Checkpoint de partida (M04) ----------------

func save_checkpoint(state: Dictionary) -> void:
	state["checksum"] = _checksum_of(state)
	_atomic_write(CHECKPOINT_PATH, JSON.stringify(state))

func load_checkpoint() -> Dictionary:
	return _read_json(CHECKPOINT_PATH)

func has_checkpoint() -> bool:
	return FileAccess.file_exists(CHECKPOINT_PATH) and not _read_json(CHECKPOINT_PATH).is_empty()

func clear_checkpoint() -> void:
	if FileAccess.file_exists(CHECKPOINT_PATH):
		DirAccess.remove_absolute(CHECKPOINT_PATH)
