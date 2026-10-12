extends Control
## Splash → Menu (LandingScreen + Logo).

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Background
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/Ui/LandingScreen.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(bg)
	# Logo
	var logo := TextureRect.new()
	logo.texture = load("res://assets/art/Ui/Logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size = Vector2(500, 220)
	logo.position = Vector2(350, 60)
	add_child(logo)
	# Subtitle
	var sub := Label.new()
	sub.text = Localization.tr_key("splash_tagline")
	sub.add_theme_font_size_override("font_size", 22)
	sub.position = Vector2(0, 300)
	sub.size = Vector2(1200, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(sub)
	# Tap hint
	var tap := Label.new()
	tap.text = Localization.tr_key("splash_tap")
	tap.add_theme_font_size_override("font_size", 26)
	tap.position = Vector2(0, 430)
	tap.size = Vector2(1200, 40)
	tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(tap)
	# Hit area on TOP (last child = highest z-order)
	var hit := Button.new()
	hit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit.text = ""
	hit.flat = true
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.focus_mode = Control.FOCUS_NONE
	hit.pressed.connect(_next)
	add_child(hit)

func _input(event: InputEvent) -> void:
	# Fallback for desktop clicks: catch any press on this Control
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_next()

func _next() -> void:
	AudioManager.play_ui("click")
	GameState.goto_app(GameState.AppState.MENU)
	SceneRouter.goto("res://scenes/main_menu.tscn")