extends Control
class_name GameScene
## Cena de partida (PLAYING): orquestra SimWorld (tick fixo, até 4 ticks/frame,
## 2x = 2 ticks/frame — 3.4), espelha views, drag & drop, HUD e popups.

const ART_UI := "res://assets/art/Ui/"

# --- Layout (3.0) referência 1200x540 ---
const BOARD_X := 14.0
const BOARD_Y := 66.0
const SLOT_W := 112.0
const SLOT_H := 110.0
const BOARD_COLS := 4
const ROUTE_X0 := 480.0
const ROUTE_X1 := 1180.0
const LANE_Y := 315.0
const MENU_SCENE := "res://scenes/level_select.tscn"

var sim: SimWorld
var balance: Balance
var stage: Dictionary
var stage_id := "P1"
var speed_mult := 1

# nós de view
var _cat_views: Dictionary = {}      # slot -> CatTowerView
var _enemy_views: Dictionary = {}    # sim id -> EnemyView
var _bullets: Array = []
var _acc := 0.0
var _drag := {}                       # {slot} durante drag
var _ghost: AnimatedSprite2D = null
var _sell_zone: Control = null
var _sell_tween_gate := {}
var _long_press_slot := -1

# HUD
var _coins_lbl: Label
var _gems_lbl: Label
var _wave_lbl: Label
var _base_bar: TextureRect
var _boss_bar: TextureProgressBar
var _buy_btn: Button
var _start_btn: Button
var _speed_btn: Button
var _prep_lbl: Label
var _banner_lbl: Label
var _info_panel: PanelContainer
var _slow_fx := {}
var _won := false

func _init() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

func _ready() -> void:
	balance = Balance.new()
	if GameState.current_stage_id != "":
		stage_id = GameState.current_stage_id
	stage = StageDatabase.get_stage(stage_id)
	sim = SimWorld.new(balance, int(Time.get_unix_time_from_system()) % 100000 + 1)
	sim.setup(stage, SaveSystem.profile)
	GameState.reset_play()
	GameState.goto_app(GameState.AppState.PLAYING)
	GameState.goto_play(GameState.PlaySub.PREP)
	_build_ui()
	_restore_checkpoint()
	if OS.is_debug_build():
		add_child(DebugMenu.new())
	if not bool(SaveSystem.profile.get("tutorial_seen", false)) and stage_id == "P1":
		_tutorial()
	AudioManager.play_music("phase_theme", -8.0)
	EventBus.haptic(0)

func set_stage(id: String) -> void:
	stage_id = id

# ============================ UI ============================

func _build_ui() -> void:
	_bg()
	_board()
	_route_base()
	_hud_top()
	_action_bar()
	_sell_zone_ui()
	_popups()
	_ghost = AnimatedSprite2D.new()
	_ghost.visible = false
	_ghost.z_index = 30
	add_child(_ghost)

func _bg() -> void:
	var tex: Texture2D = load(stage.get("bg", "res://assets/art/Area/Area1.png"))
	var bg := TextureRect.new()
	bg.texture = tex
	bg.position = Vector2(ROUTE_X0, 60)
	bg.size = Vector2(ROUTE_X1 - ROUTE_X0, 410)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var board_bg := ColorRect.new()
	board_bg.color = Color(0.10, 0.09, 0.14, 0.92)
	board_bg.position = Vector2(0, 0)
	board_bg.size = Vector2(ROUTE_X0, 540)
	add_child(board_bg)

func _board() -> void:
	var n := sim.slot_count
	for i in n:
		var r := i / BOARD_COLS
		var c := i % BOARD_COLS
		var slot := Panel.new()
		slot.position = Vector2(BOARD_X + c * (SLOT_W + 4), BOARD_Y + r * (SLOT_H + 4))
		slot.size = Vector2(SLOT_W, SLOT_H)
		slot.name = "Slot%d" % i
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.07)
		sb.border_color = Color(1, 1, 1, 0.25)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		slot.add_theme_stylebox_override("panel", sb)
		add_child(slot)
	var border := TextureRect.new()
	border.texture = load(ART_UI + "SelectedBorder.png")
	border.name = "Highlight"
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.visible = false
	border.z_index = 12
	add_child(border)

