extends Control
class_name DebugMenu
## Debug menu (M26) — somente build debug. Tecla F3 alterna.
## Dar moedas, spawnar gato C{1..15}, pular onda, matar chefe, 2x, overlay.

var layer: CanvasLayer
var panel: PanelContainer
var perf: Label
var perf_on := false
var overlay: Label = null

func _init() -> void:
	if not OS.is_debug_build():
		return
	name = "DebugMenu"
	layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	panel = PanelContainer.new()
	panel.position = Vector2(6, 66)
	panel.visible = false
	layer.add_child(panel)
	_build()
	overlay = Label.new()
	overlay.position = Vector2(6, 6)
	overlay.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
	overlay.add_theme_font_size_override("font_size", 14)
	overlay.visible = false
	layer.add_child(overlay)

func _build() -> void:
	var v := VBoxContainer.new()
	panel.add_child(v)
	var defs := [
		["+500 coins", func(): _world().run_coins += 500],
		["Spawn C1", func(): _spawn(1)],
		["Spawn C8", func(): _spawn(8)],
		["Spawn C13", func(): _spawn(13)],
		["Spawn C15", func(): _spawn(15)],
		["Pular onda", func(): _world().start_wave_early()],
		["Matar chefe", _kill_boss],
		["Perf overlay", _toggle_perf],
	]
	for d in defs:
		var b := Button.new()
		b.text = String(d[0])
		b.custom_minimum_size = Vector2(180, 36)
		b.pressed.connect(d[1])
		add_child.call_deferred(b)
		v.add_child(b)

func _world() -> SimWorld:
	var g := get_tree().current_scene
	return g.sim if g and g.get("sim") != null else null

func _game() -> Node:
	return get_tree().current_scene

func _spawn(tier: int) -> void:
	var w := _world()
	if w == null:
		return
	var slot := w.first_free_slot()
	if slot == -1:
		return
	# ignora tier_cap propositalmente (5.1: valida C13–C15)
	var t := w.place_new_cat(slot, tier, 0)
	if _game().has_method("_spawn_cat_view"):
		_game()._spawn_cat_view(slot, t)

func _kill_boss() -> void:
	var w := _world()
	if w == null:
		return
	for e in w.enemies:
		if e.get("boss", false):
			w._damage_enemy(e, 9_999_999.0, {}, [])
			return

func _toggle_perf() -> void:
	perf_on = not perf_on
	overlay.visible = perf_on

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F3:
		panel.visible = not panel.visible

func _process(_delta: float) -> void:
	if not perf_on:
		return
	overlay.text = "FPS %d | nodes %d | draw %d | mem %.0f MB" % [
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1.0e6,
	]
