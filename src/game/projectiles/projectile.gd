class_name Projectile
extends Area2D
## Projétil pooled. Colide com hurtbox de inimigo (camada ENEMY).

var speed := 600.0
var damage := 10.0
var direction := Vector2.RIGHT

var _traveled := 0.0
var _max_range := 1000.0
var _sprite: Sprite2D
var _light: PointLight2D
var _active := false

func _init() -> void:
	collision_layer = 4  # PROJECTILE
	collision_mask = 2   # ENEMY
	monitoring = true
	set_meta(&"pool_id", &"projectile")

func _ready() -> void:
	_sprite = Sprite2D.new()
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	_light = PointLight2D.new()
	_light.energy = 0.55
	_light.texture_scale = 0.35
	_light.color = Color(1.0, 0.85, 0.4)
	_light.shadow_enabled = false
	add_child(_light)
	area_entered.connect(_on_area_entered)

func launch(from: Vector2, dir: Vector2, p_speed: float, p_damage: float,
		tex: Texture2D, max_range: float) -> void:
	global_position = from
	direction = dir
	speed = p_speed
	damage = p_damage
	_traveled = 0.0
	_max_range = max_range
	_sprite.texture = tex
	_sprite.rotation = dir.angle()

func pool_activate() -> void:
	_active = true
	process_mode = Node.PROCESS_MODE_INHERIT
	show()
	set_deferred(&"monitoring", true)

func pool_deactivate() -> void:
	_active = false
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	set_deferred(&"monitoring", false)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	var step := speed * delta
	position += direction * step
	_traveled += step
	if _traveled >= _max_range:
		PoolManager.release(self)

func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	if area.is_in_group(&"enemies") and area.has_method(&"take_damage"):
		area.take_damage(damage)
		PoolManager.call_deferred(&"release", self)
