extends Control
## Tela de Addons (5.2/5.4): destrava tipos com bank_coins; equipe se dá
## in-run. Ícones AddonIcon1..8.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/Ui/AddonScreen.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(1, 1, 1, 0.35)
	add_child(bg)

	var t := Label.new()
	t.text = Localization.tr_key("addon_title")
	t.add_theme_font_size_override("font_size", 32)
	t.position = Vector2(20, 10)
	add_child(t)
	var back := Button.new()
	back.text = Localization.tr_key("ui_back")
	back.position = Vector2(1030, 8)
	back.custom_minimum_size = Vector2(150, 48)
	back.pressed.connect(func():
		AudioManager.play_ui("click")
		GameState.goto_app(GameState.AppState.LEVEL_SELECT)
		SceneRouter.goto("res://scenes/level_select.tscn"))
	add_child(back)
	var bank := Label.new()
	bank.text = "🪙 %d" % int(SaveSystem.profile.get("bank_coins", 0))
	bank.position = Vector2(860, 16)
	add_child(bank)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.position = Vector2(40, 80)
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	add_child(grid)
	var bal := Balance.new()
	var i := 1
	for id in bal.addons:
		grid.add_child(_card(id, bal.addons[id], i))
		i += 1

func _card(id: String, def: Dictionary, idx: int) -> Control:
	var v := VBoxContainer.new()
	var icon := TextureRect.new()
	icon.texture = load("res://assets/art/Ui/AddonIcon%d.png" % idx)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(80, 80)
	v.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = Localization.tr_key("addon_" + id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_lbl)
	var desc := Label.new()
	desc.text = Localization.tr_key("addon_%s_desc" % id)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(240, 60)
	desc.add_theme_font_size_override("font_size", 14)
	v.add_child(desc)
	var b := Button.new()
	var unlocked: bool = id in SaveSystem.profile.get("unlocked_addons", [])
	if unlocked:
		b.text = Localization.tr_key("addon_unlocked")
		b.disabled = true
	else:
		b.text = "%d 🪙" % int(def["bank"])
		b.custom_minimum_size = Vector2(150, 40)
		b.pressed.connect(func(): _unlock(id, int(def["bank"]), b))
	v.add_child(b)
	return v

func _unlock(id: String, cost: int, b: Button) -> void:
	if int(SaveSystem.profile.get("bank_coins", 0)) < cost:
		AudioManager.play_ui("error")
		return
	SaveSystem.profile["bank_coins"] = int(SaveSystem.profile["bank_coins"]) - cost
	var list: Array = SaveSystem.profile.get("unlocked_addons", [])
	list.append(id)
	SaveSystem.profile["unlocked_addons"] = list
	SaveSystem.save_profile()
	b.text = Localization.tr_key("addon_unlocked")
	b.disabled = true
	AudioManager.play_ui("buy")
