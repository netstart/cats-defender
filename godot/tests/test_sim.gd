extends RefCounted
class_name TestSim
## Testes unitários e de propriedade do núcleo de simulação (seções 3, 5, 6).

static func run() -> void:
	Ut.ok(Balance.new() != null, "Balance carrega")
	_test_merge_math()
	_test_merge_rules()
	_test_tier_cap()
	_test_economy_no_arbitrage()
	_test_sell_and_undo()
	_test_determinism()
	_test_siege_limits()
	_test_slow_and_min_speed()
	_test_boss_enrage()
	_test_swept_hit()
	_test_stars_independent_of_speed()
	_test_wave_flow_victory_and_defeat()
	_test_save_roundtrip()
	_test_buy_cost_growth()

static func _world(seed_ := 42) -> SimWorld:
	var b := Balance.new()
	var w := SimWorld.new(b, seed_)
	var stage := StageDatabase.get_stage("P1")
	w.setup(stage, {"buy_level": 1, "extra_slots": 0, "cat_upgrades": {}, "unlocked_addons": []})
	return w

# [M01] matemática do merge: teto = nº de slots; 2^(L-1) compras
static func _test_merge_math() -> void:
	var w := _world()
	# com 12 slots, o máximo teórico por contagem de slots é 12
	w.run_coins = 100000
	var max_tier_seen := 0
	while true:
		var full := true
		for i in w.slot_count:
			if w.towers[i] == null:
				full = false
		var placed := 0
		if not full:
			w.run_coins += 1000
			var t := w.buy_cat()
			if t < 0:
				placed = -1
			else:
				var s := w.first_free_slot()
				w.place_new_cat(s, t, w.balance.buy_cost(w.purchases))
				placed = 1
		if placed == -1:
			break
		# tenta merges em cadeia
		var merged_any := true
		while merged_any:
			merged_any = false
			for tier in range(1, 16):
				var slots_with := []
				for i in w.slot_count:
					if w.towers[i] != null and int(w.towers[i].get("tier", 0)) == tier:
						slots_with.append(i)
				while slots_with.size() >= 2:
					var r := w.move_cat(slots_with[0], slots_with[1])
					if r == "merged":
						slots_with.remove_at(0)
						merged_any = true
					else:
						break
			if full and placed == -1:
				break
		if full:
			var all_full := true
			for i in w.slot_count:
				if w.towers[i] == null:
					all_full = false
			for i in w.slot_count:
				if w.towers[i] != null:
					max_tier_seen = maxi(max_tier_seen, int(w.towers[i]["tier"]))
			break
	Ut.le(max_tier_seen, 12, "teto matemático: tier máximo <= nº de slots (12)")

# regras de borda 3.2: mesmo nível -> merge; diferente -> swap; cap impede
static func _test_merge_rules() -> void:
	var w := _world()
	w.place_new_cat(0, 1, 10)
	w.place_new_cat(1, 1, 10)
	Ut.eq(w.move_cat(0, 1), "merged", "mesmo nível -> merge")
	Ut.eq(int(w.towers[1]["tier"]), 2, "merge produz tier 2")
	Ut.ok(w.towers[0] == null, "slot origem vazio após merge")
	w.place_new_cat(0, 1, 10)
	Ut.eq(w.move_cat(0, 1), "swapped", "nível diferente -> swap")
	w.towers[0]["tier"] = w.tier_cap
	w.towers[1]["tier"] = w.tier_cap
	Ut.eq(w.move_cat(0, 1), "swapped", "tier_cap: não mescla (troca)")
	Ut.eq(w.move_cat(20, 99), "invalid", "slots fora do range -> inválido")

static func _test_tier_cap() -> void:
	var w := _world()
	w.run_coins = 1_000_000
	for i in 12:
		var tier := w.buy_cat()
		w.place_new_cat(w.first_free_slot(), tier, 0)
	# compra no nível de compra (1) — cap não impede compra, mas impede resultado acima do cap
	Ut.le(int(w.tier_cap), 8, "tier_cap P1 = 8")
	Ut.le(int(w.balance.max_tier()), 15, "cadeia implementada até 15")

