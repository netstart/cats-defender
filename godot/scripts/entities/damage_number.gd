extends Label
class_name DamageNumberView
## Número de dano flutuante (4, 4.1). Pooled, ~0.8 s de vida.

var active := false
var _t := 0.0

func _ready() -> void:
	var settings2 := LabelSettings.new()
	settings2.font_color = Color(1, 0.95, 0.6)
	settings2.font_size = 22
	settings2.outline_size = 4
	settings2.outline_color = Color(0.2, 0.1, 0.05)
	label_settings = settings2

func pool_activate() -> void:
	active = true
	visible = true
	_t = 0.0
	modulate.a = 1.0

func pool_deactivate() -> void:
	active = false
	visible = false

func setup(value: float, pos: Vector2) -> void:
	text = str(int(round(value)))
	position = pos
	_t = 0.0

func _process(delta: float) -> void:
	if not active:
		return
	_t += delta
	position.y -= 45.0 * delta
	modulate.a = clampf(1.0 - _t / 0.8, 0.0, 1.0)
	if _t >= 0.8:
		pool_deactivate()