func slot_center(i: int) -> Vector2:
	var r := i / BOARD_COLS
	var c := i % BOARD_COLS
	return Vector2(BOARD_X + c * (SLOT_W + 4) + SLOT_W / 2, BOARD_Y + r * (SLOT_H + 4) + SLOT_H / 2)

func slot_index_at(pos: Vector2) -> int:
	for i in sim.slot_count:
		var c := slot_center(i)
		if Rect2(c - Vector2(SLOT_W / 2, SLOT_H / 2), Vector2(SLOT_W, SLOT_H)).has_point(pos):
			return i
	return -1

func _route_base() -> void:
	# base à direita (+ HP visual 0Bar..5Bar)
	var base := TextureRect.new()
	base.texture = load(ART_UI + "5Bar.png")
	base.name = "BaseBarTex"
	base.position = Vector2(ROUTE_X1 - 40, 150)
	base.size = Vector2(34, 200)
	base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(base)
	_base_bar = base

func _hud_top() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(6, 4)
	bar.size = Vector2(1188, 52)
	bar.add_theme_constant_override("separation", 14)
	add_child(bar)
	_coins_lbl = _value_label(bar, "CoinIcon.png")
	_gems_lbl = _value_label(bar, "GemsIcon.png")
	_wave_lbl = Label.new()
	_wave_lbl.name = "WaveLabel"
	bar.add_child(_wave_lbl)
	_prep_lbl = Label.new()
	bar.add_child(_prep_lbl)
	var pause := _tex_button(ART_UI + "SettingBtn.png", "", 46)
	bar.add_child(pause)
	pause.pressed.connect(_on_pause)
	_update_coins()

func _value_label(parent: Control, icon: String) -> Label:
	var h := HBoxContainer.new()
	var tex := TextureRect.new()
	tex.texture = load(ART_UI + icon)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(34, 34)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	h.add_child(tex)
	var l := Label.new()
	l.text = "0"
	h.add_child(l)
	parent.add_child(h)
	return l

func _tex_button(tex_path: String, text: String, h: float = 56.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(h, h)
	b.pressed.connect(func(): AudioManager.play_ui("click"))
	return b

func _action_bar() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(6, 478)
	bar.size = Vector2(1188, 58)
	bar.add_theme_constant_override("separation", 12)
	add_child(bar)
	_buy_btn = Button.new()
	_buy_btn.text = Localization.tr_key("ui_buy")
	_buy_btn.custom_minimum_size = Vector2(200, 56)
	_buy_btn.add_theme_font_size_override("font_size", 26)
	_buy_btn.pressed.connect(_on_buy)
	bar.add_child(_buy_btn)
	# melee
	var g := Button.new()
	g.text = "🛡 Guardian (30)"
	g.custom_minimum_size = Vector2(170, 56)
	g.pressed.connect(func(): _on_melee("guardian"))
	bar.add_child(g)
	var bx := Button.new()
	bx.text = "🥊 Boxing (30)"
	bx.custom_minimum_size = Vector2(160, 56)
	bx.pressed.connect(func(): _on_melee("boxing"))
	bar.add_child(bx)
	_speed_btn = Button.new()
	_speed_btn.text = "1×"
	_speed_btn.custom_minimum_size = Vector2(90, 56)
	_speed_btn.pressed.connect(_on_speed)
	bar.add_child(_speed_btn)
	_start_btn = Button.new()
	_start_btn.text = Localization.tr_key("ui_start_wave")
	_start_btn.custom_minimum_size = Vector2(220, 56)
	_start_btn.pressed.connect(_on_start_wave)
	bar.add_child(_start_btn)

func _sell_zone_ui() -> void:
	_sell_zone = PanelContainer.new()
	_sell_zone.position = Vector2(BOARD_X + 4 * (SLOT_W + 4) + 8, BOARD_Y + 2 * (SLOT_H + 4))
	_sell_zone.custom_minimum_size = Vector2(0, 0)
	var l := Label.new()
	l.text = Localization.tr_key("ui_sell_zone")
	_sell_zone.add_child(l)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.5, 0.1, 0.1, 0.35)
	sb.set_corner_radius_all(8)
	_sell_zone.add_theme_stylebox_override("panel", sb)
	_sell_zone.visible = false
	add_child(_sell_zone)

