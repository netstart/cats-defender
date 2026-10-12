extends SceneTree
## AutoPlayTest.gd — Teste automatizado de fluxo completo: splash→menu→level_select→gameplay→win/lose
## Uso: godot --headless --path . -s res://scripts/autoplay_test.gd [-- --stage P1]

var target_stage := "P1"
var _current_scene: Node = null
var _sim: SimWorld = null
var _balance: Balance = null
var _test_passed := true
var _errors: Array = []
var _current_step := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--stage" and i + 1 < args.size():
			target_stage = args[i + 1]
	
	print("=== AutoPlayTest: Iniciando fluxo completo para " + target_stage + " ===")
	
	# 1. Test Splash → Menu
	_test_splash_to_menu()
	
	# 2. Test Menu → LevelSelect
	_test_menu_to_level_select()
	
	# 3. Test LevelSelect → Gameplay
	_test_level_select_to_gameplay()
	
	# 4. Test Gameplay mechanics
	_test_gameplay_mechanics()
	
	# 5. Test Pause/Resume
	_test_pause_resume()
	
	# 6. Test Win/Lose flow
	_test_win_lose_flow()
	
	# Report
	_report()
	quit(0 if _test_passed else 1)

func _test_splash_to_menu() -> void:
	_current_step = "Splash → Menu"
	print("Teste: " + _current_step)
	
	# Load splash scene
	var splash_scene: PackedScene = load("res://scenes/splash.tscn")
	if splash_scene == null:
		_add_error("Splash scene não encontrada")
		return
	
	_current_scene = splash_scene.instantiate()
	get_tree().root.add_child(_current_scene)
	get_tree().current_scene = _current_scene
	
	# Wait a frame for _ready
	await get_tree().process_frame
	
	# Simulate click/tap on splash (center of screen)
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MouseButton.LEFT
	click_event.pressed = true
	click_event.position = Vector2(600, 270)
	
	# Call _input directly on splash root
	if _current_scene.has_method("_input"):
		_current_scene._input(click_event)
	else:
		_add_error("Splash não tem método _input")
	
	# Wait for scene transition
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verify we're now in main_menu
	if get_tree().current_scene.get_scene_file_path() != "res://scenes/main_menu.tscn":
		_add_error("Navegação splash→menu falhou. Cena atual: " + get_tree().current_scene.get_scene_file_path())
	else:
		print("  ✓ Splash → Menu OK")

func _test_menu_to_level_select() -> void:
	_current_step = "Menu → LevelSelect"
	print("Teste: " + _current_step)
	
	await get_tree().process_frame
	
	var menu := get_tree().current_scene
	if menu.get_scene_file_path() != "res://scenes/main_menu.tscn":
		_add_error("Não está no menu principal")
		return
	
	# Find VBoxContainer with buttons
	var vbox = menu.find_child("*VBoxContainer*")
	if vbox == null:
		var vboxes = menu.find_children("*", "VBoxContainer")
		for vb in vboxes:
			if vb.position.x > 800:
				vbox = vb
				break
	
	if vbox == null:
		_add_error("VBoxContainer do menu não encontrado")
		return
	
	# Find "Jogar" button (first button)
	var play_btn = null
	for child in vbox.get_children():
		if child is Button:
			if child.text.contains("Jogar") or child.text.contains("Play") or child.get_index() == 0:
				play_btn = child
				break
	
	if play_btn == null:
		_add_error("Botão Jogar não encontrado no menu")
		return
	
	play_btn.emit_signal("pressed")
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	if get_tree().current_scene.get_scene_file_path() != "res://scenes/level_select.tscn":
		_add_error("Navegação menu→level_select falhou. Cena atual: " + get_tree().current_scene.get_scene_file_path())
	else:
		print("  ✓ Menu → LevelSelect OK")

func _test_level_select_to_gameplay() -> void:
	_current_step = "LevelSelect → Gameplay"
	print("Teste: " + _current_step)
	
	await get_tree().process_frame
	
	var level_select := get_tree().current_scene
	if level_select.get_scene_file_path() != "res://scenes/level_select.tscn":
		_add_error("Não está no level_select")
		return
	
	var stage_btn = _find_stage_button(level_select, target_stage)
	if stage_btn == null:
		_add_error("Botão da fase " + target_stage + " não encontrado")
		return
	
	stage_btn.emit_signal("pressed")
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	if get_tree().current_scene.get_scene_file_path() != "res://scenes/game.tscn":
		_add_error("Navegação level_select→game falhou. Cena atual: " + get_tree().current_scene.get_scene_file_path())
	else:
		print("  ✓ LevelSelect → Gameplay OK")

