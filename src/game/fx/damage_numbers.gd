class_name DamageNumbers
extends CanvasLayer
## DamageNumbers: números de dano flutuantes pooled. Zero alocação no loop.

const POOL := 40

var _labels: Array[Label] = []

func _ready() -> void:
	layer = 50
	for i in POOL:
		var l := Label.new()
		l.add_theme_font_size_override(&"font_size", 22)
		l.add_theme_color_override(&"font_color", Color.WHITE)
		l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override(&"outline_size", 6)
		l.hide()
		add_child(l)
		_labels.append(l)
	EventBus.damage_number_requested.connect(_on_requested)

func _on_requested(world_pos: Vector2, amount: int, is_crit: bool) -> void:
	for l in _labels:
		if not l.visible:
			_show(l, world_pos, amount, is_crit)
			return

func _show(label: Label, world_pos: Vector2, amount: int, is_crit: bool) -> void:
	label.text = str(amount)
	label.add_theme_color_override(&"font_color",
		Color(1.0, 0.85, 0.2) if is_crit else Color.WHITE)
	label.position = world_pos + Vector2(randf_range(-14, 14), 0)
	label.show()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 55, 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.15)
	tween.chain().tween_callback(label.hide)
