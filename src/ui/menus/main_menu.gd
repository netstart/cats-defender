extends CanvasLayer
## Menu principal: título, jogar, configurações. Slide-in premium na abertura.

signal play_requested(mode: LevelData.Mode)
signal settings_requested

var _root: Control

func _ready() -> void:
	layer = 30
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var title := Label.new()
	title.text = "CATS DEFENDER"
	title.add_theme_font_size_override(&"font_size", 84)
	title.add_theme_color_override(&"font_color", Color(1.0, 0.8, 0.3))
	title.add_theme_color_override(&"font_outline_color", Color(0.15, 0.08, 0.2))
	title.add_theme_constant_override(&"outline_size", 12)
	title.position = Vector2(290, 120)
	title.size = Vector2(700, 110)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(title)

	var play_btn := _menu_button("Jogar (Merge Defense)", Vector2(490, 330))
	play_btn.pressed.connect(func() -> void: play_requested.emit(LevelData.Mode.MERGE))
	_root.add_child(play_btn)

	var td_btn := _menu_button("Tower Defense (Bônus)", Vector2(490, 420))
	var td_unlocked := SaveManager.max_unlocked(LevelData.Mode.MERGE) > 5
	td_btn.disabled = not td_unlocked
	td_btn.text = "Tower Defense (Bônus)" if td_unlocked else "TD Bônus — complete a fase 5"
	td_btn.pressed.connect(func() -> void: play_requested.emit(LevelData.Mode.TOWER_DEFENSE))
	_root.add_child(td_btn)

	var settings_btn := _menu_button("Configurações", Vector2(490, 510))
	settings_btn.pressed.connect(func() -> void: settings_requested.emit())
	_root.add_child(settings_btn)

	TransitionManager.slide_in(_root)

func _menu_button(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = Vector2(300, 70)
	b.add_theme_font_size_override(&"font_size", 26)
	b.pressed.connect(func() -> void: AudioManager.play_sfx_id(&"ui_click"))
	return b