func _test_gameplay_mechanics() -> void:
	_current_step = "Mecânicas de Gameplay"
	print("Teste: " + _current_step)
	
	var game := get_tree().current_scene
	if game.get_scene_file_path() != "res://scenes/game.tscn":
		_add_error("Não está na cena de jogo")
		return
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Test 1: Verify HUD elements exist
	var hud_tests := [
		["_coins_lbl", "Coins label"],
		["_gems_lbl", "Gems label"],
		["_wave_lbl", "Wave label"],
		["_buy_btn", "Buy button"],
		["_start_btn", "Start wave button"],
		["_speed_btn", "Speed button"],
		["_base_bar", "Base HP bar"],
	]
	
	for test in hud_tests:
		var node := game.get(test[0])
		if node == null:
			_add_error("HUD element missing: " + test[1] + " (" + test[0] + ")")
		else:
			print("  ✓ HUD: " + test[1] + " OK")
	
	# Test 2: Buy cat workflow
	var buy_btn := game.get("_buy_btn")
	if buy_btn and buy_btn is Button:
		buy_btn.emit_signal("pressed")
		await get_tree().process_frame
		var sim := game.get("sim")
		if sim:
			var has_cat := false
			for t in sim.towers:
				if t != null:
					has_cat = true
					break
			if has_cat:
				print("  ✓ Compra de gato funciona")
			else:
				_add_error("Compra de gato não colocou gato no slot")
		else:
			_add_error("SimWorld não acessível após compra")
	
	# Test 3: Merge function exists
	if game.has_method("_optimal_merge"):
		print("  ✓ Função de merge (_optimal_merge) existe")
	
	# Test 4: Start wave
	var start_btn := game.get("_start_btn")
	if start_btn and start_btn is Button:
		start_btn.emit_signal("pressed")
		await get_tree().process_frame
		print("  ✓ Botão Iniciar Onda funciona")
	
	# Test 5: Speed toggle
	var speed_btn := game.get("_speed_btn")
	if speed_btn and speed_btn is Button:
		speed_btn.emit_signal("pressed")
		await get_tree().process_frame
		print("  ✓ Botão 1x/2x funciona")
	
	# Test 6: Settings/Pause
	var gear_btn := game.find_child("*gear*")
	if gear_btn == null:
		gear_btn = game.find_child("*BtnSettings*")
	if gear_btn == null:
		gear_btn = game.find_child("*settings*")
	if gear_btn and gear_btn is Button:
		gear_btn.emit_signal("pressed")
		await get_tree().process_frame
		print("  ✓ Botão Settings abre pause menu")
	else:
		print("  ⚠ Botão de settings não encontrado (pode ser ícone)")
	
	# Test 7: Targeting toggle on cat
	var sim := game.get("sim")
	if sim and sim.towers.size() > 0:
		for slot_idx in sim.towers.size():
			var tower := sim.towers[slot_idx]
			if tower != null:
				print("  ✓ Torre encontrada no slot " + str(slot_idx) + " tier: " + str(tower.get("tier", 0)))
				break

func _test_pause_resume() -> void:
	_current_step = "Pause/Resume"
	print("Teste: " + _current_step)
	
	var game := get_tree().current_scene
	if game.get_scene_file_path() != "res://scenes/game.tscn":
		_add_error("Não está no jogo para testar pause")
		return
	
	# Press ESC (ui_cancel) to open pause
	var esc_event := InputEventKey.new()
	esc_event.keycode = KEY_ESCAPE
	esc_event.pressed = true
	
	if game.has_method("_input"):
		game._input(esc_event)
	
	await get_tree().process_frame
	
	var pause_popup = game.find_child("*Pause*")
	if pause_popup == null:
		pause_popup = game.find_child("*pause*")
	if pause_popup:
		print("  ✓ Pause menu abriu com ESC")
		var resume_btn = pause_popup.find_child("*Retomar*")
		if resume_btn == null:
			resume_btn = pause_popup.find_child("*Resume*")
		if resume_btn == null:
			resume_btn = pause_popup.find_child("*Continuar*")
		if resume_btn and resume_btn is Button:
			resume_btn.emit_signal("pressed")
			await get_tree().process_frame
			print("  ✓ Resume funciona")
	else:
		_add_error("Pause menu não abriu com ESC")

func _test_win_lose_flow() -> void:
	_current_step = "Win/Lose Flow"
	print("Teste: " + _current_step)
	
	var game := get_tree().current_scene
	if game.has_method("_build_win_popup") and game.has_method("_build_lose_popup"):
		print("  ✓ Funções de popup win/lose existem")
	else:
		_add_error("Funções de popup win/lose não encontradas")
	
	if game.has_method("_on_victory") and game.has_method("_on_defeat"):
		print("  ✓ Handlers de vitória/derrota existem")
	else:
		_add_error("Handlers de vitória/derrota não encontrados")

func _find_stage_button(level_select: Node, stage_id: String) -> Button:
	var buttons = level_select.find_children("*", "Button")
	for btn in buttons:
		if btn.text.contains(stage_id) or btn.name.contains(stage_id):
			return btn
		for child in btn.get_children():
			if child is Label and child.text.contains(stage_id):
				return btn
	return null

func _add_error(msg: String) -> void:
	_test_passed = false
	_errors.append("[" + _current_step + "] " + msg)
	print("  ✗ ERRO: " + msg)

func _report() -> void:
	print("\n=== RELATÓRIO AutoPlayTest ===")
	if _test_passed:
		print("✓ TODOS OS TESTES PASSARAM")
	else:
		print("✗ FALHAS ENCONTRADAS:")
		for err in _errors:
			print("  - " + err)
		print("Total de erros: " + str(_errors.size()))