class_name MergeGame
extends Node2D
## Cena principal do modo Merge Defense: muro, slots, loja, ondas, habilidades.
## Construída 100% em código (testável headless, sem .tscn gigante).

const CAT_POOL_WARM := 16

var level: LevelData
var economy: EconomyData
var registry: EnemyRegistry
var cat_catalog: Array[CatData] = []

var _wall: Wall
var _grid: SlotGrid
var _waves: WaveManager
var _merge: MergeController
var _camera: Camera2D
var _coins_earned_wave := 0
var _abilities: Array[Ability] = []
var _rng := RandomNumberGenerator.new()

var _hud: Hud

func _ready() -> void:
	_rng.randomize()
	economy = load("res://data/economy/economy.tres")
	economy.reset_run()
	registry = load("res://data/enemies/registry.tres")
	registry.build_index()
	_load_cat_catalog()
	GameManager.currency = economy.initial_currency

	if level == null:
		level = load("res://data/waves/merge_%02d.tres" % GameManager.current_level)

	_setup_world()
	_setup_gameplay()
	_connect_events()

	_hud = Hud.new()
	_hud.name = &"Hud"
	add_child(_hud)
	var dmg := DamageNumbers.new()
	add_child(dmg)
	add_child(ParticlesPool.new())

	_waves.start_level(level, _wall)
	AudioManager.play_music(&"battle")

func _load_cat_catalog() -> void:
	for i in range(1, 16):
		cat_catalog.append(load("res://data/cats/cat_%02d.tres" % i))

func _setup_world() -> void:
	_camera = Camera2D.new()
	_camera.position = Vector2(640, 360)
	_camera.enabled = true
	add_child(_camera)
	ScreenShake.register_camera(_camera)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.glow_enabled = true
	e.glow_intensity = 0.35
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.11, 0.12, 0.16)
	env.environment = e
	add_child(env)

	# cenário: beco simples (placeholder do pack craftpix)
	var ground := ColorRect.new()
	ground.color = Color(0.16, 0.15, 0.18)
	ground.size = Vector2(1280, 720)
	ground.z_index = -10
	add_child(ground)
	for i in 6:
		var building := ColorRect.new()
		building.color = Color(0.2, 0.19, 0.24)
		building.size = Vector2(200, 140 + (i % 3) * 60)
		building.position = Vector2(i * 220 - 40, 0)
		building.z_index = -9
		add_child(building)

	_wall = Wall.new()
	_wall.position = Vector2(400, 360)
	_wall.setup(economy.wall_max_hp)
	add_child(_wall)

func _setup_gameplay() -> void:
	PoolManager.register(&"projectile", load("res://scenes/game/projectile.tscn"), 64)
	PoolManager.register(&"enemy", load("res://scenes/game/enemy.tscn"), 48)

	_grid = SlotGrid.new()
	_grid.position = Vector2(150, 220)
	add_child(_grid)

	_merge = MergeController.new()
	_merge.grid = _grid
	add_child(_merge)

	_waves = WaveManager.new()
	_waves.enemy_registry = registry
	_waves.spawn_x = 1400.0
	_waves.wall_x = 400.0
	add_child(_waves)
	_waves.all_waves_cleared.connect(_on_all_waves_cleared)

	# Habilidades desbloqueadas pela fase
	for ab_id in level.unlock_abilities:
		var ability := _make_ability(ab_id)
		if ability:
			_abilities.append(ability)
			add_child(ability)

func _make_ability(id: StringName) -> Ability:
	match id:
		&"spikes": return SpikesAbility.new()
		&"tnt": return TntAbility.new()
		&"boxer": return BoxerCallAbility.new()
	return null

func _connect_events() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.game_over.connect(_on_game_over)

func _on_enemy_killed(_enemy: Node, reward: int) -> void:
	GameManager.add_currency(reward)
	GameManager.score += reward * 10
	_coins_earned_wave += reward
	AudioManager.vibrate_light()
	_hit_stop()

## Hit-stop leve (60ms) no kill — juice premium sem travar o fluxo.
func _hit_stop() -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.06, true, false, true).timeout
	Engine.time_scale = 1.0

func _on_wave_cleared(_wave: int) -> void:
	pass

func _on_all_waves_cleared() -> void:
	var stars := _compute_stars()
	GameManager.end_game(true, stars)
	SaveManager.record_level_win(level.mode, level.level_index, stars)
	AudioManager.play_sfx_id(&"win")

func _compute_stars() -> int:
	var ratio := _wall.health.ratio()
	if ratio >= 0.75: return 3
	if ratio >= 0.4: return 2
	return 1

func _on_game_over(victory: bool) -> void:
	if victory:
		return
	GameManager.state = GameManager.State.GAME_OVER
	AudioManager.play_sfx_id(&"lose")

## Loja: compra gato tier 1 aleatório → primeiro slot livre.
func buy_cat() -> bool:
	var cost := economy.next_cat_cost()
	var slot := _grid.free_slot()
	if slot < 0:
		return false
	if not GameManager.try_spend(cost):
		return false
	var pool_size := clampi(level.cat_pool_size, 1, cat_catalog.size())
	var cat := CatTower.new()
	cat.setup(cat_catalog[_rng.randi() % pool_size])
	if not _grid.place(cat, slot):
		GameManager.add_currency(cost)
		cat.queue_free()
		return false
	economy.register_purchase()
	AudioManager.play_sfx_id(&"buy", randf_range(0.95, 1.05))
	EventBus.cat_bought.emit(cat)
	return true

func repair_wall() -> bool:
	var cost := economy.repair_cost(_coins_earned_wave)
	if not GameManager.try_spend(cost):
		return false
	_wall.repair(economy.wall_max_hp * economy.wall_repair_heal_fraction)
	AudioManager.play_sfx_id(&"repair", randf_range(0.95, 1.05))
	return true

func use_ability(index: int) -> bool:
	if index < 0 or index >= _abilities.size():
		return false
	return _abilities[index].use()

func next_cat_cost() -> int:
	return economy.next_cat_cost()

func ability_list() -> Array[Ability]:
	return _abilities
