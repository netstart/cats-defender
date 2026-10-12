extends Control
## Créditos (12.2 [M31]): lista rolável gerada de credits_manifest.json,
## offline, PT-BR/EN, links de origem como texto.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var t := Label.new()
	t.text = Localization.tr_key("credits_title")
	t.add_theme_font_size_override("font_size", 32)
	t.position = Vector2(20, 10)
	add_child(t)
	var back := Button.new()
	back.text = Localization.tr_key("ui_back")
	back.position = Vector2(1030, 8)
	back.custom_minimum_size = Vector2(150, 48)
	back.pressed.connect(func():
		AudioManager.play_ui("click")
		GameState.goto_app(GameState.AppState.MENU)
		SceneRouter.goto("res://scenes/main_menu.tscn"))
	add_child(back)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(60, 70)
	scroll.size = Vector2(1080, 450)
	add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	var manifest := _load_manifest()
	for item in manifest.get("items", []):
		var h := Label.new()
		h.text = "%s — %s" % [item.get("name", "?"), item.get("author", "?")]
		h.add_theme_font_size_override("font_size", 22)
		v.add_child(h)
		var d := Label.new()
		d.text = "%s: %s  |  %s: %s\n%s" % [
			Localization.tr_key("credits_license"), item.get("license", "?"),
			Localization.tr_key("credits_source"), item.get("source_url", "-"),
			item.get("usage", ""),
		]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD
		d.custom_minimum_size = Vector2(1020, 0)
		d.add_theme_font_size_override("font_size", 15)
		v.add_child(d)
		var sep := HSeparator.new()
		v.add_child(sep)

func _load_manifest() -> Dictionary:
	var f := FileAccess.open("res://data/credits_manifest.json", FileAccess.READ)
	if f == null:
		return {"items": []}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {"items": []}
