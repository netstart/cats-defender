extends RefCounted
class_name SimWorld
## Núcleo de simulação puro (M08): sem Node, tick fixo SIM_DT, RNG injetado,
## caminho 1D, hit-test analítico com swept test, cerco, slow, enrage, economia
## de partida, merge 2:1 com tier_cap. Serializável para checkpoint (M04).

const SIM_DT := 1.0 / 60.0
const MAX_TICKS_PER_FRAME := 4
const MAX_SLOTS := 16          # teto de slots (12 base + até 4 extras)
const MELEE_SLOTS := [16, 17]  # índices especiais para Guardian/Boxing (após MAX_SLOTS)
const BASE_BOARDS_SLOTS := 12

# Sub-estados de partida (sincronizados com GameState.PlaySub)
const S_PREP := "prep"
const S_WAVE := "wave"
const S_BOSS := "boss"
const S_WON := "won"
const S_LOST := "lost"

var rng: SimRng
var path: SimPath
var balance: Balance

# --- Configuração do stage (vem de StageDatabase) ---
var stage_id := "P1"
var tier_cap := 8
var slot_count := 12
var start_coins := 40
var base_max_hp := 100
var total_waves := 5
var boss_id := "Enemy Boss 1"
var waves: Array = []          # [{spawns: [{enemy,count,interval,delay}]}]
var hp_mult := 1.0

# --- Estado de runtime (mutável, serializável) ---
var run_coins := 0
var base_hp := 100.0
var purchases := 0
var wave_index := -1           # -1 = ainda na primeira PREP
var phase := S_PREP
var time := 0.0
var prep_timer := 0.0
var next_id := 1
var towers: Array = []         # slots 0..MAX: null ou tower dict
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var spills := []               # lixo de eventos deste tick (limpo por tick)
var boss_ref: Dictionary = {}
var leaks := 0                 # inimigos que alcançaram a base (para estrelas)
var early_starts := 0          # usos de "iniciar agora"
var kills := 0
var upgrades: Dictionary = {}   # tier -> upgrade level (permanente)
var unlocked_addons: Array = []
var melee_hp: Dictionary = {}   # slot -> hp restante (melee têm HP)
var _enemy_defs: Dictionary = {}

func _init(p_balance: Balance = null, seed_ := 1) -> void:
	balance = p_balance if p_balance else Balance.new()
	rng = SimRng.new(seed_)
	path = SimPath.new(balance.getf("path_length", 1000.0))
	towers.resize(MAX_SLOTS + 2)

func setup(p_stage: Dictionary, p_profile: Dictionary) -> void:
	stage_id = p_stage.get("id", "P1")
	tier_cap = int(p_stage.get("tier_cap", 8))
	start_coins = int(p_stage.get("start_coins", 40)) + rng.randi_range(0, 0)  # seed tocou rng? não — mantido zero var
	slot_count = mini(BASE_BOARDS_SLOTS + int(p_profile.get("extra_slots", 0)), MAX_SLOTS)
	if bool(p_stage.get("locked_slots", false)):
		slot_count = mini(slot_count, int(p_stage.get("slots_override", slot_count)))
	base_max_hp = int(p_stage.get("base_hp", 100))
	base_hp = float(base_max_hp)
	hp_mult = float(p_stage.get("mods", {}).get("hp_mult", 1.0))
	total_waves = int(p_stage.get("waves", []).size())
	boss_id = p_stage.get("boss", "Enemy Boss 1")
	waves = p_stage.get("waves", [])
	run_coins = start_coins
	upgrades = p_profile.get("cat_upgrades", {}).duplicate()
	unlocked_addons = p_profile.get("unlocked_addons", []).duplicate()
	_buy_level = int(p_profile.get("buy_level", 1))
	prep_timer = balance.getf("prep_time", 5.0)

# --------------------------- API de jogador ---------------------------

func buy_cat() -> int:
	## Compra gato no nível de compra atual. Devolve o tier ou -1 (falha).
	if first_free_slot() == -1:
		return -1
	var cost := balance.buy_cost(purchases)
	if run_coins < cost:
		return -1
	run_coins -= cost
	purchases += 1
	var tier := mini(int(profile_buy_level_cache()), tier_cap)
	return tier

var _buy_level := 1  # cache do nível de compra permanente

func profile_buy_level_cache() -> int:
	return _buy_level

