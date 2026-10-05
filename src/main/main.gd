class_name Main
extends Node
## Raiz do jogo: roteador de telas (menu → seleção de fase → jogo → resultados).

const SCENE_MENU := "res://scenes/ui/menus/main_menu.tscn"
const SCENE_LEVEL_SELECT := "res://scenes/ui/menus/level_select.tscn"
const SCENE_MERGE_GAME := "res://scenes/game/merge_game.tscn"
const SCENE_TD_GAME := "res://scenes/game/td_game.tscn"
const SCENE_PAUSE := "res://scenes/ui/dialogs/pause_menu.tscn"
const SCENE_GAME_OVER := "res://scenes/ui/dialogs/game_over_screen.tscn"

var _current: Node

func _ready() -> void:
	var font := load("res://assets/fonts/LuckiestGuy-Regular.ttf") as FontFile
	if font:
		ThemeDB.fallback_font = font
	EventBus.request_game_over_screen.connect(_show_game_over)
	EventBus.request_pause_menu.connect(_on_pause_requested)
	AudioManager.play_music(&"menu")
	show_menu()

func _swap(scene_path: String, with_tip := false) -> void:
	await TransitionManager.fade_out(with_tip)
	if _current and _current.is_inside_tree():
		remove_child(_current)
		_current.queue_free()
	_current = load(scene_path).instantiate()
	add_child(_current)
	await TransitionManager.fade_in()

func show_menu() -> void:
	GameManager.state = GameManager.State.MAIN_MENU
	await _swap(SCENE_MENU)
	_current.play_requested.connect(func(mode: LevelData.Mode) -> void:
		show_level_select(mode))
	_current.settings_requested.connect(_show_settings)
	AudioManager.play_music(&"menu")

func _show_settings() -> void:
	var pause := (load(SCENE_PAUSE) as PackedScene).instantiate()
	add_child(pause)
	pause.resume_requested.connect(pause.queue_free)
	pause.quit_requested.connect(pause.queue_free)

func _show_game_over() -> void:
	var screen := (load(SCENE_GAME_OVER) as PackedScene).instantiate()
	screen.victory = GameManager.last_victory
	screen.stars = GameManager.last_stars
	add_child(screen)
	screen.retry_requested.connect(func() -> void:
		screen.queue_free()
		GameManager.resume_game()
		_on_level_picked(GameManager.current_mode, GameManager.current_level))
	screen.quit_requested.connect(func() -> void:
		screen.queue_free()
		GameManager.resume_game()
		show_menu())


func show_level_select(mode: LevelData.Mode) -> void:
	if not has_node(^"LevelSelectHolder"):
		var ls := (load(SCENE_LEVEL_SELECT) as PackedScene).instantiate()
		ls.setup(mode)
		ls.name = &"LevelSelectHolder"
		add_child(ls)
		ls.level_picked.connect(_on_level_picked)
		ls.back_requested.connect(show_menu)

func _on_level_picked(mode: LevelData.Mode, index: int) -> void:
	if has_node(^"LevelSelectHolder"):
		get_node(^"LevelSelectHolder").queue_free()
	GameManager.current_level = index
	GameManager.current_mode = mode
	GameManager.state = GameManager.State.LOADING
	var scene := SCENE_MERGE_GAME if mode == LevelData.Mode.MERGE else SCENE_TD_GAME
	await _swap(scene, true)
	GameManager.start_game()

func _on_level_completed(_stars: int) -> void:
	pass  # merge_game/td_game já tratam via game_over(true)

func _on_pause_requested() -> void:
	GameManager.pause_game()
	var pause := (load(SCENE_PAUSE) as PackedScene).instantiate()
	add_child(pause)
	pause.resume_requested.connect(func() -> void:
		pause.queue_free()
		GameManager.resume_game())
	pause.quit_requested.connect(func() -> void:
		pause.queue_free()
		GameManager.resume_game()
		show_menu())
