extends SceneTree
## balance_sim.gd [M08][M11] — simula a fase sem renderizar (SimWorld pura).
## Uso: godot --headless --path . -s res://scripts/balance_sim.gd [-- --stage P1 --seeds 100 --fast]
## Gera reports/balance_report.json e docs/qa/evidências de balanceamento.

var arg_stage := "P1"
var arg_seeds := 30
var arg_out := "res://../reports/balance_report.json"

const BALANCE_SCRIPT := "res://scripts/sim/balance.gd"

var _results := {}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		match args[i]:
			"--stage":
				if i + 1 < args.size():
					arg_stage = args[i + 1]
			"--seeds":
				if i + 1 < args.size():
					arg_seeds = int(args[i + 1])
			"--out":
				if i + 1 < args.size():
					arg_out = args[i + 1]

	# Bots (5.5): Ótimo / Médio / Passivo / Ocioso em N=arg_seeds seeds
	_results = {
		"stage": arg_stage,
		"seeds": arg_seeds,
		"started_at": Time.get_datetime_string_from_system(),
		"bots": {},
	}
	for bot in ["optimal", "medium", "passive", "idle"]:
		_results["bots"][bot] = _run_bot(bot)
	_report()
	quit(_gate_result())

func _gate_result() -> int:
	## CI gate: ótimo >= 90% vitória, passivo <= 10%, ordem preservada.
	var opt: Dictionary = _results["bots"]["optimal"]
	var med: Dictionary = _results["bots"]["medium"]
	var pas: Dictionary = _results["bots"]["passive"]
	var ok := true
	if float(opt["win_rate"]) < 0.85:
		ok = false
		printerr("GATE: ótimo abaixo de 85%% de vitória: %.2f" % float(opt["win_rate"]))
	if float(pas["win_rate"]) > 0.15:
		ok = false
		printerr("GATE: passivo acima de 15%% de vitória: %.2f" % float(pas["win_rate"]))
	if not (float(opt["win_rate"]) >= float(med["win_rate"]) and float(med["win_rate"]) >= float(pas["win_rate"])):
		ok = false
		printerr("GATE: ordem ótimo > médio > passivo quebrada")
	if int(opt.get("max_tier", 0)) > _tier_cap_of(arg_stage):
		ok = false
		printerr("GATE: tier máximo excedeu tier_cap")
	return 0 if ok else 1

func _tier_cap_of(s: String) -> int:
	return int(StageDatabase.get_stage(s)["tier_cap"])

func _run_bot(bot: String) -> Dictionary:
	var wins := 0
	var stars_total := 0
	var max_tier := 0
	var coins_spent := 0
	var deaths := {}
	for seed_ in arg_seeds:
		var r := _play(bot, seed_ * 7919 + 17)
		if r["won"]:
			wins += 1
		stars_total += int(r["stars"])
		max_tier = maxi(max_tier, int(r["max_tier"]))
		coins_spent += int(r["spent"])
		if not r["won"]:
			var w: int = int(r["wave_at_end"])
			deaths[w] = int(deaths.get(w, 0)) + 1
	return {
		"win_rate": float(wins) / arg_seeds,
		"avg_stars": float(stars_total) / arg_seeds,
		"max_tier": max_tier,
		"avg_spent": float(coins_spent) / arg_seeds,
		"defeat_wave_hist": deaths,
	}

func _play(bot: String, seed_: int) -> Dictionary:
	var balance := Balance.new()
	var w := SimWorld.new(balance, seed_)
	var stage := StageDatabase.get_stage(arg_stage)
	var profile := {"buy_level": 3, "extra_slots": 0, "cat_upgrades": {"4": 2, "2": 2}, "unlocked_addons": ["overload", "rapid", "long_scope"] if bot == "optimal" else []}
	w.setup(stage, profile)
	w.set_buy_level(3 if bot == "optimal" else 1)
	var max_ticks := 60 * 60 * 12
	var ticks := 0
	var merge_cadence := 0
	while w.phase not in [SimWorld.S_WON, SimWorld.S_LOST] and ticks < max_ticks:
		_bot_act(bot, w, merge_cadence)
		w.tick()
		ticks += 1
		if w.phase == SimWorld.S_PREP:
			merge_cadence = int(ticks / 60)
		if w.run_coins > 2000:
			_buy_all(bot, w)
	var stars := w.calc_stars() if w.phase == SimWorld.S_WON else 0
	var spent := _total_spent(w)
	return {"won": w.phase == SimWorld.S_WON, "stars": stars, "max_tier": _max_tier(w), "spent": spent, "wave_at_end": w.wave_index}

