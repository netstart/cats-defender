extends CanvasLayer
## Tela de resultado: vitória com estrelas ou derrota. Reiniciar / menu.

signal retry_requested
signal quit_requested

var victory := false
var stars := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(390, 180)
	panel.custom_minimum_size = Vector2(500, 340)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 28)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "VITÓRIA!" if victory else "FIM DE JOGO"
	title.add_theme_font_size_override(&"font_size", 52)
	title.add_theme_color_override(&"font_color",
		Color(1.0, 0.85, 0.3) if victory else Color(0.9, 0.3, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	if victory:
		var stars_label := Label.new()
		var text := ""
		for s in 3:
			text += "★" if s < stars else "☆"
		stars_label.text = text
		stars_label.add_theme_font_size_override(&"font_size", 48)
		stars_label.add_theme_color_override(&"font_color", Color(1.0, 0.85, 0.2))
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(stars_label)
		_animate_stars(stars_label)

	var next := _button("Próxima fase" if victory else "Tentar de novo")
	next.pressed.connect(func() -> void: retry_requested.emit())
	vbox.add_child(next)

	var quit := _button("Menu")
	quit.pressed.connect(func() -> void: quit_requested.emit())
	vbox.add_child(quit)

	TransitionManager.slide_in(panel)

func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 56)
	b.add_theme_font_size_override(&"font_size", 24)
	return b

func _animate_stars(label: Label) -> void:
	label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.5).set_delay(0.3)