func set_buy_level(l: int) -> void:
	_buy_level = maxi(1, l)

func first_free_slot() -> int:
	for i in slot_count:
		if towers[i] == null:
			return i
	return -1

func place_new_cat(slot: int, tier: int, cost_paid := 0) -> Dictionary:
	if slot < 0 or slot >= slot_count or towers[slot] != null:
		return towers[slot] if slot >= 0 and slot < MAX_SLOTS and towers[slot] != null else {}
	var t := {
		"id": next_id, "slot": slot, "tier": tier, "kind": "ranged",
		"cooldown": 0.0, "targeting": "first", "cost_paid": cost_paid,
		"addons": [],
	}
	next_id += 1
	towers[slot] = t
	return t

## move/swap/merge (regras de borda 3.2). Retorna "moved|swapped|merged|invalid".
func move_cat(from_slot: int, to_slot: int) -> String:
	if from_slot == to_slot:
		return "invalid"
	if from_slot < 0 or to_slot < 0 or from_slot >= MAX_SLOTS or to_slot >= slot_count:
		return "invalid"
	var a: Dictionary = towers[from_slot] if towers[from_slot] != null else {}
	if a.is_empty():
		return "invalid"
	var b: Dictionary = towers[to_slot] if towers[to_slot] != null else {}
	if b.is_empty():
		(towers as Array)[to_slot] = a
		a["slot"] = to_slot
		towers[from_slot] = null
		return "moved"
	if int(a["tier"]) == int(b["tier"]) and int(a["tier"]) < tier_cap and int(a["tier"]) < balance.max_tier():
		var new_tier: int = int(a["tier"]) + 1
		b["tier"] = new_tier
		b["cost_paid"] = int(b.get("cost_paid", 0)) + int(a.get("cost_paid", balance.cat_cost_value(int(a["tier"]))))
		b["cooldown"] = 0.0
		towers[from_slot] = null
		return "merged"
	# níveis diferentes (ou cap): troca de posição
	(towers as Array)[to_slot] = a
	a["slot"] = to_slot
	towers[from_slot] = b
	b["slot"] = from_slot
	return "swapped"

func sell_cat(slot: int) -> int:
	## Devolve refund ou 0. Guarda last_sold para desfazer (3 s na UI).
	if slot < 0 or slot >= MAX_SLOTS or towers[slot] == null:
		return 0
	var t: Dictionary = towers[slot]
	var refund_bonus := _addon_value(slot, "sell_bonus")
	var refund := balance.sell_refund(int(t["tier"]), int(t.get("cost_paid", 0)), refund_bonus)
	run_coins += refund
	last_sold = {"tower": t.duplicate(true), "refund": refund, "expires": time + 3.0}
	towers[slot] = null
	return refund

var last_sold: Dictionary = {}

func undo_sell() -> bool:
	if last_sold.is_empty() or time > float(last_sold.get("expires", 0.0)):
		return false
	var t: Dictionary = last_sold["tower"]
	if towers[int(t["slot"])] != null:
		return false
	towers[int(t["slot"])] = t
	run_coins -= int(last_sold["refund"])
	last_sold = {}
	return true

func cycle_targeting(slot: int) -> String:
	if slot < 0 or slot >= MAX_SLOTS or towers[slot] == null:
		return ""
	var modes := ["first", "last", "strongest", "closest"]
	var cur: String = towers[slot]["targeting"]
	var idx := (modes.find(cur) + 1) % modes.size()
	towers[slot]["targeting"] = modes[idx]
	return modes[idx]

func equip_addon(slot: int, addon_id: String) -> bool:
	## Compra in-run de addon já destravado (5.2/5.4).
	if slot < 0 or slot >= MAX_SLOTS or towers[slot] == null:
		return false
	if addon_id not in unlocked_addons:
		return false
	if not balance.addons.has(addon_id):
		return false
	var t: Dictionary = towers[slot]
	var slots_left := 2 - (t["addons"] as Array).size()
	if slots_left <= 0:
		return false
	var cost: int = int(balance.addons[addon_id]["run"])
	if run_coins < cost:
		return false
	run_coins -= cost
	t["addons"].append(addon_id)
	return true

