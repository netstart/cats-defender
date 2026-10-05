extends GutTest
## SaveManager: persistência versionada, progresso por nível, settings.

func before_each() -> void:
	var f := "user://save_game.dat"
	if FileAccess.file_exists(f):
		DirAccess.remove_absolute(f)

func test_progresso_registra_estrelas_e_desbloqueio() -> void:
	SaveManager.record_level_win(LevelData.Mode.MERGE, 1, 2)
	SaveManager.record_level_win(LevelData.Mode.MERGE, 1, 3)
	SaveManager.record_level_win(LevelData.Mode.MERGE, 1, 1)
	assert_eq(SaveManager.level_stars(LevelData.Mode.MERGE, 1), 3)
	assert_eq(SaveManager.max_unlocked(LevelData.Mode.MERGE), 2)

func test_sem_save_retorna_padrao() -> void:
	var f := "user://save_game.dat"
	if FileAccess.file_exists(f):
		DirAccess.remove_absolute(f)
	assert_eq(SaveManager.level_stars(LevelData.Mode.TOWER_DEFENSE, 1), 0)
	assert_eq(SaveManager.max_unlocked(LevelData.Mode.TOWER_DEFENSE), 1)

func test_settings_persistem() -> void:
	SaveManager.save_settings({"Master": 0.5})
	assert_eq(SaveManager.load_game().get("settings", {}).get("Master"), 0.5)
