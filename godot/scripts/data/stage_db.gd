extends RefCounted
class_name StageDatabase
## Banco de fases: 5 principais (P1..P5) + 15 bônus (A{n}_B1..B3) [M33].
## Ondas geradas data-driven; cada bônus mantém tower defense (caminho, base,
## ondas, merge, chefe) conforme 13.2.

const AREAS := ["res://assets/art/Area/Area1.png", "res://assets/art/Area/Area2.png", "res://assets/art/Area/Area3.png", "res://assets/art/Area/Area4.png", "res://assets/art/Area/Area5.png"]

static var AREA_UNLOCK := {
	"P1": true, "P2": ["P1"], "P3": ["P2"], "P4": ["P3"], "P5": ["P4"],
	"A1_B1": ["P1"], "A1_B2": ["P1"], "A1_B3": ["P1"],
	"A2_B1": ["P2"], "A2_B2": ["P2"], "A2_B3": ["P2"],
	"A3_B1": ["P3"], "A3_B2": ["P3"], "A3_B3": ["P3"],
	"A4_B1": ["P4"], "A4_B2": ["P4"], "A4_B3": ["P4"],
	"A5_B1": ["P5"], "A5_B2": ["P5"], "A5_B3": ["P5"],
}

static func all_stage_ids() -> Array:
	return ["P1", "P2", "P3", "P4", "P5",
		"A1_B1", "A1_B2", "A1_B3", "A2_B1", "A2_B2", "A2_B3",
		"A3_B1", "A3_B2", "A3_B3", "A4_B1", "A4_B2", "A4_B3",
		"A5_B1", "A5_B2", "A5_B3"]

static func area_of(stage_id: String) -> int:
	if stage_id.begins_with("P"):
		return int(stage_id.trim_prefix("P"))
	# A{n}_B{k}
	return int(stage_id.split("_")[0].trim_prefix("A"))

static func is_unlocked(stage_id: String, profile: Dictionary) -> bool:
	var deps: Variant = AREA_UNLOCK.get(stage_id, true)
	if deps is bool:
		return deps
	var prog: Dictionary = profile.get("stage_progress", {})
	for d in deps:
		if not bool(prog.get(d, {}).get("completed", false)):
			return false
	return true

static func get_stage(stage_id: String) -> Dictionary:
	var area := area_of(stage_id)
	var tier_cap := mini(8 + (area - 1) * 2, 15)
	var stage := {
		"id": stage_id,
		"area": area,
		"bg": AREAS[area - 1],
		"tier_cap": tier_cap,
		"boss": "Enemy Boss %d" % [clampi(area, 1, 5)],
		"start_coins": 45 - (area - 1) * 3,
		"base_hp": 100,
		"mods": {},
		"waves": [],
	}
	if stage_id.begins_with("P"):
		stage["waves"] = _campaign_waves(area, tier_cap)
		stage["name_key"] = "stage_%s" % stage_id
	else:
		var b := stage_id.split("_")[1]   # B1/B2/B3
		stage["waves"] = _bonus_waves(area, b, tier_cap, stage)
		stage["name_key"] = "stage_%s" % stage_id
	return stage

static func _campaign_waves(area: int, _tier_cap: int) -> Array:
	## 5 ondas regulares + onda de chefe. Curva por área.
	var w: Array = []
	var hp_m := 1.0 + (area - 1) * 0.45
	# Misturas dão identidade por onda (seção 2)
	w.append(_wave([["1", 4 + area, 1.6]], hp_m))
	w.append(_wave([["2", 5 + area, 1.4], ["1", 3, 0.9]], hp_m))
	w.append(_wave([["3", 3, 2.4], ["1", 6, 1.0]], hp_m))
	w.append(_wave([["5", 4, 1.8], ["2", 5, 1.1]], hp_m))
	w.append(_wave([["4", 3, 2.2], ["7", 2, 3.0], ["1", 6, 0.9]], hp_m))
	var boss_wave := _wave([["1", 4, 1.2], ["3", 2, 2.4], ["6", 2, 2.0]], hp_m)
	boss_wave["is_boss"] = true
	boss_wave["spawns"].append({"enemy": "Enemy Boss %d" % clampi(area, 1, 5), "count": 1, "interval": 4.0, "hp_mult": hp_m})
	w.append(boss_wave)
	return w

static func _bonus_waves(area: int, bkind: String, _tier_cap: int, stage: Dictionary) -> Array:
	var w: Array = []
	var hp_m := (1.0 + (area - 1) * 0.45) * 1.05
	match bkind:
		"B1":  # Cerco: mais inimigos de cerco, base com HP reduzido
			stage["base_hp"] = 60
			w.append(_wave([["5", 6, 1.5]], hp_m))
			w.append(_wave([["6", 5, 1.6], ["5", 4, 1.2]], hp_m))
			w.append(_wave([["2", 6, 0.9], ["5", 5, 1.4]], hp_m))
			w.append(_wave([["6", 6, 1.3], ["3", 2, 2.2]], hp_m))
		"B2":  # Reforços limitados: menos recursos, slots bloqueados
			stage["start_coins"] = maxi(20, int(stage["start_coins"]) - 15)
			stage["locked_slots"] = true
			stage["slots_override"] = 8
			stage["mods"] = {"hp_mult": 2.35}
			w.append(_wave([["2", 5, 1.6]], hp_m))
			w.append(_wave([["3", 3, 2.4], ["1", 4, 1.1]], hp_m))
			w.append(_wave([["6", 3, 1.8], ["2", 5, 1.0]], hp_m))
			w.append(_wave([["4", 3, 2.0], ["8", 2, 2.6]], hp_m))
		"B3":  # Horda do chefe: chefe remixado (Boss 6/7 alternados)
			var alt_boss := "Enemy Boss %d" % [6 + (area % 2)]
			stage["boss"] = alt_boss
			w.append(_wave([["1", 8, 0.7], ["2", 6, 0.8]], hp_m))
			w.append(_wave([["3", 4, 1.6], ["7", 3, 2.0]], hp_m))
			w.append(_wave([["5", 5, 1.2], ["6", 4, 1.4]], hp_m))
			w.append(_wave([["2", 8, 0.7], ["4", 4, 1.6]], hp_m))
	var boss_wave := _wave([["1", 5, 1.0]], hp_m)
	boss_wave["is_boss"] = true
	boss_wave["spawns"].append({"enemy": stage["boss"], "count": 1, "interval": 3.0, "hp_mult": hp_m})
	w.append(boss_wave)
	return w

static func _wave(composition: Array, hp_mult: float) -> Dictionary:
	var spawns: Array = []
	for c in composition:
		spawns.append({"enemy": "Enemy Reg %s" % String(c[0]), "count": c[1], "interval": c[2], "hp_mult": hp_mult})
	return {"spawns": spawns, "is_boss": false}
