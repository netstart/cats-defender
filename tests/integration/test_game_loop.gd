extends GutTest
## Integração: roda a fase 1 headless com um "jogador" automático simples
## (compra gato sempre que possível, faz merge, repara muro).

var game: MergeGame

func before_each() -> void:
	GameManager.current_level = 1
	GameManager.current_mode = LevelData.Mode.MERGE
	game = ((load("res://scenes/game/merge_game.tscn")) as PackedScene).instantiate() as MergeGame
	add_child_autofree(game)
	GameManager.start_game()

func test_fase_1_completa_sem_crash() -> void:
	var timer := 0.0
	var merged_once := false
	while GameManager.state == GameManager.State.PLAYING and timer < 300.0:
		game.buy_cat()
		if not merged_once and game.buy_cat():
			merged_once = grid_try_merge_any()
		game.repair_wall()
		while game.use_ability(0):
			pass
		await wait_frames(15)
		timer += 0.25
	assert_eq(GameManager.state, GameManager.State.GAME_OVER)
	assert_true(GameManager.last_victory, "fase 1 deve ser vencida pelo bot simples")
	assert_gt(GameManager.last_stars, 0)

func grid_try_merge_any() -> bool:
	var grid: SlotGrid = game._grid
	for i in SlotGrid.COLS * SlotGrid.ROWS:
		for j in SlotGrid.COLS * SlotGrid.ROWS:
			if i != j and grid.try_merge(i, j) >= 0:
				return true
	return false

func test_moeda_aumenta_ao_matar() -> void:
	var before := GameManager.currency
	game._on_enemy_killed(null, 15)
	assert_eq(GameManager.currency, before + 15)