static func _test_economy_no_arbitrage() -> void:
	var w := _world()
	w.place_new_cat(0, 1, 20)
	var refund := w.sell_cat(0)
	Ut.ok(refund < 20, "refund < 100% do custo da unidade")
	# comprar 2 -> mesclar -> vender nunca devolve mais que o gasto total
	w.run_coins = 1000
	var c1 := w.balance.buy_cost(w.purchases)
	var t1 := w.buy_cat()
	var s1 := w.first_free_slot()
	w.place_new_cat(s1, t1, c1)
	var c2 := w.balance.buy_cost(w.purchases)
	var t2 := w.buy_cat()
	var s2 := w.first_free_slot()
	w.place_new_cat(s2, t2, c2)
	var spent := c1 + c2
	if t1 == t2:
		w.move_cat(s1, s2)
	var ref := w.sell_cat(s2)
	Ut.le(ref, spent, "comprar->mesclar->vender nunca lucra (refund <= gasto)")

static func _test_sell_and_undo() -> void:
	var w := _world()
	w.place_new_cat(0, 2, 80)
	var refund := w.sell_cat(0)
	Ut.gt(refund, 0, "venda devolve moedas")
	Ut.ok(w.undo_sell(), "desfazer funciona dentro da janela")
	Ut.eq(int(w.towers[0]["tier"]), 2, "torre restaurada")

static func _test_determinism() -> void:
	var h1 := _run_battle(1234, 60 * 20)
	var h2 := _run_battle(1234, 60 * 20)
	var h3 := _run_battle(999, 60 * 20)
	Ut.eq(h1, h2, "mesma seed -> mesmo hash (determinismo)")
	Ut.ne(h1, h3, "seeds diferentes -> resultado diferente")

static func _run_battle(seed_: int, ticks: int) -> int:
	var w := _world(seed_)
	w.run_coins = 500
	w.tier_cap = 4
	# estratégia simples e determinística
	var buys := 0
	for t in ticks:
		if t % 120 == 0 and w.first_free_slot() != -1 and buys < 8:
			var tier := w.buy_cat()
			if tier > 0:
				w.place_new_cat(w.first_free_slot(), tier, 0)
				buys += 1
		# merge periódico
		if t % 300 == 0:
			for i in w.slot_count - 1:
				if w.towers[i] != null and w.towers[i + 1] != null and int(w.towers[i]["tier"]) == int(w.towers[i + 1]["tier"]):
					w.move_cat(i, i + 1)
					break
		w.tick()
	return w.state_hash()

static func _test_siege_limits() -> void:
	var w := _world()
	w.base_hp = 100000
	# 10 tanques de cerco chegam à base
	for i in 10:
		var def: Dictionary = w.balance.enemies["Enemy Reg 5"]
		w.enemies.append({
			"id": w.next_id + i, "type": "Enemy Reg 5", "progress": 1.0, "hp": 99999.0,
			"speed": 0.0, "state": "siege", "slow_until": -1.0, "slow_factor": 1.0,
			"alive": true, "enraged": false, "role": "siege",
			"siege_dps": float(def["siege_dps"]), "reward": 5, "boss": false,
		})
	w.next_id += 10
	var hp0: float = w.base_hp
	for i in 60:
		w.tick()
	var dps := (hp0 - w.base_hp) / (60.0 / 60.0)
	Ut.le(dps, w.balance.getf("siege_dps_cap", 30.0) + 0.01, "DPS de cerco <= teto")

static func _test_slow_and_min_speed() -> void:
	var w := _world()
	w._apply_slow({"slow_until": -1.0, "slow_factor": 1.0, "type": "Enemy Reg 1"}, 0.55)
	var e := {"type": "Enemy Reg 1", "slow_until": w.time + 1.5, "slow_factor": 0.55, "speed": 100.0, "progress": 0.0, "alive": true, "state": "walk", "enraged": false, "hp": 10.0, "max_hp": 10.0, "reward": 1, "boss": false, "id": 99, "siege_dps": 0.0, "role": "runner"}
	w.enemies.append(e)
	var p0: float = e["progress"]
	for i in 60:
		w.tick()
	var moved := float(e["progress"]) - p0
	# velocidade efetiva >= min_speed_factor * base
	var min_moved := 0.3 * 100.0 / w.path.length * 1.0
	Ut.ge(moved, min_moved * 0.95, "piso de velocidade com slow (min_speed_factor)")

