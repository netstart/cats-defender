extends CanvasLayer
## Pausa: continuar, configurações, sair. Pausa a árvore, roda com PROCESS_MODE_ALWAYS.

signal resume_requested
signal quit_requested

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(440, 160)
	panel.custom_minimum_size = Vector2(400, 400)
	add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 24)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSADO"
	title.add_theme_font_size_override(&"font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume := _button("Continuar")
	resume.pressed.connect(func() -> void: resume_requested.emit())
	vbox.add_child(resume)

	for bus in [&"Master", &"Music", &"SFX"]:
		vbox.add_child(_volume_row(bus))

	var quit := _button("Sair para o menu")
	quit.pressed.connect(func() -> void: quit_requested.emit())
	vbox.add_child(quit)

	AudioManager.duck_music(true)
	tree_exiting.connect(func() -> void: AudioManager.duck_music(false))

func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 52)
	b.add_theme_font_size_override(&"font_size", 22)
	return b

func _volume_row(bus: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = String(bus)
	l.custom_minimum_size = Vector2(100, 0)
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = AudioManager.get_bus_volume(bus)
	slider.custom_minimum_size = Vector2(200, 0)
	var b := bus
	slider.value_changed.connect(func(v: float) -> void:
		AudioManager.set_bus_volume(b, v)
		SaveManager.save_settings({
			"Master": AudioManager.get_bus_volume(&"Master"),
			"Music": AudioManager.get_bus_volume(&"Music"),
			"SFX": AudioManager.get_bus_volume(&"SFX"),
		}))
	row.add_child(slider)
	return row
