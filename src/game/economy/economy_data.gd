class_name EconomyData
extends Resource
## Economia global (validada por tools/simulate.py — win-rate alvo 60–80%).

@export var initial_currency := 150
@export var cat_base_cost := 40
@export var cat_cost_increment := 10
## kill drop = enemy_hp / kill_reward_divisor
@export var kill_reward_divisor := 3.0
## reparo do muro: custo = wall_repair_cost_fraction * moedas_ganhas_na_wave
@export var wall_repair_cost_fraction := 0.25
## cura por reparo (fração do HP máximo do muro)
@export var wall_repair_heal_fraction := 0.30
@export var wall_max_hp := 800.0

var _purchases := 0

func reset_run() -> void:
	_purchases = 0

func next_cat_cost() -> int:
	return cat_base_cost + cat_cost_increment * _purchases

func register_purchase() -> void:
	_purchases += 1

func kill_reward(enemy_hp: float) -> int:
	return maxi(1, roundi(enemy_hp / kill_reward_divisor))

func repair_cost(coins_earned_this_wave: int) -> int:
	return maxi(10, roundi(coins_earned_this_wave * wall_repair_cost_fraction))
