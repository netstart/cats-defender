extends RefCounted
class_name TestData
## Testes de dados/contratos: stages, localização, manifestos (6).

static func run() -> void:
	_test_stages()
	_test_localization()
	_test_enemies()
	_test_addons()
	_test_state_machine()

static func _test_stages() -> void:
	var ids := StageDatabase.all_stage_ids()
	Ut.eq(ids.size(), 20, "20 fases (5 principais + 15 bônus)")
	for id in ids:
		var s := StageDatabase.get_stage(id)
		Ut.eq(String(s["id"]), id, "stage_id coerente " + id)
		Ut.ok((s["waves"] as Array).size() >= 5, id + " tem >= 5 ondas")
		Ut.ok(String(s["boss"]).begins_with("Enemy Boss"), id + " tem chefe")
		var has_boss_wave := false
		for wv in s["waves"]:
			if wv.get("is_boss", false):
				has_boss_wave = true
		Ut.ok(has_boss_wave, id + " tem onda de chefe")
		Ut.ok(ResourceLoader.exists(String(s["bg"])), "fundo existe: " + String(s["bg"]))
	# desbloqueio por área (13.2)
	var profile := {"stage_progress": {}}
	Ut.ok(StageDatabase.is_unlocked("P1", profile), "P1 sempre aberta")
	Ut.ok(not StageDatabase.is_unlocked("P2", profile), "P2 trava antes de P1")
	Ut.ok(not StageDatabase.is_unlocked("A3_B1", profile), "bônus trava antes da principal")
	profile = {"stage_progress": {"P1": {"completed": true, "stars": 2}}}
	Ut.ok(StageDatabase.is_unlocked("P2", profile), "P2 abre após P1")
	Ut.ok(StageDatabase.is_unlocked("A1_B2", profile), "bônus A1 abre após P1")
	Ut.ok(not StageDatabase.is_unlocked("A2_B1", profile), "bônus A2 trava sem P2")

static func _test_localization() -> void:
	var f := FileAccess.open("res://data/localization.json", FileAccess.READ)
	Ut.ok(f != null, "localization.json existe")
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	Ut.ok(typeof(parsed) == TYPE_DICTIONARY, "localization.json válido")
	var d: Dictionary = parsed
	var missing := []
	for k in d.keys():
		var entry: Dictionary = d[k]
		if String(entry.get("pt_BR", "")).strip_edges() == "" or String(entry.get("en", "")).strip_edges() == "":
			missing.append(k)
	Ut.gt(d.size(), 40, "localização tem > 40 chaves")
	Ut.ok(missing.is_empty(), "sem chaves com tradução faltante (pt_BR/en)")

static func _test_enemies() -> void:
	var b := Balance.new()
	Ut.eq(b.enemies.size(), 15, "8 regulares + 7 chefes no enemies.csv")
	for id in b.enemies:
		var e: Dictionary = b.enemies[id]
		Ut.gt(e["hp"], 0, id + " hp > 0")
		Ut.gt(e["speed"], 0, id + " speed > 0")
		if String(e.get("role", "")) == "support":
			Ut.ok(b.enemies.has(id), "suporte existe")

static func _test_addons() -> void:
	var b := Balance.new()
	Ut.eq(b.addons.size(), 8, "8 addons (AddonIcon1..8)")
	for id in b.addons:
		var a: Dictionary = b.addons[id]
		Ut.ok(String(a["effect"]) != "", id + " tem efeito")
		Ut.gt(a["run"], 0, id + " custo in-run > 0")
		# chave de localização existe
		var f := FileAccess.open("res://data/localization.json", FileAccess.READ)
		var text := f.get_as_text()
		var found := text.find('"addon_' + id + '"') >= 0
		Ut.ok(found, "localização tem chave addon_" + id)

static func _test_state_machine() -> void:
	# M17: transições inválidas rejeitadas
	var gs: Node = load("res://scripts/core/game_state.gd").new()
	gs.app_state = gs.AppState.SPLASH
	Ut.ok(not gs.goto_app(gs.AppState.WIN), "SPLASH->WIN inválido")
	Ut.ok(gs.goto_app(gs.AppState.MENU), "SPLASH->MENU ok")
	gs.play_sub = gs.PlaySub.PREP
	Ut.ok(not gs.goto_play(gs.PlaySub.VICTORY), "PREP->VICTORY inválido")
	Ut.ok(gs.goto_play(gs.PlaySub.WAVE_ACTIVE), "PREP->WAVE ok")
	gs.free()
