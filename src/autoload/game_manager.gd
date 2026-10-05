extends Node
## GameManager: máquina de estados global + economia da run em curso.

signal state_changed(new_state: State)

enum State { MAIN_MENU, LOADING, PLAYING, PAUSED, GAME_OVER }

var state: State = State.MAIN_MENU:
	set(value):
		if state == value:
			return
		state = value
		state_changed.emit(state)
		if value == State.PLAYING:
			EventBus.game_started.emit()

var currency: int = 0:
	set(value):
		currency = maxi(0, value)
		EventBus.currency_changed.emit(currency)

var current_level := 1
var current_mode: LevelData.Mode = LevelData.Mode.MERGE
var score := 0:
	set(value):
		score = value
		EventBus.score_changed.emit(score)

var last_victory := false
var last_stars := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func add_currency(amount: int) -> void:
	currency += amount

func try_spend(amount: int) -> bool:
	if currency < amount:
		return false
	currency -= amount
	return true

func start_game() -> void:
	state = State.PLAYING

func pause_game() -> void:
	state = State.PAUSED
	get_tree().paused = true

func resume_game() -> void:
	state = State.PLAYING
	get_tree().paused = false

func end_game(victory: bool, stars: int = 0) -> void:
	state = State.GAME_OVER
	last_victory = victory
	last_stars = stars
	EventBus.game_over.emit(victory)
	EventBus.request_game_over_screen.emit()