var _win_popup: Control
var _lose_popup: Control
var _pause_popup: Control

func _popups() -> void:
	_banner_lbl = Label.new()
	_banner_lbl.position = Vector2(480, 120)
	_banner_lbl.size = Vector2(700, 80)
	_banner_lbl.add_theme_font_size_override("font_size", 40)
	_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_lbl.visible = false
	add_child(_banner_lbl)
	_boss_bar = TextureProgressBar.new()
	_boss_bar.position = Vector2(ROUTE_X0 + 60, 66)
	_boss_bar.size = Vector2(400, 18)
	_boss_bar.max_value = 100
	_boss_bar.visible = false
	add_child(_boss_bar)
	_win_popup = _build_win_popup()
	_lose_popup = _build_lose_popup()
	_pause_popup = _build_pause_popup()
	add_child(_win_popup)
	add_child(_lose_popup)
	add_child(_pause_popup)

func _popup_base(tex_name: String) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(dim)
	var tex := TextureRect.new()
	tex.texture = load(ART_UI + tex_name)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.size = Vector2(560, 420)
	tex.position = (Vector2(1200, 540) - tex.size) / 2
	c.add_child(tex)
	return c

func _popup_buttons(c: Control, defs: Array) -> Array:
	var out := []
	var y := 380.0
	for d in defs:
		var b := Button.new()
		b.text = Localization.tr_key(d["text"])
		b.custom_minimum_size = Vector2(240, 52)
		b.position = Vector2(600 - 120, y)
		b.add_theme_font_size_override("font_size", 24)
		y += 60.0
		c.add_child(b)
		if d.has("fn"):
			b.pressed.connect(d["fn"])
		out.append(b)
	return out

func _build_win_popup() -> Control:
	var c := _popup_base("WinPopUp.png")
	var stars := Label.new()
	stars.name = "StarsLabel"
	stars.position = Vector2(600 - 150, 210)
	stars.size = Vector2(300, 50)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 34)
	c.add_child(stars)
	var defs := [
		{"text": "ui_continue", "fn": _popup_exit},
		{"text": "ui_replay", "fn": _popup_replay},
	]
	_popup_buttons(c, defs)
	return c

func _build_lose_popup() -> Control:
	var c := _popup_base("LosePopUp.png")
	var defs := [
		{"text": "ui_retry", "fn": _popup_replay},
		{"text": "ui_continue", "fn": _popup_exit},
	]
	_popup_buttons(c, defs)
	return c

func _build_pause_popup() -> Control:
	var c := _popup_base("BgPaused.png")
	var btns := _popup_buttons(c, [
		{"text": "ui_resume", "fn": _popup_resume},
		{"text": "ui_restart", "fn": _popup_replay},
		{"text": "ui_keep_effects", "fn": _toggle_reduce},
		{"text": "ui_exit", "fn": _popup_exit},
	])
	return c

func _toggle_reduce() -> void:
	GameSettings.set_reduce_fx(not GameSettings.reduce_fx)

func _popup_resume() -> void:
	_pause_popup.visible = false
	GameState.goto_app(GameState.AppState.PLAYING)
	get_tree().paused = false

func _popup_replay() -> void:
	SaveSystem.clear_checkpoint()
	get_tree().paused = false
	GameState.goto_app(GameState.AppState.LOADING)
	SceneRouter.goto("res://scenes/game.tscn")

