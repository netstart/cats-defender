extends Sprite2D
class_name CoinView
## Moeda: cai com gravidade, 1 quique no chão, voa até o CoinBar (3.1).
## Pooled.

signal collected(amount: int)

var amount := 0
var active := false
var vy := 0.0
var bounced := false
var floor_y := 0.0
var target: Control = null
var _flying := false
var _age := 0.0

func _ready() -> void:
	texture = load("res://assets/art/Ui/CoinIcon.png")
	scale = Vector2(0.8, 0.8)

func pool_activate() -> void:
	active = true
	visible = true
	vy = -180.0
	bounced = false
	_flying = false
	_age = 0.0

func pool_deactivate() -> void:
	active = false
	visible = false

func setup(p_amount: int, start: Vector2, p_floor_y: float, p_target: Control) -> void:
	amount = p_amount
	position = start
	floor_y = p_floor_y
	target = p_target

func _process(delta: float) -> void:
	if not active:
		return
	_age += delta
	if _flying and target:
		position = position.lerp(target.get_global_rect().get_center(), 8.0 * delta)
		scale = scale.lerp(Vector2(0.2, 0.2), 8.0 * delta)
		if position.distance_to(target.get_global_rect().get_center()) < 30.0:
			collected.emit(amount)
			queue_free()
		return
	# queda com 1 quique (3.4 fixed step na sim; aqui é cosmético)
	vy += 900.0 * delta
	position.y += vy * delta
	if position.y >= floor_y and not bounced:
		position.y = floor_y
		vy = -vy * 0.4
		bounced = true
	elif bounced and vy > 0.0 and position.y >= floor_y:
		_flying = true
