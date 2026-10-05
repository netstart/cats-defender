extends GutTest
## Integração: modo TD — placement em grid, inimigo percorre caminho, base perde vida.

var game: TdGame

func before_each() -> void:
	GameManager.current_level = 1
	GameManager.current_mode = LevelData.Mode.TOWER_DEFENSE
	game = (load("res://scenes/game/td_game.tscn") as PackedScene).instantiate() as TdGame
	add_child_autofree(game)
	GameManager.start_game()

func test_placement_no_grid() -> void:
	GameManager.currency = 200
	assert_true(game.buy_cat())
	var cell := Vector2i(11, 2)
	var cat := CatTower.new()
	cat.setup(game.cat_catalog[0])
	assert_true(game._placement.place(cat, cell))
	assert_eq(game._placement.get_at(cell), cat)

func test_nao_constroi_no_caminho() -> void:
	var cell := game._placement.world_to_cell(Vector2(1000, 360))
	assert_false(game._placement.is_free(cell))

func test_td_derrota_quando_base_zera() -> void:
	var e := Enemy.new()
	e.setup(load("res://data/enemies/enemy_01.tres"))
	add_child_autofree(e)
	game._lives = 1
	game._on_enemy_finished(e)
	assert_eq(GameManager.state, GameManager.State.GAME_OVER)
	assert_false(GameManager.last_victory)

func test_td_vitoria_ao_zerar_ondas() -> void:
	game._waves.all_waves_cleared.emit()
	game._on_all_waves_cleared()
	assert_eq(GameManager.state, GameManager.State.GAME_OVER)
	assert_true(GameManager.last_victory)