func _popup_exit() -> void:
	get_tree().paused = false
	SaveSystem.clear_checkpoint()
	GameState.goto_app(GameState.AppState.LEVEL_SELECT)
	SceneRouter.goto(MENU_SCENE)

# ============================ Input / drag ============================

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_pause()
		return
	var pos := Vector2.ZERO
	if event is InputEventScreenTouch:
		pos = event.position
		if not event.pressed:
			_end_drag(pos)
	elif event is InputEventScreenDrag:
		pos = event.position
		_update_drag(pos)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		if not event.pressed:
			_end_drag(get_global_mouse_position())
	elif event is InputEventMouseMotion:
		_update_drag(get_global_mouse_position())

func begin_drag(slot: int) -> void:
	if GameState.play_sub in [GameState.PlaySub.DEFEAT, GameState.PlaySub.VICTORY]:
		return
	if _drag.has("slot"):
		return
	_drag = {"slot": slot}
	var bg := _build_ghost_for(slot)
	if bg:
		_ghost.sprite_frames = bg
		_ghost.play("idle")
	_ghost.visible = true
	_ghost.modulate = Color(1, 1, 1, 0.75)
	_sell_zone.visible = true

func _build_ghost_for(slot: int) -> SpriteFrames:
	var t: Dictionary = sim.towers[slot] if slot < sim.towers.size() and sim.towers[slot] != null else {}
	if t.is_empty():
		return null
	if t.get("kind", "ranged") == "ranged":
		return FrameLoader.load_character(CatTowerView.tier_dir(int(t["tier"])), {"idle": ["Idle", 18, true]})
	return FrameLoader.load_character(CatTowerView.melee_dir(t["kind"]), {"idle": ["Idle", 18, true]})

func _update_drag(pos: Vector2) -> void:
	if _drag.is_empty():
		return
	# fantasma ~1 slot acima do dedo (M15)
	_ghost.position = pos + Vector2(0, -SLOT_H * 0.9)
	var idx := slot_index_at(pos)
	var hl := get_node("Highlight") as TextureRect
	if idx >= 0:
		hl.visible = true
		hl.position = slot_center(idx) - Vector2(SLOT_W / 2 + 8, SLOT_H / 2 + 8)
		hl.size = Vector2(SLOT_W + 16, SLOT_H + 16)
		hl.modulate = _drop_highlight_color(idx)
	elif _sell_zone.get_global_rect().has_point(pos):
		hl.visible = true
		hl.position = _sell_zone.position
		hl.size = _sell_zone.size
		hl.modulate = Color(1, 0.3, 0.3)
	else:
		hl.visible = false

func _drop_highlight_color(idx: int) -> Color:
	var from_slot: int = _drag["slot"]
	var tgt: Dictionary = sim.towers[idx] if idx >= 0 and sim.towers[idx] != null else {}
	var src: Dictionary = sim.towers[from_slot]
	if tgt.is_empty():
		return Color(0.4, 1, 0.4)     # mover
	if int(tgt.get("tier", -1)) == int(src.get("tier", -2)) and src.get("kind", "ranged") == tgt.get("kind", "ranged") and src.get("kind") == "ranged":
		if int(tgt["tier"]) < sim.tier_cap:
			return Color(0.2, 0.8, 1)  # merge
		return Color(1, 0.2, 0.2)      # merge inválido: nível máximo
	return Color(1, 0.85, 0.3)         # swap

func _end_drag(pos: Vector2) -> void:
	if _drag.is_empty():
		return
	var from_slot: int = _drag["slot"]
	_drag.clear()
	_ghost.visible = false
	(get_node("Highlight") as TextureRect).visible = false
	_sell_zone.visible = false
	if _sell_zone.get_global_rect().has_point(pos):
		_sell(from_slot)
		return
	var idx := slot_index_at(get_parent().get_local_mouse_position() if false else pos)
	if idx < 0 or idx == from_slot:
		return   # soltar fora: volta (3.2)
	var result := sim.move_cat(from_slot, idx)
	match result:
		"merged":
			_on_merged(idx)
		"swapped", "moved":
			_refresh_cats()
	EventBus.haptic(20)