static func _test_boss_enrage() -> void:
	var w := _world()
	var def: Dictionary = w.balance.enemies["Enemy Boss 1"]
	var boss := {
		"id": 999, "type": "Enemy Boss 1", "progress": 0.5, "hp": float(def["hp"]), "max_hp": float(def["hp"]),
		"speed": float(def["speed"]), "state": "walk", "slow_until": -1.0, "slow_factor": 1.0,
		"alive": true, "enraged": false, "role": "boss", "siege_dps": 20.0, "reward": 60, "boss": true,
	}
	w.wave_index = w.total_waves - 1
	w.phase = SimWorld.S_BOSS
	w.enemies.append(boss)
	w._damage_enemy(boss, float(def["hp"]) * 0.6, {}, [])
	var ev := w.tick()
	Ut.ok(bool(w.enemies[0]["enraged"]), "chefe entra em enrage a 50% HP")

static func _test_swept_hit() -> void:
	# projétil rápido não atravessa alvo fino (M08)
	var w := _world()
	w.enemies.append({
		"id": 5, "type": "Enemy Reg 1", "progress": 0.5, "hp": 10.0, "max_hp": 10.0,
		"speed": 0.0, "state": "walk", "slow_until": -1.0, "slow_factor": 1.0,
		"alive": true, "enraged": false, "role": "runner", "siege_dps": 0.0, "reward": 1, "boss": false, "size": 0.01,
	})
	w.bullets.append({
		"id": 1, "kind": "straight", "p": 0.9, "speed": 5000.0, "target_id": 5,
		"dmg": 5.0, "slow": 0.0, "aoe": 0.0, "from_slot": 0, "gravity": 0.0, "vy": 0.0, "y": 0.0,
	})
	var events: Array = []
	for i in 12:
		events = w.tick()
	Ut.ok(not w.enemies[0]["alive"] or float(w.enemies[0]["hp"]) < 10.0, "swept test: hit registrado")
	Ut.ok(w.bullets.is_empty(), "projétil consumido no impacto")

static func _test_stars_independent_of_speed() -> void:
	# M23: resultado idêntico com 1x e 2x (o 2x só dobra ticks por frame)
	var run := func(speed: int) -> int:
		var w := _world(77)
		w.run_coins = 400
		for i in 4:
			var t := w.buy_cat()
			w.place_new_cat(w.first_free_slot(), t, 0)
		var ticks := 0
		while w.phase not in [SimWorld.S_WON, SimWorld.S_LOST] and ticks < 60 * 60 * 6:
			for k in speed:
				w.tick()
			ticks += 1
		return w.calc_stars() * 1000 + (1 if w.phase == SimWorld.S_WON else 0)
	Ut.eq(run.call(1), run.call(2), "estrelas/resultado iguais em 1x e 2x")

static func _test_wave_flow_victory_and_defeat() -> void:
	# vitória: defesa forte
	var w := _world(5)
	w.run_coins = 100000
	w.tier_cap = 10
	for i in 6:
		w.place_new_cat(i, 10, 0)
	var ticks := 0
	while w.phase not in [SimWorld.S_WON, SimWorld.S_LOST] and ticks < 60 * 60 * 10:
		w.tick()
		ticks += 1
	Ut.eq(w.phase, SimWorld.S_WON, "defesa forte vence a fase")
	Ut.ok(w.calc_stars() >= 1, "estrelas >= 1")
	# derrota: sem defesa
	var w2 := _world(5)
	ticks = 0
	while w2.phase not in [SimWorld.S_WON, SimWorld.S_LOST] and ticks < 60 * 60 * 10:
		w2.tick()
		ticks += 1
	Ut.eq(w2.phase, SimWorld.S_LOST, "sem defesa perde")

static func _test_save_roundtrip() -> void:
	var w := _world(314)
	w.place_new_cat(0, 3, 80)
	w.place_new_cat(4, 1, 10)
	for i in 200:
		w.tick()
	var snap := w.serialize()
	var w2 := _world(314)
	w2.deserialize(snap)
	var cont_a := 0
	var cont_b := 0
	for i in 500:
		w.tick()
		w2.tick()
	cont_a = w.state_hash()
	cont_b = w2.state_hash()
	Ut.eq(cont_a, cont_b, "round-trip de checkpoint restaura RNG e estado")

static func _test_buy_cost_growth() -> void:
	var b := Balance.new()
	var c0 := b.buy_cost(0)
	var c10 := b.buy_cost(10)
	Ut.eq(c0, 10, "custo inicial = buy_base_cost")
	Ut.gt(c10, c0, "custo cresce com compras (growth)")
