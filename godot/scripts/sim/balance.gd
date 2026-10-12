extends RefCounted
class_name Balance
## Lê res://data/balance.json e res://data/enemies.json.
## (JSON é embutido no export; CSV vira Translation e não entra raw no APK.)

var values: Dictionary = {}
var enemies: Dictionary = {}        # id -> Dictionary
var cats: Dictionary = {}           # tier -> {dmg, interval, range_p, bullet, targeting...}
var addons: Dictionary = {}         # id -> {effect, magnitude, cost_run, cost_bank}

func _init() -> void:
	values = _read_json("res://data/balance.json")
	enemies = _read_json("res://data/enemies.json")
	_setup_cats()
	_setup_addons()

func _read_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Balance: dados ausentes: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Balance: JSON inválido: " + path)
		return {}
	return parsed

func getf(key: String, fallback := 0.0) -> float:
	return float(values.get(key, fallback))

func max_tier() -> int:
	return 15

## DPS de um gato de tier t (crescimento geométrico + upgrade permanente).
func cat_damage(tier: int, upgrade_lvl: int = 0) -> float:
	var base := getf("cat_base_dmg", 20.0)
	var growth := getf("cat_dmg_growth", 1.35)
	return base * pow(growth, tier - 1) * (1.0 + 0.05 * upgrade_lvl)

func cat_interval(tier: int) -> float:
	# tiers altos atiram um pouco mais rápido
	return maxf(0.45, getf("cat_base_interval", 1.2) * pow(0.985, tier - 1))

func cat_range_p(tier: int) -> float:
	# fração do caminho coberta a partir da base (cobre inimigos com progress >= 1-range)
	return clampf(getf("cat_base_range", 0.6) + 0.015 * tier, 0.3, 1.0)

func cat_bullet_kind(tier: int) -> String:
	# 3 arquétipos (2): tiro reto, slow, granada balística
	var grenade_from := int(getf("grenade_tier_from", 6))
	var slow_tiers := [4, 8, 12]
	if tier >= grenade_from:
		return "grenade"
	if tier in slow_tiers:
		return "slow"
	return "straight"

func buy_cost(purchases: int) -> int:
	return int(round(getf("buy_base_cost", 10.0) * pow(getf("buy_growth", 1.08), purchases)))

func sell_refund(tier: int, purchases_spent: int, refund_bonus := 0.0) -> int:
	var pct := getf("sell_refund", 0.5) + refund_bonus
	return int(floor(purchases_spent * pct))

func cat_cost_value(tier: int) -> int:
	# valor acumulado (em compras do tier de compra) de um gato de tier t
	return int(getf("buy_base_cost", 10.0) * (1 << (tier - 1)))

func _setup_cats() -> void:
	for t in range(1, max_tier() + 1):
		cats[t] = {
			"dmg": cat_damage(t, 0),
			"interval": cat_interval(t),
			"range_p": cat_range_p(t),
			"bullet": cat_bullet_kind(t),
		}

func _setup_addons() -> void:
	# id, efeito, magnitude, custo destrave (bank), custo por partida (run)
	addons = {
		"overload":   {"effect": "dmg_mult",      "value": 0.30, "bank": 150, "run": 20, "category": 1},
		"long_scope": {"effect": "range_mult",    "value": 0.30, "bank": 150, "run": 20, "category": 1},
		"rapid":      {"effect": "rate_mult",     "value": 0.30, "bank": 150, "run": 20, "category": 1},
		"frost":      {"effect": "slow",          "value": 0.35, "bank": 150, "run": 20, "category": 1},
		"swift_shot": {"effect": "bullet_speed",  "value": 0.35, "bank": 150, "run": 20, "category": 2},
		"bounty":     {"effect": "kill_coins",    "value": 2.0,  "bank": 150, "run": 20, "category": 2},
		"refund":     {"effect": "sell_bonus",    "value": 0.25, "bank": 150, "run": 20, "category": 2},
		"guardian":   {"effect": "siege_resist",  "value": 0.15, "bank": 150, "run": 20, "category": 3},
	}
