class_name TdGame
extends Node2D
## Modo Tower Defense bônus: caminho splineado + placement livre em grid.
## Reuso total: CatTower, EnemyData, WaveManager, PoolManager, HUD.

var level: LevelData
var economy: EconomyData
var registry: EnemyRegistry
var cat_catalog: Array[CatData] = []

var _waves: WaveManager
var _placement: GridPlacement
var _placement_mode := false
var _rng := RandomNumberGenerator.new()
var _coins_earned_wave := 0
var _lives := 10

func _ready() -> void:
	_rng.randomize()
	if level == null:
		level = load("res://data/waves/td_%02d.tres" % GameManager.current_level)
	economy = load("res://data/economy/economy.tres")
	economy.reset_run()
	registry = load("res://data/enemies/registry.tres")
	registry.build_index()
	for i in range(1, 16):
		cat_catalog.append(load("res://data/cats/cat_%02d.tres" % i))
	GameManager.currency = economy.initial_currency * 2  # TD: recompensa 2x

	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.18, 0.12)
	bg.size = Vector2(1280, 720)
	bg.z_index = -10
	add_child(bg)

	var path := Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2(1400, 360))
	curve.add_point(Vector2(1000, 360))
	curve.add_point(Vector2(1000, 150))
	curve.add_point(Vector2(500, 150))
	curve.add_point(Vector2(500, 560))
	curve.add_point(Vector2(180, 560))
	curve.add_point(Vector2(60, 360))
	path.curve = curve
	add_child(path)
	_draw_path(curve)

	_placement = GridPlacement.new()
	add_child(_placement)
	var baked := curve.get_baked_points()
	for p in baked:
		_placement.mark_path(_placement.world_to_cell(p))

	PoolManager.register(&"projectile", load("res://scenes/game/projectile.tscn"), 64)

	_waves = WaveManager.new()
	_waves.enemy_registry = registry
	add_child(_waves)
	_waves.spawn_strategy = _spawn_on_path.bind(path)
	_waves.all_waves_cleared.connect(_on_all_waves_cleared)

	add_child(Hud.new())
	add_child(DamageNumbers.new())
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.enemy_leaked.connect(_on_enemy_leaked)
	EventBus.game_over.connect(_on_game_over)

	_waves.start_level(level, null)
	AudioManager.play_music(&"battle")

func _draw_path(curve: Curve2D) -> void:
	var line := Line2D.new()
	line.points = curve.get_baked_points()
	line.width = 70.0
	line.default_color = Color(0.35, 0.3, 0.25)
	line.z_index = -5
	add_child(line)
	_base_at(curve.get_baked_points()[-1])

func _base_at(pos: Vector2) -> void:
	var base := ColorRect.new()
	base.color = Color(0.5, 0.45, 0.4)
	base.size = Vector2(90, 90)
	base.position = pos - base.size / 2.0
	add_child(base)

func _spawn_on_path(data: EnemyData, path: Path2D) -> bool:
	var follower := PathFollowEnemy.new()
	path.add_child(follower)
	follower.path_length = path.curve.get_baked_length()
	follower.setup(data, level.hp_multiplier, level.speed_multiplier)
	follower.on_finished = _on_enemy_finished
	if data.is_boss:
		EventBus.boss_spawned.emit(follower)
	return true

func _on_enemy_finished(enemy: Enemy) -> void:
	_lives -= 3 if enemy.data.is_boss else 1
	EventBus.wall_damaged.emit(_lives, 10)
	if _lives <= 0:
		GameManager.end_game(false)

func _on_enemy_leaked(_e: Node) -> void:
	pass  # contagem de vivos via enemy_leaked já ocorre no WaveManager

func _on_enemy_killed(_enemy: Node, reward: int) -> void:
	GameManager.add_currency(reward * 2)  # TD paga o dobro
	GameManager.score += reward * 20
	_coins_earned_wave += reward
	AudioManager.vibrate_light()

func _on_all_waves_cleared() -> void:
	if _lives <= 0:
		return
	GameManager.end_game(true, _stars())
	SaveManager.record_level_win(level.mode, level.level_index, _stars())
	AudioManager.play_sfx_id(&"win")

func _stars() -> int:
	if _lives >= 9: return 3
	if _lives >= 5: return 2
	return 1

func _on_game_over(victory: bool) -> void:
	if not victory:
		GameManager.state = GameManager.State.GAME_OVER
		AudioManager.play_sfx_id(&"lose")

## Compra → entra em modo placement; próximo toque posiciona no grid.
func buy_cat() -> bool:
	if not GameManager.try_spend(economy.next_cat_cost()):
		return false
	_placement_mode = true
	return true

func _input(event: InputEvent) -> void:
	if not _placement_mode:
		return
	var pos: Vector2
	if event is InputEventMouseButton and event.pressed:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	else:
		return
	var cell := _placement.world_to_cell(get_canvas_transform().affine_inverse() * pos)
	if _placement.is_free(cell):
		var cat := CatTower.new()
		cat.setup(cat_catalog[_rng.randi() % cat_catalog.size()])
		if _placement.place(cat, cell):
			economy.register_purchase()
			AudioManager.play_sfx_id(&"buy")
			EventBus.cat_bought.emit(cat)
	_placement_mode = false

func repair_wall() -> bool:
	var cost := economy.repair_cost(_coins_earned_wave)
	if not GameManager.try_spend(cost):
		return false
	_lives = mini(_lives + 3, 10)
	AudioManager.play_sfx_id(&"repair")
	return true

func next_cat_cost() -> int:
	return economy.next_cat_cost()

func ability_list() -> Array[Ability]:
	return []
