extends Node
## tools/simulate harness: roda fases headless com bot simples e mede win-rate.
## Uso: godot --headless --path . res://tools/sim_runner.tscn -- --from 1 --to 5 --sim-avg

var _lo := 1
var _hi := 1

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var idx: int = args.find("--from")
	if idx >= 0:
		_lo = int(args[idx + 1])
	idx = args.find("--to")
	if idx >= 0:
		_hi = int(args[idx + 1])
	var wins := 0
	var total := 0
	for lvl in range(_lo, _hi + 1):
		var result: Dictionary = await _run_level(lvl)
		total += 1
		if result["win"]:
			wins += 1
		print("[sim] fase %d: %s stars=%d moedas_ganhas=%d tempo=%.0fs" % [
			lvl, "WIN" if result["win"] else "LOSE", result["stars"],
			result["earned"], result["time"]])
	print("[sim] win-rate %d-%d: %d/%d (%.0f%%)" % [
		_lo, _hi, wins, total, 100.0 * wins / maxf(total, 1)])
	get_tree().quit(0 if wins * 100 >= total * 50 else 2)

func _run_level(lvl: int) -> Dictionary:
	GameManager.current_level = lvl
	GameManager.current_mode = LevelData.Mode.MERGE
	GameManager.state = GameManager.State.PLAYING
	var game := (load("res://scenes/game/merge_game.tscn") as PackedScene).instantiate() as MergeGame
	add_child(game)
	var prev_currency := GameManager.currency
	var earned := 0
	var t := 0.0
	var step := 1.0 / 30.0
	var last_log := -1.0
	while GameManager.state == GameManager.State.PLAYING and t < 360.0:
		_smart_buy(game)
		if t - last_log >= 15.0:
			last_log = t
			var en := get_tree().get_nodes_in_group(&"enemies")
			var epos := ""
			if not en.is_empty():
				epos = str((en[0] as Node2D).global_position)
			var tiers := [0, 0, 0]
			for i in SlotGrid.COLS * SlotGrid.ROWS:
				var c: CatTower = game._grid.get_at(i)
				if c:
					tiers[c.tier - 1] += 1
			print("[sim] t=%.0f wave=%d vivos=%d(grupo=%d) moedas=%d muro=%.0f/%.0f gatos=%s e0=%s" % [
				t, game._waves.current_wave(), game._waves.alive_count(), en.size(),
				GameManager.currency, game._wall.health.hp, game._wall.health.max_hp,
				tiers, epos])
		_merge_any(game)
		if game._wall.health.ratio() < 0.7:
			game.repair_wall()
		for i in game.ability_list().size():
			game.use_ability(i)
		for i in 2:
			await get_tree().physics_frame
			t += step
		var delta := GameManager.currency - prev_currency
		if delta > 0:
			earned += delta
		prev_currency = GameManager.currency
	var result := {
		"win": GameManager.last_victory,
		"stars": GameManager.last_stars,
		"earned": earned,
		"time": t,
	}
	remove_child(game)
	game.queue_free()
	await get_tree().process_frame
	return result

## Bot de "habilidade média": prefere comprar tipo igual ao já possuído (força merges).
func _smart_buy(game: MergeGame) -> void:
	var counts: Dictionary = {}
	for i in SlotGrid.COLS * SlotGrid.ROWS:
		var c: CatTower = game._grid.get_at(i)
		if c:
			var k := int(c.data.id.trim_prefix("cat_").to_int())
			counts[k] = int(counts.get(k, 0)) + (1 if c.tier < CatData.MAX_TIER else 0)
	var best := -1
	var best_n := 0
	for k in counts.keys():
		if counts[k] > best_n:
			best = int(k)
			best_n = int(counts[k])
	if best > 0:
		game.buy_cat_of_type(best - 1)
	else:
		game.buy_cat_of_type(randi() % maxi(1, game.level.cat_pool_size))

func _count_cats(game: MergeGame) -> int:
	var n := 0
	for i in SlotGrid.COLS * SlotGrid.ROWS:
		if game._grid.get_at(i) != null:
			n += 1
	return n

func _merge_any(game: MergeGame) -> void:
	var grid: SlotGrid = game._grid
	for i in SlotGrid.COLS * SlotGrid.ROWS:
		for j in SlotGrid.COLS * SlotGrid.ROWS:
			if i != j and grid.try_merge(i, j) >= 0:
				return
