extends Control
## Seleção de fases: LevelMap + botões por stage (campanha + bônus) com cadeado
## e estrelas; progresso salvo por stage_id (13.2).

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/Ui/LevelMap_Bg_Screen.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = Localization.tr_key("select_title")
	title.add_theme_font_size_override("font_size", 34)
	title.position = Vector2(20, 10)
	add_child(title)

	var back := Button.new()
	back.text = Localization.tr_key("ui_back")
	back.custom_minimum_size = Vector2(150, 48)
	back.position = Vector2(1030, 8)
	back.pressed.connect(func():
		AudioManager.play_ui("click")
		GameState.goto_app(GameState.AppState.MENU)
		SceneRouter.goto("res://scenes/main_menu.tscn"))
	add_child(back)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(30, 70)
	grid.size = Vector2(1140, 460)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	add_child(grid)
	for stage_id in StageDatabase.all_stage_ids():
		grid.add_child(_stage_button(stage_id))

func _stage_button(stage_id: String) -> Control:
	var v := VBoxContainer.new()
	var b := Button.new()
	b.custom_minimum_size = Vector2(214, 120)
	var unlocked := StageDatabase.is_unlocked(stage_id, SaveSystem.profile)
	var stars := SaveSystem.stage_stars(stage_id)
	var lbl := Label.new()
	if unlocked:
		b.text = Localization.tr_key("stage_%s" % stage_id)
		lbl.text = "★".repeat(stars) + "☆".repeat(3 - stars)
		lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	else:
		b.text = stage_id + " 🔒"
		b.disabled = true
		lbl.text = Localization.tr_key("select_locked")
	b.pressed.connect(func():
		AudioManager.play_ui("click")
		GameState.current_stage_id = stage_id
		GameState.goto_app(GameState.AppState.LOADING)
		SceneRouter.goto("res://scenes/game.tscn"))
	v.add_child(b)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lbl)
	return v
