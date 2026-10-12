extends Control
## Menu principal: Jogar, Loja, Oficina (upgrade), Addons, Configurações, Créditos.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/Ui/LandingScreen.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0.85, 0.85, 0.9)
	add_child(bg)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/art/Ui/Logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size = Vector2(400, 170)
	logo.position = Vector2(30, 20)
	add_child(logo)

	# HUD economia
	var bank := Label.new()
	bank.text = "🪙 %d   💎 %d" % [int(SaveSystem.profile.get("bank_coins", 0)), int(SaveSystem.profile.get("gems", 0))]
	bank.add_theme_font_size_override("font_size", 26)
	bank.position = Vector2(30, 6)
	add_child(bank)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(880, 40)
	vbox.size = Vector2(290, 470)
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)
	var defs := [
		["menu_play", "res://scenes/level_select.tscn", GameState.AppState.LEVEL_SELECT],
		["menu_shop", "res://scenes/shop_screen.tscn", GameState.AppState.SHOP],
		["menu_upgrade", "res://scenes/upgrade_screen.tscn", GameState.AppState.UPGRADE],
		["menu_addons", "res://scenes/addon_screen.tscn", GameState.AppState.ADDON],
		["menu_settings", "res://scenes/settings.tscn", GameState.AppState.SETTINGS],
		["menu_credits", "res://scenes/credits.tscn", GameState.AppState.CREDITS],
	]
	for d in defs:
		var b := Button.new()
		b.text = Localization.tr_key(d[0])
		b.custom_minimum_size = Vector2(290, 64)
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(func():
			AudioManager.play_ui("click")
			GameState.goto_app(d[2])
			SceneRouter.goto(d[1]))
		vbox.add_child(b)
	AudioManager.play_music("menu_theme", -8.0)