func place_melee(kind: String) -> bool:
	## kind: "guardian" | "boxing". Requer desbloqueio permanente.
	var idx := 0 if kind == "guardian" else 1
	var slot: int = MELEE_SLOTS[idx]
	if towers.size() <= slot or towers[slot] != null:
		return false
	var cost := int(balance.getf("melee_cost_run", 30))
	if run_coins < cost:
		return false
	run_coins -= cost
	towers[slot] = {
		"id": next_id, "slot": slot, "tier": 1, "kind": kind,
		"cooldown": 0.0, "cost_paid": cost, "addons": [],
		"hp": balance.getf("melee_hp", 300.0), "position_p": path.melee_slots[idx],
	}
	next_id += 1
	return true

func start_wave_early() -> int:
	## Botão "iniciar agora" — bônus de coins e corte da espera (4).
	if phase != S_PREP:
		return 0
	var bonus := int(balance.getf("early_start_bonus", 15))
	run_coins += bonus
	early_starts += 1
	prep_timer = 0.0
	return bonus

# --------------------------- Simulação ---------------------------

func tick() -> Array:
	var events := []
	time += SIM_DT
	_enemy_defs = balance.enemies

	_update_waves(events)
	_move_enemies(events)
	_update_siege_damage(events)
	_towers_fire(events)
	_move_bullets(events)
	_update_status(events)

	return events

func _update_waves(events: Array) -> void:
	if phase in [S_WON, S_LOST]:
		return
	if phase == S_PREP:
		prep_timer -= SIM_DT
		if prep_timer > 0.0:
			return
		_next_wave(events)
	# spawn queue da onda ativa
	if _spawn_queue.size() > 0:
		_spawn_timer -= SIM_DT
		if _spawn_timer <= 0.0:
			var item: Dictionary = _spawn_queue.pop_front()
			_spawn_enemy(item["enemy"], item.get("hp_mult", 1.0), events)
			_spawn_timer = float(item["interval"])
	# fim da onda?
	if phase in [S_WAVE, S_BOSS] and _spawn_queue.is_empty() and _alive_enemies() == 0:
		events.append(SimEvents.ev(SimEvents.WAVE_CLEARED, {"wave": wave_index, "total": total_waves}))
		if wave_index >= total_waves - 1:
			_win(events)
		else:
			phase = S_PREP
			run_coins += int(balance.getf("wave_clear_bonus", 12))
			prep_timer = balance.getf("prep_time", 5.0)

var _spawn_queue: Array = []
var _spawn_timer := 0.0

func _next_wave(events: Array) -> void:
	wave_index += 1
	if wave_index >= total_waves:
		_win(events)
		return
	var wave: Dictionary = waves[wave_index]
	_spawn_queue = []
	var is_boss_wave: bool = bool(wave.get("is_boss", false))
	for s in wave.get("spawns", []):
		for i in int(s["count"]):
			_spawn_queue.append({
				"enemy": s["enemy"], "interval": float(s["interval"]),
				"delay": float(s.get("delay", 0.0)), "hp_mult": float(s.get("hp_mult", 1.0)) * hp_mult,
			})
	_spawn_timer = 0.0
	phase = S_BOSS if is_boss_wave else S_WAVE
	events.append(SimEvents.ev(SimEvents.WAVE_STARTED, {"wave": wave_index, "total": total_waves, "boss": is_boss_wave}))

func _spawn_enemy(enemy_id: String, hm: float, events: Array) -> void:
	var def: Dictionary = _enemy_defs.get(enemy_id, {})
	var is_boss := enemy_id == boss_id and (wave_index == total_waves - 1)
	var hp := float(def.get("hp", 50.0)) * hm
	var e := {
		"id": next_id, "type": enemy_id, "progress": 0.0, "hp": hp, "max_hp": hp,
		"speed": float(def.get("speed", 25.0)), "state": "walk",
		"slow_until": -1.0, "slow_factor": 1.0, "alive": true, "enraged": false,
		"role": def.get("role", "normal"), "siege_dps": float(def.get("siege_dps", 5.0)),
		"reward": int(def.get("reward", 5)), "boss": is_boss,
	}
	next_id += 1
	enemies.append(e)
	events.append(SimEvents.ev(SimEvents.ENEMY_SPAWNED, {"id": e["id"], "type": enemy_id, "boss": is_boss}))
	if is_boss:
		boss_ref = e
		events.append(SimEvents.ev(SimEvents.BOSS_SPAWNED, {"id": e["id"], "type": enemy_id}))

