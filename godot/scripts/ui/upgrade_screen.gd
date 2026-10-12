extends Control
## Tela de Upgrade de gatos (5.4 [M10]): 15 trilhas (Uplogo1..15), 4 níveis
## (Up0..Up3), custo em bank_coins escalando geometricamente; acima do tier_cap
## da próxima fase, mostra cadeado (LockedCatBox).

const UPGRADE_BASE_COST := 60
const TIER_CAP_UI := 15

var _grid: GridContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/Ui/CatUpgradeScreen.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(1, 1, 1, 0.35)
	add_child(bg)

	var top := HBoxContainer.new()
	top.position = Vector2(20, 10)
	top.size = Vector2(1160, 50)
	add_child(top)
	var t := Label.new()
	t.text = Localization.tr_key("upgrade_title")
	t.add_theme_font_size_override("font_size", 32)
	top.add_child(t)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var bank := Label.new()
	bank.name = "BankLabel"
	bank.text = "🪙 %d" % int(SaveSystem.profile.get("bank_coins", 0))
	bank.add_theme_font_size_override("font_size", 24)
	top.add_child(bank)
	var back := Button.new()
	back.text = Localization.tr_key("ui_back")
	back.pressed.connect(func():
		AudioManager.play_ui("click")
		GameState.goto_app(GameState.AppState.LEVEL_SELECT)
		SceneRouter.goto("res://scenes/level_select.tscn"))
	top.add_child(back)

	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.position = Vector2(24, 70)
	_grid.size = Vector2(1150, 460)
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	add_child(_grid)
	_build_rows()

func _build_rows() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var upgrades: Dictionary = SaveSystem.profile.get("cat_upgrades", {})
	for tier in range(1, 16):
		var lvl := int(upgrades.get(str(tier), 0))
		_grid.add_child(_card(tier, lvl))

func _card(tier: int, lvl: int) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/art/Ui/Uplogo%d.png" % tier)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(84, 70)
	v.add_child(icon)
	var pips := TextureRect.new()
	pips.texture = load("res://assets/art/Ui/Up%d.png" % clampi(lvl, 0, 3))
	pips.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pips.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pips.custom_minimum_size = Vector2(84, 16)
	v.add_child(pips)
	var b := Button.new()
	if lvl >= 4:
		b.text = "MAX"
		b.disabled = true
	else:
		b.text = "%d 🪙" % _cost(lvl)
	b.custom_minimum_size = Vector2(120, 34)
	b.pressed.connect(func(): _buy(tier))
	v.add_child(b)
	return v

func _cost(lvl: int) -> int:
	return int(UPGRADE_BASE_COST * pow(2.4, lvl))

func _buy(tier: int) -> void:
	var upgrades: Dictionary = SaveSystem.profile.get("cat_upgrades", {})
	var lvl := int(upgrades.get(str(tier), 0))
	if lvl >= 4:
		return
	var c := _cost(lvl)
	if int(SaveSystem.profile.get("bank_coins", 0)) < c:
		AudioManager.play_ui("error")
		return
	SaveSystem.profile["bank_coins"] = int(SaveSystem.profile["bank_coins"]) - c
	upgrades[str(tier)] = lvl + 1
	SaveSystem.profile["cat_upgrades"] = upgrades
	SaveSystem.save_profile()
	AudioManager.play_ui("buy")
	get_node_or_null("BankLabel")
	_ready_refresh()

func _ready_refresh() -> void:
	_build_rows()
