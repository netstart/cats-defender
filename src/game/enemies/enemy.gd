class_name Enemy
extends Area2D
## Inimigo do modo Merge Defense: anda até o muro, ataca, morre.
## Composição: Health + Moving + HitFlash. Pooled e reutilizável com novo EnemyData.

const DEATH_ANIM_WAIT := 0.7

var data: EnemyData
var health: Health
var wall: Node  # injetado pelo WaveManager (objeto com take_damage)

var _sprite: AnimatedSprite2D
var _moving: Moving
var _state := &"walk"
var _attack_cooldown := 0.0
var _dot_dps := 0.0
var _dot_time := 0.0
var _built := false
var _speed_mult := 1.0
var _wall_x := 100.0

var is_dead: bool:
	get:
		return health == null or health.is_dead

func setup(p_data: EnemyData, hp_mult := 1.0, speed_mult := 1.0,
		p_wall: Node = null, wall_x := 100.0) -> void:
	data = p_data
	_speed_mult = speed_mult
	wall = p_wall
	_wall_x = wall_x
	if not is_node_ready():
		return
	_build(hp_mult)

func _ready() -> void:
	if data != null:
		_build(1.0)

func _build(hp_mult: float) -> void:
	if not is_in_group(&"enemies"):
		add_to_group(&"enemies")
	collision_layer = 2  # ENEMY
	collision_mask = 0
	set_meta(&"pool_id", &"enemy")

	if health == null:
		health = Health.new()
		health.name = &"Health"
		add_child(health)
		health.damaged.connect(_on_damaged)
	if not health.died.is_connected(_on_died):
		health.died.connect(_on_died)
	health.setup(data.max_hp * hp_mult)

	if _sprite == null:
		_sprite = AnimatedSprite2D.new()
		add_child(_sprite)
		var flash := HitFlash.new()
		add_child(flash)
	_sprite.sprite_frames = AtlasLoader.make_sprite_frames(data.atlas_name)
	_sprite.scale = Vector2.ONE * (0.7 * data.scale_mod)
	if _sprite.sprite_frames.has_animation(&"walk"):
		_sprite.play(&"walk")

	if get_child_count() == 0 or _find_collision() == null:
		var shape := CollisionShape2D.new()
		shape.name = &"CollisionShape2D"
		shape.shape = CircleShape2D.new()
		add_child(shape)
	var circle := _find_collision().shape as CircleShape2D
	circle.radius = 26.0 * data.scale_mod

	if _moving == null:
		_moving = Moving.new()
		add_child(_moving)
	_moving.enabled = true
	_moving.speed = data.move_speed * _speed_mult
	_moving.direction = Vector2.LEFT
	_moving.stop_x = _wall_x

	_state = &"walk"
	_attack_cooldown = 0.0
	_dot_dps = 0.0
	_dot_time = 0.0
	monitoring = true
	monitorable = true
	_built = true

func _find_collision() -> CollisionShape2D:
	return get_node_or_null(^"CollisionShape2D") as CollisionShape2D

func take_damage(amount: float) -> void:
	if health:
		health.take_damage(amount)

func apply_dot(dps: float, duration: float) -> void:
	_dot_dps = maxf(_dot_dps, dps)
	_dot_time = maxf(_dot_time, duration)

func apply_slow(factor: float, duration: float) -> void:
	if _moving == null:
		return
	_moving.speed = data.move_speed * _speed_mult * factor
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(_restore_speed)

func _restore_speed() -> void:
	if _moving and data:
		_moving.speed = data.move_speed * _speed_mult

func _process(delta: float) -> void:
	if not _built or _state == &"dead":
		return
	if _dot_time > 0.0:
		_dot_time -= delta
		health.take_damage(_dot_dps * delta)
		if _state == &"dead":
			return
	if _state == &"walk" and _blocked_by_boxer():
		_state = &"attack"
		_moving.enabled = false
		if _sprite.sprite_frames.has_animation(&"attack"):
			_sprite.play(&"attack")
	if _state == &"walk" and global_position.x <= _wall_x + data.attack_range:
		_state = &"attack"
		_moving.enabled = false
		if _sprite.sprite_frames.has_animation(&"attack"):
			_sprite.play(&"attack")
	elif _state == &"attack":
		_attack_cooldown -= delta
		if _attack_cooldown <= 0.0:
			_attack_cooldown = 1.0 / maxf(data.attack_rate, 0.01)
			# mira no bloqueador (CatBoxing) se houver, senão no muro
			var target: Node = _blocked_by_boxer()
			if target == null and wall and is_instance_valid(wall):
				target = wall
			if target and target.has_method(&"take_damage"):
				target.take_damage(data.damage)

func _on_damaged(amount: float) -> void:
	EventBus.damage_number_requested.emit(global_position + Vector2(0, -40), roundi(amount), false)

func _on_died() -> void:
	if _state == &"dead":
		return
	_state = &"dead"
	_moving.enabled = false
	set_deferred(&"monitoring", false)
	set_deferred(&"monitorable", false)
	if is_in_group(&"enemies"):
		remove_from_group(&"enemies")
	var reward := data.coin_reward if data.coin_reward > 0 else maxi(1, roundi(data.max_hp / 10.0))
	EventBus.enemy_killed.emit(self, reward)
	AudioManager.play_sfx_id(&"enemy_die", randf_range(0.92, 1.08))
	if _sprite.sprite_frames.has_animation(&"dead"):
		_sprite.play(&"dead")
		await get_tree().create_timer(DEATH_ANIM_WAIT).timeout
	_built = false
	PoolManager.release(self)

func _blocked_by_boxer() -> Node:
	for b in get_tree().get_nodes_in_group(&"blockers"):
		var n := b as Node2D
		if n and absf(n.global_position.y - global_position.y) < 80.0 \
				and absf(n.global_position.x - global_position.x) < 70.0:
			return n
	return null

## Compatibilidade com simulação headless (sem cena real da sprite).
func describe() -> String:
	return "%s hp=%.0f state=%s" % [data.id, health.hp, _state]
