class_name Hud
extends CanvasLayer
## HUD: moedas, HP do muro, onda, botões (comprar, reparar, habilidades, pausa).

const BUTTON_SIZE := Vector2(150, 64)

var _game: Node  # MergeGame ou TdGame (duck-typed)
var _coins_label: Label
var _wave_label: Label
var _wall_bar: ProgressBar
var _buy_button: Button
var _repair_button: Button
var _ability_container: HBoxContainer

func _ready() -> void:
	layer = 40
	_game = get_parent()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_coins_label = _make_label(30)
	_coins_label.position = Vector2(24, 16)
	root.add_child(_coins_label)

	_wall_bar = ProgressBar.new()
	_wall_bar.position = Vector2(24, 60)
	_wall_bar.size = Vector2(220, 22)
	_wall_bar.show_percentage = false
	root.add_child(_wall_bar)

	_wave_label = _make_label(24)
	_wave_label.position = Vector2(560, 16)
	root.add_child(_wave_label)

	_buy_button = _make_button("Comprar Gato", Vector2(24, 620))
	_buy_button.pressed.connect(_on_buy)
	root.add_child(_buy_button)

	_repair_button = _make_button("Reparar Muro", Vector2(190, 620))
	_repair_button.pressed.connect(_on_repair)
	root.add_child(_repair_button)

	_ability_container = HBoxContainer.new()
	_ability_container.position = Vector2(400, 620)
	_ability_container.add_theme_constant_override(&"separation", 12)
	root.add_child(_ability_container)

	var pause_btn := _make_button("‖", Vector2(1190, 12))
	pause_btn.custom_minimum_size = Vector2(64, 48)
	pause_btn.pressed.connect(_on_pause)
	root.add_child(pause_btn)

	EventBus.currency_changed.connect(_on_currency)
	EventBus.wall_damaged.connect(_on_wall)
	EventBus.wave_started.connect(_on_wave)
	_on_currency(GameManager.currency)
	call_deferred(&"_build_ability_buttons")

func _make_label(font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", Color(1, 0.95, 0.6))
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override(&"outline_size", 6)
	return l

func _make_button(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.custom_minimum_size = BUTTON_SIZE
	b.add_theme_font_size_override(&"font_size", 20)
	return b

func _build_ability_buttons() -> void:
	if not _game.has_method(&"ability_list"):
		return
	for i in _game.ability_list().size():
		var ab: Ability = _game.ability_list()[i]
		var b := _make_button(String(ab.id).capitalize(), Vector2.ZERO)
		b.custom_minimum_size = Vector2(130, 64)
		var idx: int = i
		b.pressed.connect(func() -> void: _game.use_ability(idx))
		_ability_container.add_child(b)

func _on_currency(amount: int) -> void:
	_coins_label.text = "🪙 %d" % amount
	if _game.has_method(&"next_cat_cost"):
		_buy_button.text = "🐱 %d" % _game.next_cat_cost()
		_buy_button.disabled = amount < _game.next_cat_cost()

func _on_wall(current: int, maximum: int) -> void:
	_wall_bar.max_value = maximum
	_wall_bar.value = current
	_repair_button.text = "🔧 %d" % _game.economy.repair_cost(0)

func _on_wave(current: int, total: int) -> void:
	_wave_label.text = "Onda %d/%d" % [current + 1, total]

func _on_buy() -> void:
	if _game.has_method(&"buy_cat"):
		_game.buy_cat()

func _on_repair() -> void:
	if _game.has_method(&"repair_wall"):
		_game.repair_wall()

func _on_pause() -> void:
	AudioManager.play_sfx_id(&"ui_click")
	EventBus.request_pause_menu.emit()