func _alive_enemies() -> int:
	var n := 0
	for e in enemies:
		if e["alive"]:
			n += 1
	return n

func _move_enemies(events: Array) -> void:
	var min_speed_factor := balance.getf("min_speed_factor", 0.3)
	var enrage_mult := balance.getf("enrage_speed", 1.5)
	var base_zone := 0.99  # progress >= base_zone: chega na base (siege)
	for e in enemies:
		if not e["alive"]:
			continue
		if e["state"] == "siege":
			continue
		if e["state"] == "queue":
			continue
		var speed: float = e["speed"]
		if e["enraged"]:
			speed *= enrage_mult
		# slow (3.5): fator com piso
		var sf: float = e["slow_factor"]
		if e["slow_until"] >= 0.0 and time > float(e["slow_until"]):
			sf = 1.0
			e["slow_factor"] = 1.0
		speed *= maxf(min_speed_factor, sf)
		e["progress"] = path.clamp_progress(float(e["progress"]) + speed / path.length * SIM_DT)
		if float(e["progress"]) >= base_zone:
			_enter_siege(e, events)
		# enrage do chefe a 50%
		if e["boss"] and not e["enraged"] and float(e["hp"]) <= 0.5 * float(e["max_hp"]):
			e["enraged"] = true
			e["speed"] = float(e["speed"]) * balance.getf("enrage_speed_boost", 1.25)
			events.append(SimEvents.ev(SimEvents.BOSS_ENRAGED, {"id": e["id"]}))
	_cleanup_dead()

func _enter_siege(e: Dictionary, events: Array) -> void:
	var siege_slots := int(balance.getf("siege_slots", 3))
	var busy := 0
	for o in enemies:
		if o["alive"] and o["state"] == "siege":
			busy += 1
	if busy >= siege_slots:
		# fila: fica parado perto da base até liberar slot
		e["state"] = "queue"
		e["progress"] = minf(float(e["progress"]), 0.97)
		return
	var was_queued: bool = e["state"] == "queue"
	e["state"] = "siege"
	e["progress"] = 1.0
	if not was_queued:
		leaks += 1
	events.append(SimEvents.ev(SimEvents.ENEMY_SIEGED, {"id": e["id"]}))

func _update_siege_damage(events: Array) -> void:
	# DPS de cerco AGREGADO com teto (3.5: siege_dps_cap no total, não por inimigo)
	var resist := _global_siege_resist()
	var total := 0.0
	for e in enemies:
		if e["alive"] and e["state"] == "siege":
			total += float(e.get("siege_dps", 5.0))
	total = minf(total, balance.getf("siege_dps_cap", 30.0)) * (1.0 - resist)
	if total <= 0.0:
		return
	base_hp -= total * SIM_DT
	hit_flash = time
	var fatal := base_hp <= 0.0
	if fatal:
		base_hp = 0
	events.append(SimEvents.ev(SimEvents.BASE_DAMAGED, {"hp": base_hp, "max": base_max_hp, "fatal": fatal}))
	if fatal:
		_lose(events)

func _global_siege_resist() -> float:
	# Guardian melee implantado -> 15% de resistência ao dano de cerco (5.4)
	var r := 0.0
	for slot in MELEE_SLOTS:
		if slot < towers.size() and towers[slot] != null and towers[slot].get("kind") == "guardian":
			r += balance.getf("guardian_siege_resist", 0.15)
	return minf(r, 0.45)

func _towers_fire(events: Array) -> void:
	if phase == S_LOST or phase == S_WON:
		return
	for slot in towers.size():
		var t: Dictionary = towers[slot] if towers[slot] != null else {}
		if t.is_empty():
			continue
		t["cooldown"] = float(t["cooldown"]) - SIM_DT
		if float(t["cooldown"]) > 0.0:
			continue
		var tgt := _pick_target(t)
		if tgt.is_empty():
			continue
		if t.get("kind", "ranged") == "ranged":
			_fire_bullet(t, tgt, events)
			t["cooldown"] = _cat_interval(slot, int(t["tier"]))
		else:
			_melee_strike(t, tgt, events)
			t["cooldown"] = balance.getf("melee_interval", 0.8)