func _on_merged(slot: int) -> void:
	var t: Dictionary = sim.towers[slot]
	var v: CatTowerView = _cat_views.get(slot)
	if v:
		v.set_tier(int(t["tier"]))
		# juice: pulso de escala (4.1)
		if not GameSettings.reduce_fx:
			v.scale = Vector2(1.25, 1.25)
			var tw := create_tween()
			tw.tween_property(v, "scale", Vector2.ONE, 0.25)
	EventBus.merge_performed.emit(slot, slot, int(t["tier"]))
	AudioManager.play_sfx("merge")
	EventBus.haptic(30)

func _refresh_cats() -> void:
	for v in _cat_views.values():
		remove_child(v)
		v.queue_free()
	_cat_views.clear()
	for slot in sim.towers.size():
		var t: Dictionary = sim.towers[slot] if sim.towers[slot] != null else {}
		if t.is_empty():
			continue
		_spawn_cat_view(slot, t)

func _spawn_cat_view(slot: int, t: Dictionary) -> void:
	var v := CatTowerView.new()
	add_child(v)
	v.setup(slot, int(t["tier"]), t.get("kind", "ranged"))
	if v.kind == "ranged":
		v.position = slot_center(slot)
	else:
		var px: float = t.get("position_p", 0.85)
		v.position = Vector2(prog_to_x(px), LANE_Y - 60)
	v.tapped.connect(_on_cat_tap)
	v.long_pressed.connect(_on_cat_long_press)
	v.drag_began.connect(_on_cat_drag)
	_cat_views[slot] = v

func _on_cat_tap(v: CatTowerView) -> void:
	var mode := sim.cycle_targeting(v.slot)
	if mode != "":
		EventBus.haptic(15)
		_show_info(v)

func _on_cat_long_press(v: CatTowerView) -> void:
	_show_info(v)

func _on_cat_drag(v: CatTowerView) -> void:
	begin_drag(v.slot)

func _show_info(v: CatTowerView) -> void:
	var t: Dictionary = sim.towers[v.slot] if sim.towers[v.slot] != null else {}
	if t.is_empty():
		return
	if _info_panel:
		_info_panel.queue_free()
	_info_panel = PanelContainer.new()
	var l := Label.new()
	l.text = "C%d  DMG %d  RNG %d%%  [%s]" % [int(t["tier"]), int(sim.cat_damage_for(v.slot)), int(sim.cat_range_for(t) * 100.0), t.get("targeting", "first")]
	_info_panel.add_child(l)
	_info_panel.position = v.position + Vector2(-40, -90)
	add_child(_info_panel)
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(_clear_info_panel)

func _clear_info_panel() -> void:
	if is_instance_valid(_info_panel):
		_info_panel.queue_free()

# ============================ Botões ============================

var _buy_debounce := 0.0

func _on_buy() -> void:
	if _buy_debounce > 0.0:
		return
	_buy_debounce = 0.15
	var free_slot := sim.first_free_slot()
	if free_slot == -1:
		EventBus.buy_failed.emit("board_full")
		AudioManager.play_ui("error")
		return
	var tier := sim.buy_cat()
	if tier < 0:
		EventBus.buy_failed.emit("no_coins")
		AudioManager.play_ui("error")
		return
	var t := sim.place_new_cat(free_slot, tier, 0)
	_spawn_cat_view(free_slot, t)
	EventBus.cat_bought.emit(tier)
	AudioManager.play_ui("buy")
	_update_coins()

