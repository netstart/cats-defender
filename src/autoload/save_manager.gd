extends Node
## SaveManager: persistência versionada em user:// (save data resource-convertido).

const SAVE_PATH := "user://save_game.dat"
const SAVE_VERSION := 1

func save(data: Dictionary) -> void:
	data["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = file.get_var()
	if not data is Dictionary or int(data.get("version", 0)) != SAVE_VERSION:
		return {}
	return data

## Registro de progresso: níveis por modo com estrelas {merge: {1: 3}, td: {2: 2}}.
func record_level_win(mode: int, level_index: int, stars: int) -> void:
	var data := load_game()
	var key := "merge" if mode == LevelData.Mode.MERGE else "td"
	if not data.has(key):
		data[key] = {}
	var prev: int = data[key].get(str(level_index), 0)
	data[key][str(level_index)] = maxi(prev, stars)
	save(data)

func level_stars(mode: int, level_index: int) -> int:
	var data := load_game()
	var key := "merge" if mode == LevelData.Mode.MERGE else "td"
	return int(data.get(key, {}).get(str(level_index), 0))

func max_unlocked(mode: int) -> int:
	var data := load_game()
	var key := "merge" if mode == LevelData.Mode.MERGE else "td"
	var levels: Dictionary = data.get(key, {})
	var mx := 0
	for k in levels:
		mx = maxi(mx, int(k))
	return maxi(1, mx + 1)  # próximo nível desbloqueado

func save_settings(volumes: Dictionary) -> void:
	var data := load_game()
	data["settings"] = volumes
	save(data)