func _addon_value(slot: int, effect: String) -> float:
	## Soma magnitude dos addons com esse efeito na torre do slot.
	var t: Dictionary = towers[slot] if slot >= 0 and slot < towers.size() and towers[slot] != null else {}
	if t.is_empty():
		return 0.0
	var total := 0.0
	for a in t.get("addons", []):
		var def: Dictionary = balance.addons.get(a, {})
		if def.get("effect") == effect:
			total += float(def["value"])
	return total

func _pick_target(t: Dictionary) -> Dictionary:
	var mode: String = t.get("targeting", "first")
	var best: Dictionary = {}
	var kind: String = t.get("kind", "ranged")
	for e in enemies:
		if not e["alive"] or e["state"] == "queue":
			# inimigos em fila ainda são alvos válidos (estão perto da base)
			if not (e["alive"] and e["state"] == "queue"):
				continue
		if not e["alive"]:
			continue
		if kind == "ranged":
			var range_p := cat_range_for(t)
			var reach := 1.0 - range_p
			if float(e["progress"]) < reach:
				continue
		else:
			var mp: float = float(t.get("position_p", 0.85))
			if absf(float(e["progress"]) - mp) > balance.getf("melee_range_p", 0.06):
				continue
		if best.is_empty():
			best = e
			continue
		match mode:
			"first":
				if float(e["progress"]) > float(best["progress"]):
					best = e
			"last":
				if float(e["progress"]) < float(best["progress"]):
					best = e
			"strongest":
				if float(e["hp"]) > float(best["hp"]):
					best = e
			"closest":
				if absf(1.0 - float(e["progress"])) < absf(1.0 - float(best["progress"])):
					best = e
	return best

func cat_range_for(t: Dictionary) -> float:
	var r := balance.cat_range_p(int(t["tier"]))
	r *= (1.0 + _addon_value(int(t["slot"]), "range_mult"))
	return clampf(r, 0.2, 1.0)

func _cat_interval(slot: int, tier: int) -> float:
	var iv := balance.cat_interval(tier)
	iv /= (1.0 + _addon_value(slot, "rate_mult"))
	return maxf(0.2, iv)

func cat_damage_for(slot: int) -> float:
	var t: Dictionary = towers[slot]
	var tier: int = int(t["tier"])
	var upg: int = int(upgrades.get(str(tier), 0))
	var dmg := balance.cat_damage(tier, upg)
	dmg *= (1.0 + _addon_value(slot, "dmg_mult"))
	return dmg

func _fire_bullet(t: Dictionary, tgt: Dictionary, events: Array) -> void:
	var tier: int = int(t["tier"])
	var kind := balance.cat_bullet_kind(tier)
	var b := {
		"id": next_id, "kind": kind, "p": 0.98, "speed": balance.getf("bullet_speed", 400.0) * (1.0 + _addon_value(int(t["slot"]), "bullet_speed")),
		"target_id": tgt["id"], "dmg": cat_damage_for(int(t["slot"])),
		"slow": 0.0, "aoe": 0.0, "from_slot": int(t["slot"]), "gravity": 0.0, "vy": 0.0, "y": 0.0,
	}
	if kind == "slow":
		b["slow"] = balance.getf("slow_factor", 0.55)
		b["speed"] *= 0.8
	elif kind == "grenade":
		b["aoe"] = balance.getf("grenade_aoe", 0.05)
		b["speed"] *= 0.65
		b["gravity"] = balance.getf("bullet_gravity", 600.0)
		b["dmg"] *= balance.getf("grenade_dmg_mult", 1.6)
	# addon frost aplica slow em qualquer projétil
	var frost := _addon_value(int(t["slot"]), "slow")
	if frost > 0.0:
		b["slow"] = maxf(float(b["slow"]), 1.0 - frost)
	next_id += 1
	bullets.append(b)
	events.append(SimEvents.ev(SimEvents.CAT_FIRED, {"slot": int(t["slot"]), "tier": tier}))
	events.append(SimEvents.ev(SimEvents.BULLET_FIRED, {"id": b["id"], "kind": kind, "p": b["p"], "target": tgt["id"]}))

func _melee_strike(t: Dictionary, tgt: Dictionary, events: Array) -> void:
	var dmg := balance.getf("melee_dmg", 35.0)
	_damage_enemy(tgt, dmg, t, events)
	events.append(SimEvents.ev(SimEvents.MELEE_HIT, {"slot": int(t["slot"]), "target": tgt["id"]}))