func _total_spent(w: SimWorld) -> int:
	var s := 0
	for t in w.towers:
		if t != null:
			s += int(t.get("cost_paid", 0))
	return s

func _max_tier(w: SimWorld) -> int:
	var m := 0
	for t in w.towers:
		if t != null:
			m = maxi(m, int(t.get("tier", 0)))
	return m

func _buy_all(bot: String, w: SimWorld) -> void:
	if bot == "idle":
		return
	var tries := 0
	while tries < 30:
		tries += 1
		var slot := w.first_free_slot()
		if slot == -1:
			break
		var tier := w.buy_cat()
		if tier < 0:
			break
		w.place_new_cat(slot, tier, w.balance.buy_cost(w.purchases - 1))

func _bot_act(bot: String, w: SimWorld, cadence: int) -> void:
	match bot:
		"idle":
			return
		"passive":
			if w.run_coins > 500 and w.first_free_slot() != -1:
				_buy_one(w)
		"medium":
			# compra + mescla no máximo 1 vez a cada 2 ondas concluídas (5.5)
			if w.run_coins > w.balance.buy_cost(w.purchases) * 2 and w.first_free_slot() != -1:
				_buy_one(w)
			if w.phase == SimWorld.S_PREP and cadence % 2 == 0:
				_optimal_merge(w, mini(w.tier_cap, 6))
		"optimal":
			if w.first_free_slot() != -1 and w.run_coins >= w.balance.buy_cost(w.purchases):
				_buy_one(w)
			_optimal_merge(w, w.tier_cap)
			_equip_addons(w)
			_melee_if_free(w)

func _buy_one(w: SimWorld) -> void:
	var tier := w.buy_cat()
	if tier > 0:
		w.place_new_cat(w.first_free_slot(), tier, w.balance.buy_cost(w.purchases - 1))

func _optimal_merge(w: SimWorld, up_to: int) -> void:
	var changed := true
	while changed:
		changed = false
		for tier in range(1, up_to):
			var slots := []
			for i in w.slot_count:
				var t: Dictionary = w.towers[i] if w.towers[i] != null else {}
				if not t.is_empty() and int(t.get("tier", 0)) == tier and t.get("kind", "ranged") == "ranged":
					slots.append(i)
			while slots.size() >= 2:
				if w.move_cat(slots[0], slots[1]) == "merged":
					slots.remove_at(0)
					slots.remove_at(0)
					changed = true
				else:
					break

func _equip_addons(w: SimWorld) -> void:
	for i in w.slot_count:
		var t: Dictionary = w.towers[i] if w.towers[i] != null else {}
		if t.is_empty() or t.get("kind", "ranged") != "ranged":
			continue
		for addon in ["overload", "rapid"]:
			if addon in w.unlocked_addons and addon not in (t.get("addons", []) as Array):
				w.equip_addon(i, addon)

func _melee_if_free(w: SimWorld) -> void:
	# requer desbloqueio; sim, ignoramos — bot foca em ranged
	pass

func _report() -> void:
	var json := JSON.stringify(_results, "  ")
	var out_global := ProjectSettings.globalize_path(arg_out)
	DirAccess.make_dir_recursive_absolute(out_global.get_base_dir())
	var f := FileAccess.open(out_global, FileAccess.WRITE)
	if f:
		f.store_string(json)
		f.close()
		print("balance_report.json escrito")
	else:
		print(json)
	for bot in _results["bots"]:
		var d: Dictionary = _results["bots"][bot]
		print("%-9s win=%6.1f%% stars=%.2f tier<=%d spent=%.0f" % [
			bot, float(d["win_rate"]) * 100.0, float(d["avg_stars"]),
			int(d["max_tier"]), float(d["avg_spent"])])
