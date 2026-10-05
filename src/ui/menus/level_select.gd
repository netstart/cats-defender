extends CanvasLayer
## Seleção de fase: grade de botões com estrelas conquistadas (modo merge ou TD).

signal level_picked(mode: LevelData.Mode, index: int)
signal back_requested

const COLS := 6

var _mode: LevelData.Mode = LevelData.Mode.MERGE

func setup(mode: LevelData.Mode) -> void:
	_mode = mode

func _ready() -> void:
	layer = 30
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Merge Defense" if _mode == LevelData.Mode.MERGE else "Tower Defense"
	title.add_theme_font_size_override(&"font_size", 48)
	title.position = Vector2(24, 20)
	add_child(title)

	var total := 30 if _mode == LevelData.Mode.MERGE else 10
	var unlocked := SaveManager.max_unlocked(_mode)
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.position = Vector2(80, 110)
	grid.add_theme_constant_override(&"h_separation", 16)
	grid.add_theme_constant_override(&"v_separation", 16)
	add_child(grid)
	for i in range(1, total + 1):
		grid.add_child(_level_button(i, i <= unlocked))

	var back := Button.new()
	back.text = "← Voltar"
	back.position = Vector2(24, 620)
	back.custom_minimum_size = Vector2(160, 56)
	back.add_theme_font_size_override(&"font_size", 22)
	back.pressed.connect(func() -> void:
		AudioManager.play_sfx_id(&"ui_click")
		back_requested.emit())
	add_child(back)

func _level_button(index: int, unlocked: bool) -> Button:
	var b := Button.new()
	var stars := SaveManager.level_stars(_mode, index)
	var star_text := ""
	for s in 3:
		star_text += "★" if s < stars else "☆"
	b.text = "%d\n%s" % [index, star_text]
	b.custom_minimum_size = Vector2(180, 86)
	b.disabled = not unlocked
	b.add_theme_font_size_override(&"font_size", 22)
	var idx := index
	b.pressed.connect(func() -> void:
		AudioManager.play_sfx_id(&"ui_click")
		level_picked.emit(_mode, idx))
	return b
