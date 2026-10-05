class_name Shooting
extends Node
## Componente de tiro: busca alvo por grupo e dispara projéteis via PoolManager.
## Reusado por gatos e pelo CatBoxing não usa (melee). Zero alocação no loop.

signal target_acquired(target: Node2D)

@export var projectile_pool: StringName = &"projectile"
@export var muzzle_offset := Vector2(48, 0)

var damage := 10.0
var fire_rate := 1.0
var projectile_speed := 600.0
var attack_range := 900.0
var bullet_texture: Texture2D
var target_group := &"enemies"
var direction := Vector2.RIGHT

var _cooldown := 0.0
var _muzzle: Marker2D
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_muzzle = Marker2D.new()
	_muzzle.position = muzzle_offset
	add_child(_muzzle)
	_rng.randomize()

func configure(p_damage: float, p_rate: float, p_speed: float, p_range: float,
		p_bullet: Texture2D) -> void:
	damage = p_damage
	fire_rate = p_rate
	projectile_speed = p_speed
	attack_range = p_range
	bullet_texture = p_bullet

func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var targets := get_tree().get_nodes_in_group(target_group)
	var owner_node := get_parent() as Node2D
	if owner_node == null:
		return
	var best: Node2D = null
	var best_dist := attack_range
	for t in targets:
		var n := t as Node2D
		if n == null or (t.get(&"is_dead") == true):
			continue
		var to_t: Vector2 = n.global_position - owner_node.global_position
		if to_t.sign().x != direction.sign().x:
			continue  # só atira para frente
		var dist := to_t.length()
		if dist < best_dist:
			best = n
			best_dist = dist
	if best == null:
		return
	_fire(best)

func _fire(target: Node2D) -> void:
	_cooldown = 1.0 / maxf(fire_rate, 0.01)
	var proj := PoolManager.acquire(projectile_pool) as Projectile
	if proj == null:
		return
	var dir := (target.global_position - _muzzle.global_position).normalized()
	proj.launch(_muzzle.global_position, dir, projectile_speed, damage, bullet_texture, attack_range)
	target_acquired.emit(target)
	EventBus.shot_fired.emit(proj)
	AudioManager.play_sfx_id(&"shot", _rng.randf_range(0.92, 1.08))