func _on_melee(kind: String) -> void:
	var bit := 1 if kind == "guardian" else 2
	if int(SaveSystem.profile.get("melee_unlocked", 0)) & bit == 0:
		EventBus.buy_failed.emit("locked")
		AudioManager.play_ui("error")
		return
	if sim.place_melee(kind):
		var slot: int = SimWorld.MELEE_SLOTS[0 if kind == "guardian" else 1]
		_spawn_cat_view(slot, sim.towers[slot])
		AudioManager.play_ui("buy")
	else:
		AudioManager.play_ui("error")

func _on_speed() -> void:
	speed_mult = 3 - speed_mult   # 1 <-> 2
	_speed_btn.text = "%d×" % speed_mult

func _on_start_wave() -> void:
	var bonus := sim.start_wave_early()
	if bonus > 0:
		EventBus.haptic(15)

func _on_pause() -> void:
	if GameState.app_state != GameState.AppState.PLAYING:
		return
	GameState.goto_app(GameState.AppState.PAUSED)
	get_tree().paused = true
	_pause_popup.visible = true
	_checkpoint_now()

func _sell(slot: int) -> void:
	var refund := sim.sell_cat(slot)
	if refund > 0:
		if _cat_views.has(slot):
			_cat_views[slot].queue_free()
			_cat_views.erase(slot)
		EventBus.cat_sold.emit(slot, refund)
		AudioManager.play_sfx("sell")

# ============================ Loop ============================

func _process(delta: float) -> void:
	if _buy_debounce > 0.0:
		_buy_debounce -= delta
	if GameState.app_state != GameState.AppState.PLAYING:
		return
	_acc += delta
	var ticks := 0
	var max_ticks := SimWorld.MAX_TICKS_PER_FRAME * speed_mult
	while _acc >= SimWorld.SIM_DT and ticks < max_ticks:
		_acc -= SimWorld.SIM_DT
		ticks += 1
		var events: Array = sim.tick()
		_dispatch_events(events)
	_sync_views(delta)
	_hud_update()

func _dispatch_events(events: Array) -> void:
	for ev in events:
		match String(ev["type"]):
			SimEvents.ENEMY_SPAWNED:
				_spawn_enemy_view(ev)
			SimEvents.ENEMY_DIED:
				_on_enemy_died(ev)
			SimEvents.BULLET_FIRED:
				_spawn_bullet_view(ev)
			SimEvents.BULLET_HIT:
				_bullet_impact(ev)
			SimEvents.CAT_FIRED:
				var v: CatTowerView = _cat_views.get(int(ev["slot"]))
				if v:
					v.play_shoot()
			SimEvents.MELEE_HIT:
				var v2: CatTowerView = _cat_views.get(int(ev["slot"]))
				if v2:
					v2.play_shoot()
			SimEvents.WAVE_STARTED:
				_on_wave_started(ev)
			SimEvents.WAVE_CLEARED:
				GameState.goto_play(GameState.PlaySub.WAVE_CLEAR)
				GameState.goto_play(GameState.PlaySub.PREP)
				_checkpoint_now()
			SimEvents.BOSS_SPAWNED:
				_boss_bar.visible = true
				AudioManager.play_sfx("boss_alert")
			SimEvents.BOSS_ENRAGED:
				AudioManager.play_sfx("boss_alert")
			SimEvents.BASE_DAMAGED:
				_on_base_damage(ev)
			SimEvents.EXPLOSION:
				_on_explosion(ev)
			SimEvents.STAGE_WON:
				_on_win(int(ev.get("stars", 1)))
			SimEvents.STAGE_LOST:
				_on_lose()

func _spawn_enemy_view(ev: Dictionary) -> void:
	var v := EnemyView.new()
	add_child(v)
	v.setup(int(ev["id"]), String(ev["type"]), bool(ev.get("boss", false)))
	v.position = Vector2(ROUTE_X0 - 20, LANE_Y + randf_range(-14, 14))
	_enemy_views[int(ev["id"])] = v

func _spawn_bullet_view(ev: Dictionary) -> void:
	var b := BulletView.new()
	add_child(b)
	b.z_index = 7
	b.setup(int(ev["id"]), String(ev["kind"]))
	b.position = Vector2(prog_to_x(float(ev["p"])), LANE_Y - 70)
	_bullets.append(b)

