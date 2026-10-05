extends GutTest
## Curva de progressão: 30 merge + 10 TD geradas; boss nas fases 10/30.

func test_existem_30_fases_merge_e_10_td() -> void:
	for i in range(1, 31):
		assert_true(ResourceLoader.exists("res://data/waves/merge_%02d.tres" % i))
	for i in range(1, 11):
		assert_true(ResourceLoader.exists("res://data/waves/td_%02d.tres" % i))

func test_curva_multiplicador_sobe() -> void:
	var last := 0.0
	for i in range(1, 31):
		var lv: LevelData = load("res://data/waves/merge_%02d.tres" % i)
		assert_gt(lv.hp_multiplier, last * 0.99, "mult deve ser monotônico na fase %d" % i)
		last = lv.hp_multiplier

func test_boss_nas_fases_10_e_30() -> void:
	for i in range(1, 31):
		var lv: LevelData = load("res://data/waves/merge_%02d.tres" % i)
		assert_eq(lv.is_boss_level, i == 10 or i == 30)

func test_habilidades_desbloqueiam_na_ordem() -> void:
	var lv4: LevelData = load("res://data/waves/merge_04.tres")
	assert_true(lv4.unlock_abilities.has(&"spikes"))
	var lv7: LevelData = load("res://data/waves/merge_07.tres")
	assert_true(lv7.unlock_abilities.has(&"tnt"))
	var lv11: LevelData = load("res://data/waves/merge_11.tres")
	assert_true(lv11.unlock_abilities.has(&"boxer"))

func test_toda_wave_tem_spawn_valido() -> void:
	var registry: EnemyRegistry = load("res://data/enemies/registry.tres")
	registry.build_index()
	for i in range(1, 31):
		var lv: LevelData = load("res://data/waves/merge_%02d.tres" % i)
		assert_gt(lv.waves.size(), 0, "fase %d sem ondas" % i)
		for w in lv.waves:
			for spawn in w.spawns:
				assert_not_null(registry.get_enemy(spawn["enemy_id"]))
