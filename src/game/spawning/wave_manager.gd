class_name WaveManager
extends Node
## WaveManager: dispara ondas do LevelData, respawna inimigos via PoolManager,
## e emite wave_started/wave_cleared/game_over. Data-driven: zero número aqui.

signal all_waves_cleared

var level: LevelData
var wall: Wall
var spawn_x := 1400.0
var wall_x := 380.0
var lane_y: Array[float] = [220.0, 360.0, 500.0]  # 3 pistas
var enemy_registry: EnemyRegistry
## Modo TD: estratégia customizada de spawn (PathFollowEnemy) substitui a padrão.
var spawn_strategy: Callable = Callable()

var _wave_index := -1
var _spawning := false
var _pending: Array[Dictionary] = []
var _spawn_timer := 0.0
var _alive := 0

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_gone)
	EventBus.enemy_leaked.connect(_on_enemy_gone)

func start_level(p_level: LevelData, p_wall: Wall) -> void:
	level = p_level
	wall = p_wall
	_wave_index = -1
	_alive = 0
	_start_next_wave()

func _start_next_wave() -> void:
	_wave_index += 1
	if _wave_index >= level.waves.size():
		all_waves_cleared.emit()
		EventBus.level_completed.emit(0)  # estrelas calculadas pela cena de jogo
		return
	var wave := level.waves[_wave_index]
	_pending.clear()
	for spawn in wave.spawns:
		for i in int(spawn.get("count", 1)):
			_pending.append({
				"enemy_id": spawn["enemy_id"],
				"at": float(spawn.get("delay", 0.0)) + i * float(spawn.get("interval", 1.0)),
			})
	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["at"] < b["at"])
	_spawn_timer = -2.0  # 2s de aviso antes da primeira onda
	_spawning = true
	EventBus.wave_started.emit(_wave_index, level.waves.size())

func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	if _spawning:
		_spawn_timer += delta
		while not _pending.is_empty() and _pending[0]["at"] <= _spawn_timer:
			_spawn(_pending.pop_front())
		# onda termina quando não há mais nada para spawnar nem ninguém vivo
		if _pending.is_empty() and _alive <= 0:
			_spawning = false
			EventBus.wave_cleared.emit(_wave_index)
			_rest_then_next(level.waves[_wave_index].rest_time)

func _rest_then_next(rest: float) -> void:
	await get_tree().create_timer(rest).timeout
	if GameManager.state == GameManager.State.PLAYING:
		_start_next_wave()

func _spawn(info: Dictionary) -> void:
	var data := enemy_registry.get_enemy(info["enemy_id"])
	if data == null:
		push_warning("WaveManager: inimigo '%s' não registrado" % info["enemy_id"])
		return
	if spawn_strategy.is_valid():
		if bool(spawn_strategy.call(data)):
			_alive += 1
		return
	var enemy := PoolManager.acquire(&"enemy") as Enemy
	if enemy == null:
		return
	var lane := lane_y[randi() % lane_y.size()]
	enemy.setup(data, level.hp_multiplier, level.speed_multiplier, wall, wall_x)
	enemy.global_position = Vector2(spawn_x, lane)  # nó já está na árvore do PoolManager
	_alive += 1
	if data.is_boss:
		EventBus.boss_spawned.emit(enemy)

func _on_enemy_gone(_enemy: Node, _reward: int = 0) -> void:
	_alive = maxi(0, _alive - 1)

func alive_count() -> int:
	return _alive + _pending.size()

func current_wave() -> int:
	return _wave_index