func _bullet_impact(ev: Dictionary) -> void:
	var vid := int(ev["target"])
	if _enemy_views.has(vid):
		_enemy_views[vid].flash_hit()
		if not GameSettings.reduce_fx:
			var dn := DamageNumberView.new()
			add_child(dn)
			dn.setup(0, _enemy_views[vid].position + Vector2(0, -80))

func _on_enemy_died(ev: Dictionary) -> void:
	var vid := int(ev["id"])
	if _enemy_views.has(vid):
		# anim Dead toca no sync; libera view após término
		_enemy_views[vid].set_meta("dying", true)
	AudioManager.play_sfx("enemy_die")
	_spawn_coin(float(ev["p"]), int(ev.get("reward", 0)))

func _spawn_coin(p: float, amount: int) -> void:
	var c := CoinView.new()
	add_child(c)
	c.collected.connect(_on_coin_collected)
	c.setup(amount, Vector2(prog_to_x(p), LANE_Y - 50), 470, _coins_lbl)

func _on_coin_collected(_amount: int) -> void:
	AudioManager.play_sfx("coin")

func _on_wave_started(ev: Dictionary) -> void:
	GameState.goto_play(GameState.PlaySub.BOSS if bool(ev.get("boss", false)) else GameState.PlaySub.WAVE_ACTIVE)
	_banner_lbl.text = "%s %d/%d" % [Localization.tr_key("ui_wave"), int(ev["wave"]) + 1, int(ev["total"])]
	_banner_lbl.visible = true
	AudioManager.play_ui("wave_start")
	get_tree().create_timer(1.2).timeout.connect(func(): _banner_lbl.visible = false)

func _on_base_damage(ev: Dictionary) -> void:
	var hpr := float(ev["hp"]) / float(ev["max"])
	var idx := clampi(int(ceil(hpr * 5.0)), 0, 5)
	_base_bar.texture = load("%s%dBar.png" % [ART_UI, idx])
	if not GameSettings.reduce_fx:
		modulate = Color(1.15, 0.9, 0.9)
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	EventBus.haptic(40)

func _on_explosion(ev: Dictionary) -> void:
	if GameSettings.reduce_fx:
		return
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = FrameLoader.load_character("res://assets/art/Explosion", {"boom": [".", 24, false]})
	add_child(fx)
	fx.position = Vector2(prog_to_x(float(ev["p"])), LANE_Y - 60)
	fx.z_index = 9
	fx.play("boom")
	fx.animation_finished.connect(fx.queue_free)
	if bool(ev.get("boss_hit", false)) and not GameSettings.reduce_fx:
		pass

func _shake(strength := 4.0) -> void:
	if GameSettings.reduce_fx:
		return
	var tw := create_tween()
	tw.tween_property(self, "position", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)), 0.05)
	tw.tween_property(self, "position", Vector2.ZERO, 0.06)

func _on_win(stars: int) -> void:
	if _won:
		return
	_won = true
	GameState.goto_app(GameState.AppState.WIN)
	get_tree().paused = true
	var entry := SaveSystem.record_stage_result(stage_id, stars, true)
	SaveSystem.add_bank(int(balance.getf("win_payout", 120)))
	SaveSystem.add_gems(sim.stage_gems(stars))
	SaveSystem.clear_checkpoint()
	_win_popup.get_node("StarsLabel").text = "★".repeat(stars) + "☆".repeat(3 - stars)
	_win_popup.visible = true
	AudioManager.play_sfx("win")
	AudioManager.duck_music(true)

func _on_lose() -> void:
	if _won:
		return
	_won = true
	GameState.goto_app(GameState.AppState.LOSE)
	get_tree().paused = true
	SaveSystem.add_bank(int(balance.getf("win_payout", 120) * balance.getf("lose_payout_ratio", 0.3)))
	SaveSystem.clear_checkpoint()
	_lose_popup.visible = true
	AudioManager.play_sfx("lose")
	AudioManager.duck_music(true)

