extends GutTest
## Economia: custo crescente, recompensa, reparo (plano §5).

var eco: EconomyData

func before_each() -> void:
	eco = EconomyData.new()
	eco.reset_run()

func test_custo_inicial() -> void:
	assert_eq(eco.next_cat_cost(), eco.cat_base_cost)

func test_custo_cresce() -> void:
	eco.register_purchase()
	assert_eq(eco.next_cat_cost(), eco.cat_base_cost + eco.cat_cost_increment)
	eco.register_purchase()
	assert_eq(eco.next_cat_cost(), eco.cat_base_cost + eco.cat_cost_increment * 2)

func test_kill_reward_e_hp_sobre_divisor() -> void:
	assert_eq(eco.kill_reward(100.0), roundi(100.0 / eco.kill_reward_divisor))
	assert_eq(eco.kill_reward(1.0), 1)

func test_reparo_custa_25_por_cento_das_moedas() -> void:
	assert_eq(eco.repair_cost(200), 50)
	assert_eq(eco.repair_cost(0), 10)  # mínimo

func test_try_spend_respeita_saldo() -> void:
	GameManager.currency = 30
	assert_false(GameManager.try_spend(50))
	assert_true(GameManager.try_spend(30))
	assert_eq(GameManager.currency, 0)
