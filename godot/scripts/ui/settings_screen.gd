extends Control
## Configurações: toggles de som/música/vibração, reduzir efeitos (M21),
## escala de texto, idioma PT-BR/EN.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var t := Label.new()
	t.text = Localization.tr_key("settings_title")
	t.add_theme_font_size_override("font_size", 32)
	t.position = Vector2(20, 10)
	add_child(t)
	var back := Button.new()
	back.text = Localization.tr_key("ui_back")
	back.position = Vector2(1030, 8)
	back.custom_minimum_size = Vector2(150, 48)
	back.pressed.connect(func():
		AudioManager.play_ui("click")
		SaveSystem.save_profile()
		if GameState.app_state == GameState.AppState.SETTINGS:
			GameState.goto_app(GameState.AppState.MENU)
			SceneRouter.goto("res://scenes/main_menu.tscn"))
	add_child(back)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(300, 80)
	vbox.size = Vector2(600, 400)
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	_toggle(vbox, "set_sound", GameSettings.sound_enabled, func(v): GameSettings.set_sound(v))
	_toggle(vbox, "set_music", GameSettings.music_enabled, func(v): GameSettings.set_music(v))
	_toggle(vbox, "set_vibration", GameSettings.vibration_enabled, func(v): GameSettings.set_vibration(v))
	_toggle(vbox, "set_reduce_fx", GameSettings.reduce_fx, func(v): GameSettings.set_reduce_fx(v))

	# escala de texto
	var scale_h := HBoxContainer.new()
	var sl := Label.new()
	sl.text = Localization.tr_key("set_text_scale")
	sl.custom_minimum_size = Vector2(280, 44)
	scale_h.add_child(sl)
	for i in GameSettings.TEXT_SCALES.size():
		var b := Button.new()
		b.text = "%d%%" % GameSettings.TEXT_SCALES[i]
		b.toggle_mode = true
		b.button_pressed = GameSettings.text_scale_index == i
		b.custom_minimum_size = Vector2(90, 44)
		var idx := i
		b.pressed.connect(func(): GameSettings.set_text_scale(idx))
		scale_h.add_child(b)
	vbox.add_child(scale_h)

	# idioma
	var lang_h := HBoxContainer.new()
	var ll := Label.new()
	ll.text = Localization.tr_key("set_language")
	ll.custom_minimum_size = Vector2(280, 44)
	lang_h.add_child(ll)
	for loc in [["pt_BR", "Português"], ["en", "English"]]:
		var b := Button.new()
		b.text = loc[1]
		b.custom_minimum_size = Vector2(150, 44)
		var code: String = loc[0]
		b.pressed.connect(func():
			Localization.set_locale(code)
			SaveSystem.save_profile()
			get_tree().reload_current_scene())
		lang_h.add_child(b)
	vbox.add_child(lang_h)

func _toggle(parent: Control, key: String, value: bool, setter: Callable) -> void:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = Localization.tr_key(key)
	l.custom_minimum_size = Vector2(280, 44)
	l.add_theme_font_size_override("font_size", 20)
	h.add_child(l)
	var b := CheckButton.new()
	b.button_pressed = value
	b.custom_minimum_size = Vector2(90, 44)
	b.toggled.connect(func(v): setter.call(v))
	h.add_child(b)
	parent.add_child(h)
