extends Node
## Debug TD run com log por segundo.
func _ready() -> void:
	GameManager.current_level = 1
	GameManager.current_mode = LevelData.Mode.TOWER_DEFENSE
	GameManager.state = GameManager.State.PLAYING
	var game := (load("res://scenes/game/td_game.tscn") as PackedScene).instantiate() as TdGame
	add_child(game)
	game.level.hp_multiplier = 0.05
	game.level.speed_multiplier = 6.0
	var t := 0.0
	while GameManager.state == GameManager.State.PLAYING and t < 240.0:
		game.buy_cat()
		for cy in range(1, 7):
			for cx in range(1, 12):
				var cell := Vector2i(cx, cy)
				if game._placement_mode and game._placement.is_free(cell):
					game._placement_mode = true
					var ev := InputEventScreenTouch.new()
					ev.pressed = true
					ev.position = game.get_canvas_transform() * Vector2(cx * 96 + 48, cy * 96 + 48)
					game._input(ev)
		await get_tree().physics_frame
		await get_tree().physics_frame
		t += 1.0 / 30.0
		if int(t) % 10 == 0 and absf(t - int(t)) < 0.02:
			print("[td] t=%.0f wave=%d vivos=%d moedas=%d lives=%d" % [
				t, game._waves.current_wave(), game._waves.alive_count(),
				GameManager.currency, game._lives])
	print("[td] fim: state=%s vivos=%d" % [GameManager.state, game._waves.alive_count()])
	get_tree().quit()