func _move_bullets(events: Array) -> void:
	var to_remove := []
	for i in bullets.size():
		var b: Dictionary = bullets[i]
		var prev_p: float = b["p"]
		# granadas sobem/caem (visual), posição 1D continua sendo p
		if float(b["gravity"]) > 0.0:
			b["vy"] = float(b["vy"]) - float(b["gravity"]) * SIM_DT
			b["y"] = float(b["y"]) + float(b["vy"]) * SIM_DT
		b["p"] = float(b["p"]) - float(b["speed"]) / path.length * SIM_DT
		var hit: Dictionary = {}
		for e in enemies:
			if not e["alive"]:
				continue
			if e["id"] == b["target_id"]:
				# swept test: projétil cruzou a posição do alvo neste tick?
				if float(e["progress"]) <= prev_p and float(e["progress"]) >= float(b["p"]):
					hit = e
				elif absf(float(e["progress"]) - float(b["p"])) <= float(e.get("size", 0.02)):
					hit = e
		if not hit.is_empty():
			_impact(b, hit, events)
			to_remove.append(i)
		elif float(b["p"]) <= -0.05:
			to_remove.append(i)
	for k in range(to_remove.size() - 1, -1, -1):
		bullets.remove_at(to_remove[k])

func _impact(b: Dictionary, tgt: Dictionary, events: Array) -> void:
	var dmg: float = b["dmg"]
	if float(b["aoe"]) > 0.0:
		# dano em área: todos num raio (fração do caminho) ao redor do alvo
		events.append(SimEvents.ev(SimEvents.EXPLOSION, {"p": tgt["progress"], "aoe": b["aoe"]}))
		for e in enemies:
			if e["alive"] and absf(float(e["progress"]) - float(tgt["progress"])) <= float(b["aoe"]):
				_damage_enemy(e, dmg, {}, events)
	else:
		_damage_enemy(tgt, dmg, {}, events)
		if float(b["slow"]) > 0.0 and tgt["alive"]:
			_apply_slow(tgt, float(b["slow"]))
	events.append(SimEvents.ev(SimEvents.BULLET_HIT, {"id": b["id"], "target": tgt["id"], "p": tgt["progress"]}))

func _apply_slow(e: Dictionary, factor: float) -> void:
	var resist := float(_enemy_defs.get(e["type"], {}).get("slow_resist", 0.0))
	var effective := lerpf(1.0, factor, 1.0 - resist)
	e["slow_factor"] = minf(float(e["slow_factor"]) if float(e["slow_until"]) > time else 1.0, effective)
	e["slow_until"] = time + balance.getf("slow_duration", 1.5)

func _damage_enemy(e: Dictionary, dmg: float, source: Dictionary, events: Array) -> void:
	if not e["alive"]:
		return
	e["hp"] = float(e["hp"]) - dmg
	if e["boss"]:
		boss_ref = e
	if float(e["hp"]) <= 0.0:
		_kill(e, events)
	else:
		# knockback leve (empurra contra o avanço, clampado no caminho)
		var kb: float = balance.getf("knockback", 0.004) * float(_enemy_defs.get(e["type"], {}).get("kb_resist", 1.0))
		e["progress"] = path.clamp_progress(float(e["progress"]) - kb)

func _kill(e: Dictionary, events: Array) -> void:
	e["alive"] = false
	e["state"] = "dead"
	kills += 1
	var reward: int = int(e["reward"]) + int(_kill_bonus())
	run_coins += reward
	events.append(SimEvents.ev(SimEvents.ENEMY_DIED, {"id": e["id"], "type": e["type"], "p": e["progress"], "reward": reward, "boss": e["boss"]}))
	events.append(SimEvents.ev(SimEvents.COIN_SPAWNED, {"p": e["progress"], "amount": reward}))
	if e["boss"]:
		_win(events)

func _kill_bonus() -> float:
	var bonus := 0.0
	for slot in towers.size():
		var t: Dictionary = towers[slot] if towers[slot] != null else {}
		if t.is_empty():
			continue
		for a in t.get("addons", []):
			var def: Dictionary = balance.addons.get(a, {})
			if def.get("effect") == "kill_coins":
				bonus += float(def["value"])
				return bonus   # aplica uma vez por kill
	return bonus

