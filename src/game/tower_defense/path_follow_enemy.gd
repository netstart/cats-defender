class_name PathFollowEnemy
extends PathFollow2D
## Inimigo do modo TD: segue Path2D; usa o mesmo Enemy dentro (composição).
## Chegou no fim do caminho → dano no muro/base e sai.

var enemy: Enemy
var path_length := 0.0
var on_finished: Callable = Callable()

func setup(data: EnemyData, hp_mult: float, speed_mult: float) -> void:
	enemy = Enemy.new()
	enemy.setup(data, hp_mult, speed_mult, null, -INF)
	call_deferred(&"_apply_mult", hp_mult, speed_mult)
	enemy.name = &"EnemyBody"
	# Enemy._process usa _wall_x para atacar; no TD o movimento é via progresso
	add_child(enemy)
	progress = 0.0
	loop = false

func _apply_mult(hp_mult: float, speed_mult: float) -> void:
	if enemy and enemy.is_node_ready():
		enemy.setup(data_of(enemy), hp_mult, speed_mult, null, -INF)

func data_of(e: Enemy) -> EnemyData:
	return e.data

func _ready() -> void:
	if enemy:
		enemy._moving.enabled = false

func _process(delta: float) -> void:
	if enemy == null:
		return
	if enemy.is_dead:
		queue_free()
		return
	if path_length > 0.0:
		progress += enemy._moving.speed * delta
		if progress_ratio >= 1.0 - 0.001:
			if on_finished.is_valid():
				on_finished.call(enemy)
			EventBus.enemy_leaked.emit(enemy)
			queue_free()

func take_damage(amount: float) -> void:
	if enemy:
		enemy.take_damage(amount)

func is_dead() -> bool:
	return enemy == null or enemy.is_dead
