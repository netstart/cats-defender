class_name Wall
extends Node2D
## O muro que os gatos defendem. HP zero = game over.

signal repaired(amount: float)

const REPAIR_FRACTION := 0.25  # reparo custa 25% das moedas ganhas na wave (veja EconomyData)

var health: Health
var _rect: ColorRect
var _width := 40.0
var _height := 720.0

func _ready() -> void:
	health = Health.new()
	health.name = &"Health"
	add_child(health)
	health.hp_changed.connect(_on_hp_changed)
	health.died.connect(_on_died)
	_rect = ColorRect.new()
	_rect.color = Color(0.45, 0.4, 0.38)
	_rect.size = Vector2(_width, _height)
	_rect.position = Vector2(-_width / 2.0, -_height / 2.0)
	add_child(_rect)
	_render_bricks()

func setup(max_hp: float) -> void:
	if not is_node_ready():
		await ready
	health.setup(max_hp)
	_update_visual()

## Reparo: cura amount de HP (a cobrança fica com quem chama).
func repair(amount: float) -> void:
	health.heal(amount)
	repaired.emit(amount)
	_update_visual()

func take_damage(amount: float) -> void:
	health.take_damage(amount)
	_update_visual()
	_shake()

func _on_hp_changed(current: float, maximum: float) -> void:
	EventBus.wall_damaged.emit(roundi(current), roundi(maximum))

func _on_died() -> void:
	EventBus.game_over.emit(false)

func _update_visual() -> void:
	var ratio := health.ratio()
	_rect.color = Color(0.45, 0.4, 0.38).lerp(Color(0.25, 0.1, 0.1), 1.0 - ratio)

func _shake() -> void:
	var tween := create_tween()
	var orig := Vector2.ZERO
	for i in 3:
		tween.tween_property(self, "position", orig + Vector2(randf_range(-4, 4), 0), 0.03)
	tween.tween_property(self, "position", orig, 0.05)

func _render_bricks() -> void:
	# tijolos desenhados uma única vez (separadores escuros)
	for y in range(-360, 360, 60):
		var line := ColorRect.new()
		line.color = Color(0.3, 0.27, 0.26)
		line.size = Vector2(_width, 3)
		line.position = Vector2(-_width / 2.0, y)
		_rect.add_child(line)
