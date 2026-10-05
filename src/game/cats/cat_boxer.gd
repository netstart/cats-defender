class_name CatBoxer
extends Node2D
## CatBoxing: unidade corpo-a-corpo temporária (habilidade). Bloqueia inimigos.

var hp: float
var dps: float
var punch_range: float
var lifetime: float

var _sprite: AnimatedSprite2D
var _health: Health
var _punch_cooldown := 0.0

func setup(p_hp: float, p_dps: float, p_range: float, p_lifetime: float) -> void:
	hp = p_hp
	dps = p_dps
	punch_range = p_range
	lifetime = p_lifetime

func _ready() -> void:
	add_to_group(&"blockers")  # inimigos param ao encostar (lógica no Enemy)
	_health = Health.new()
	_health.setup(hp)
	_health.died.connect(_on_died)
	add_child(_health)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = AtlasLoader.make_sprite_frames(&"cat_boxing")
	_sprite.scale = Vector2.ONE * 0.8
	_sprite.play(&"idle")
	add_child(_sprite)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		_despawn()
		return
	_punch_cooldown -= delta
	if _punch_cooldown > 0.0:
		return
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var e := node as Enemy
		if e and not e.is_dead and e.global_position.distance_to(global_position) <= punch_range:
			e.take_damage(dps)
			_punch_cooldown = 0.6
			_sprite.play(&"attack")
			_sprite.animation_finished.connect(func() -> void:
				if is_instance_valid(_sprite):
					_sprite.play(&"idle"), CONNECT_ONE_SHOT)
			break

func take_damage(amount: float) -> void:
	_health.take_damage(amount)

func _on_died() -> void:
	_despawn()

func _despawn() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
