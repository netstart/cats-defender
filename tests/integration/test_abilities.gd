extends GutTest
## Integração: habilidades (espinhos, TNT, CatBoxing) e boss.

var game: MergeGame

func _start(level_idx: int) -> void:
	GameManager.current_level = level_idx
	GameManager.current_mode = LevelData.Mode.MERGE
	game = (load("res://scenes/game/merge_game.tscn") as PackedScene).instantiate() as MergeGame
	add_child_autofree(game)
	GameManager.start_game()

func after_each() -> void:
	GameManager.state = GameManager.State.MAIN_MENU

func test_fase_4_desbloqueia_espinhos() -> void:
	_start(4)
	var ids: Array = []
	for ab in game.ability_list():
		ids.append(ab.id)
	assert_true(ids.has(&"spikes"))

func test_espinhos_aplicam_dot_slow_e_custam() -> void:
	_start(4)
	var ab := game.ability_list()[0]
	GameManager.currency = 500
	# inimigo fake direto na área
	var e := Enemy.new()
	e.setup(load("res://data/enemies/enemy_01.tres"))
	e.global_position = Vector2(600, 360)
	add_child_autofree(e)
	await wait_frames(3)
	assert_true(ab.can_use())
	assert_true(ab.use())
	await wait_frames(10)
	assert_lt(e.health.hp, e.health.max_hp)  # dot rodou
	assert_eq(ab._remaining > 0.0, true)

func test_tnt_causa_dano_em_area() -> void:
	_start(7)
	var ab: Ability = null
	for a in game.ability_list():
		if a.id == &"tnt":
			ab = a
	GameManager.currency = 500
	var e := Enemy.new()
	e.setup(load("res://data/enemies/enemy_02.tres"))
	e.global_position = Vector2(600, 360)
	add_child_autofree(e)
	await wait_frames(2)
	var hp_before := e.health.hp
	assert_not_null(ab)
	assert_true(ab.use())
	await wait_frames(3)
	assert_lt(e.health.hp, hp_before, "TNT deve causar dano")

func test_boss_spawna_na_fase_10() -> void:
	_start(10)
	watch_signals(EventBus)
	# força a onda do boss (última)
	game._waves._wave_index = game.level.waves.size() - 2
	game._waves._start_next_wave()
	await wait_seconds(8.0)
	assert_signal_emitted(EventBus, "boss_spawned")
