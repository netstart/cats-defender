extends Control
## Loja premium (5.3 [M10]): 3 categorias, 7 itens; moeda: gems. Sem compras
## com dinheiro real; OrangeBTNAds oculto por feature flag (M24).

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/Ui/ShopScreen.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(1, 1, 1, 0.4)
	add_child(bg)
	var t := Label.new()
	t.text = Localization.tr_key("shop_title")
	t.add_theme_font_size_override("font_size", 32)
	t.position = Vector2(20, 10)
	add_child(t)
	var gems := Label.new()
	gems.text = "💎 %d" % int(SaveSystem.profile.get("gems", 0))
	gems.position = Vector2(880, 16)
	add_child(gems)
	var back := Button.new()
	back.text = Localization.tr_key("ui_back")
	back.position = Vector2(1030, 8)
	back.custom_minimum_size = Vector2(150, 48)
	back.pressed.connect(func():
		AudioManager.play_ui("click")
		GameState.goto_app(GameState.AppState.MENU)
		SceneRouter.goto("res://scenes/main_menu.tscn"))
	add_child(back)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(30, 80)
	grid.size = Vector2(1140, 440)
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	add_child(grid)

	# Tabela item ↔ ícone (5.3)
	var items := [
		{"icon": 1, "box": "ShopBoxGreen.png", "key": "shop_coins_s", "cost": 10, "fn": func(): SaveSystem.add_bank(300)},
		{"icon": 2, "box": "ShopBoxGreen.png", "key": "shop_coins_l", "cost": 25, "fn": func(): SaveSystem.add_bank(900)},
		{"icon": 3, "box": "BlueShopBox.png", "key": "shop_buy_level", "cost": 30, "fn": _buy_level_up},
		{"icon": 4, "box": "BlueShopBox.png", "key": "shop_slots", "cost": 35, "fn": _buy_slot, "maxq": func(): return int(SaveSystem.profile.get("extra_slots", 0)) >= 4},
		{"icon": 5, "box": "BlueShopBox.png", "key": "shop_melee_g", "cost": 20, "fn": func(): _unlock_melee(1)},
		{"icon": 6, "box": "OrangeShopBox.png", "key": "shop_boost", "cost": 8, "fn": func(): SaveSystem.add_bank(150)},
		{"icon": 7, "box": "OrangeShopBox.png", "key": "shop_melee_b", "cost": 20, "fn": func(): _unlock_melee(2)},
	]
	for it in items:
		grid.add_child(_card(it))

func _buy_level_up() -> void:
	SaveSystem.profile["buy_level"] = mini(int(SaveSystem.profile.get("buy_level", 1)) + 1, 5)

func _buy_slot() -> void:
	SaveSystem.profile["extra_slots"] = mini(int(SaveSystem.profile.get("extra_slots", 0)) + 1, 4)

func _unlock_melee(bit: int) -> void:
	SaveSystem.profile["melee_unlocked"] = int(SaveSystem.profile.get("melee_unlocked", 0)) | bit

func _card(it: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(360, 200)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/art/Ui/ShopIcon%d.png" % it["icon"])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(90, 80)
	v.add_child(icon)
	var name := Label.new()
	name.text = Localization.tr_key(it["key"])
	name.add_theme_font_size_override("font_size", 18)
	v.add_child(name)
	var b := Button.new()
	b.text = "%d 💎" % int(it["cost"])
	b.custom_minimum_size = Vector2(150, 44)
	if it.has("maxq") and bool(it["maxq"].call()):
		b.text = "MAX"
		b.disabled = true
	b.pressed.connect(func():
		if int(SaveSystem.profile.get("gems", 0)) < int(it["cost"]):
			AudioManager.play_ui("error")
			return
		SaveSystem.profile["gems"] = int(SaveSystem.profile["gems"]) - int(it["cost"])
		it["fn"].call()
		SaveSystem.save_profile()
		AudioManager.play_ui("buy"))
	v.add_child(b)
	return v