func _sync_views(delta: float) -> void:
	# inimigos
	for e in sim.enemies:
		var v: EnemyView = _enemy_views.get(int(e["id"]))
		if v == null:
			continue
		v.position.x = prog_to_x(float(e["progress"]))
		v.sync_from_sim(e, delta)
		if v.has_meta("dying") and v.is_dead_finished():
			remove_child(v)
			v.queue_free()
			_enemy_views.erase(int(e["id"]))
	# projéteis
	var remove := []
	for b in _bullets:
		var found := false
		for bs in sim.bullets:
			if int(bs["id"]) == b.sim_id:
				b.position.x = prog_to_x(float(bs["p"]))
				found = true
		if not found:
			b.queue_free()
			remove.append(b)
	for b in remove:
		_bullets.erase(b)
	# boss bar
	if _boss_bar.visible:
		for e in sim.enemies:
			if e.get("boss", false):
				_boss_bar.value = 100.0 * float(e["hp"]) / float(e["max_hp"])
				break

func _hud_update() -> void:
	_wave_lbl.text = "%s %d/%d" % [Localization.tr_key("ui_wave"), maxi(0, sim.wave_index + 1), sim.total_waves]
	if sim.phase == SimWorld.S_PREP:
		_prep_lbl.text = "%ss" % str(int(ceil(sim.prep_timer)))
	else:
		_prep_lbl.text = ""

func _update_coins() -> void:
	_coins_lbl.text = str(sim.run_coins)
	_gems_lbl.text = str(SaveSystem.profile.get("gems", 0))

func prog_to_x(p: float) -> float:
	return ROUTE_X0 + p * (ROUTE_X1 - ROUTE_X0)

# ============================ Tutorial contextual (4.2/G01) ============================

func _tutorial() -> void:
	var steps := [
		{"text": "tutorial_step_buy", "at": Vector2(140, 420), "wait": "buy"},
		{"text": "tutorial_step_merge", "at": Vector2(200, 200), "wait": "merge"},
		{"text": "tutorial_step_start", "at": Vector2(1080, 420), "wait": "wave"},
	]
	var tip := Label.new()
	tip.add_theme_font_size_override("font_size", 26)
	tip.z_index = 40
	add_child(tip)
	for s in steps:
		tip.text = Localization.tr_key(String(s["text"]))
		tip.position = s["at"]
		tip.visible = true
		var wait_kind: String = s["wait"]
		var done := false
		var conn: Callable
		conn = func(_a = null, _b = null, _c = null):
			done = true
		match wait_kind:
			"buy":
				EventBus.cat_bought.connect(conn, CONNECT_ONE_SHOT)
			"merge":
				EventBus.merge_performed.connect(conn, CONNECT_ONE_SHOT)
			"wave":
				EventBus.wave_started.connect(conn, CONNECT_ONE_SHOT)
		var timeout := 30.0
		while not done and timeout > 0.0:
			await get_tree().create_timer(0.2).timeout
			timeout -= 0.2
	tip.visible = false
	SaveSystem.profile["tutorial_seen"] = true
	SaveSystem.save_profile()

# ============================ Checkpoint (M04) ============================

func _checkpoint_now() -> void:
	SaveSystem.save_checkpoint(sim.serialize())

func _restore_checkpoint() -> void:
	var data := SaveSystem.load_checkpoint()
	if data.is_empty():
		return
	if String(data.get("stage_id", "")) != stage.id:
		SaveSystem.clear_checkpoint()
		return
	GameState.goto_play(GameState.PlaySub.PREP)
	sim.deserialize(data)
	_refresh_cats()
	_update_coins()
	SaveSystem.clear_checkpoint()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_PAUSED:
		if GameState.app_state == GameState.AppState.PLAYING:
			_checkpoint_now()
			_on_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_pause()
