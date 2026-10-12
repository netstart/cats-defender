extends Node
## GameState — máquina de estados explícita em dois níveis (M17).
## Autoload: GameState

enum AppState {
	SPLASH, MENU, LEVEL_SELECT, SHOP, UPGRADE, ADDON, SETTINGS, CREDITS,
	LOADING, PLAYING, PAUSED, WIN, LOSE,
}

enum PlaySub { NONE, PREP, WAVE_ACTIVE, WAVE_CLEAR, BOSS, VICTORY, DEFEAT }

const APP_TRANSITIONS := {
	AppState.SPLASH: [AppState.MENU],
	AppState.MENU: [AppState.LEVEL_SELECT, AppState.SETTINGS, AppState.SHOP, AppState.CREDITS],
	AppState.LEVEL_SELECT: [AppState.MENU, AppState.LOADING, AppState.UPGRADE, AppState.ADDON],
	AppState.SHOP: [AppState.MENU, AppState.LEVEL_SELECT],
	AppState.UPGRADE: [AppState.MENU, AppState.LEVEL_SELECT],
	AppState.ADDON: [AppState.MENU, AppState.LEVEL_SELECT],
	AppState.SETTINGS: [AppState.MENU, AppState.CREDITS, AppState.PAUSED],
	AppState.CREDITS: [AppState.MENU, AppState.SETTINGS],
	AppState.LOADING: [AppState.PLAYING],
	AppState.PLAYING: [AppState.PAUSED, AppState.WIN, AppState.LOSE, AppState.LEVEL_SELECT],
	AppState.PAUSED: [AppState.PLAYING, AppState.SETTINGS, AppState.LEVEL_SELECT, AppState.MENU],
	AppState.WIN: [AppState.LEVEL_SELECT, AppState.PLAYING],
	AppState.LOSE: [AppState.LEVEL_SELECT, AppState.PLAYING],
}

const PLAY_TRANSITIONS := {
	PlaySub.NONE: [PlaySub.PREP],
	PlaySub.PREP: [PlaySub.WAVE_ACTIVE, PlaySub.BOSS, PlaySub.NONE],
	PlaySub.WAVE_ACTIVE: [PlaySub.WAVE_CLEAR, PlaySub.DEFEAT, PlaySub.NONE],
	PlaySub.WAVE_CLEAR: [PlaySub.PREP, PlaySub.BOSS, PlaySub.WAVE_ACTIVE, PlaySub.DEFEAT, PlaySub.NONE],
	PlaySub.BOSS: [PlaySub.VICTORY, PlaySub.DEFEAT],
	PlaySub.VICTORY: [PlaySub.NONE],
	PlaySub.DEFEAT: [PlaySub.NONE],
}

var app_state: AppState = AppState.SPLASH
var play_sub: PlaySub = PlaySub.NONE
var current_stage_id: String = ""

func goto_app(s: AppState) -> bool:
	var allowed: Array = APP_TRANSITIONS.get(app_state, [])
	if s not in allowed:
		if OS.is_debug_build():
			print("GameState: transição inválida %s -> %s (rejeitada)" % [AppState.keys()[app_state], AppState.keys()[s]])
		return false
	var from := app_state
	app_state = s
	EventBus.state_changed.emit(from, s)
	return true

func goto_play(s: PlaySub) -> bool:
	var allowed: Array = PLAY_TRANSITIONS.get(play_sub, [])
	if s not in allowed:
		if OS.is_debug_build():
			print("GameState: sub-estado inválido %s -> %s (rejeitado)" % [PlaySub.keys()[play_sub], PlaySub.keys()[s]])
		return false
	play_sub = s
	return true

func reset_play() -> void:
	play_sub = PlaySub.NONE