func _update_status(events: Array) -> void:
	# gens: caso especial de "queue" -> siege quando slot abre
	for e in enemies:
		if e["alive"] and e["state"] == "queue":
			var busy := 0
			for o in enemies:
				if o["alive"] and o["state"] == "siege":
					busy += 1
			if busy < int(balance.getf("siege_slots", 3)):
				e["state"] = "siege"
				e["progress"] = 1.0
				leaks += 1
				events.append(SimEvents.ev(SimEvents.ENEMY_SIEGED, {"id": e["id"]}))
	_cleanup_dead()

func _cleanup_dead() -> void:
	# remove mortos após 1.2 s (tempo da anim Dead acelerada)
	var keep: Array[Dictionary] = []
	for e in enemies:
		if e["alive"]:
			keep.append(e)
		elif time - float(e.get("died_at", time)) < 999.0 and not e.has("removed"):
			e["died_at"] = float(e.get("died_at", time))
			if time - float(e["died_at"]) <= 1.2:
				keep.append(e)
	enemies = keep

func _win(events: Array) -> void:
	if phase == S_WON:
		return
	phase = S_WON
	events.append(SimEvents.ev(SimEvents.STAGE_WON, {"stars": calc_stars()}))

func _lose(events: Array) -> void:
	if phase == S_LOST:
		return
	phase = S_LOST
	events.append(SimEvents.ev(SimEvents.STAGE_LOST, {}))

func calc_stars() -> int:
	## M23: estrelas = f(HP da base, eficiência) — nunca tempo de relógio.
	var hp_ratio := float(base_hp) / float(base_max_hp)
	var s1 := balance.getf("star1_hp", 0.0)
	var s2 := balance.getf("star2_hp", 0.5)
	var s3 := balance.getf("star3_hp", 0.85)
	if hp_ratio <= s1 or leaks > int(balance.getf("star_leak_limit", 3)):
		return 1
	if hp_ratio >= s3 and leaks == 0:
		return 3
	if hp_ratio >= s2:
		return 2
	return 1

func stage_gems(stars: int) -> int:
	return int(balance.getf("gem_per_star", 3)) * stars

func payout_mult() -> float:
	if phase == S_WON:
		return 1.0
	return balance.getf("lose_payout_ratio", 0.3)

# --------------------------- Serialização (M04) ---------------------------

func serialize() -> Dictionary:
	return {
		"stage_id": stage_id, "tier_cap": tier_cap, "slot_count": slot_count,
		"run_coins": run_coins, "base_hp": base_hp, "purchases": purchases,
		"wave_index": wave_index, "phase": phase, "time": time, "prep_timer": prep_timer,
		"rng": rng.serialize(), "next_id": next_id, "leaks": leaks,
		"early_starts": early_starts, "kills": kills, "buy_level": _buy_level,
		"towers": towers.filter(func(t): return t != null),
		"enemies": enemies, "bullets": bullets,
		"spawn_queue": _spawn_queue, "spawn_timer": _spawn_timer,
		"melee_hp": melee_hp, "upgrades": upgrades, "unlocked_addons": unlocked_addons,
	}

func deserialize(d: Dictionary) -> void:
	wave_index = int(d.get("wave_index", -1))
	run_coins = int(d.get("run_coins", 0))
	base_hp = float(d.get("base_hp", base_max_hp))
	purchases = int(d.get("purchases", 0))
	phase = d.get("phase", S_PREP)
	time = float(d.get("time", 0.0))
	prep_timer = float(d.get("prep_timer", 0.0))
	next_id = int(d.get("next_id", 1))
	leaks = int(d.get("leaks", 0))
	early_starts = int(d.get("early_starts", 0))
	kills = int(d.get("kills", 0))
	_buy_level = int(d.get("buy_level", 1))
	rng.restore(int(d.get("rng", 1)))
	towers.clear()
	towers.resize(MAX_SLOTS + 2)
	for t in d.get("towers", []):
		var slot := int(t["slot"])
		if slot < towers.size():
			towers[slot] = t
	enemies.assign(d.get("enemies", []))
	bullets.assign(d.get("bullets", []))
	_spawn_queue = d.get("spawn_queue", []).duplicate()
	_spawn_timer = float(d.get("spawn_timer", 0.0))
	upgrades = d.get("upgrades", {}).duplicate()
	unlocked_addons = d.get("unlocked_addons", []).duplicate()

func state_hash() -> int:
	## Determinismo (M08): mesma seed -> mesmo hash do estado final.
	return serialize().hash()

var hit_flash := 0.0
