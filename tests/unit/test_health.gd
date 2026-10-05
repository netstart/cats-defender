extends GutTest
## Health: dano, cura, morte, clamping.

var health: Health

func before_each() -> void:
	health = Health.new()
	add_child_autofree(health)
	health.setup(100.0)

func test_dano_reduz_hp() -> void:
	health.take_damage(30.0)
	assert_eq(health.hp, 70.0)

func test_morte_emite_sinal_uma_vez() -> void:
	watch_signals(health)
	health.take_damage(150.0)
	assert_signal_emitted(health, "died")
	assert_true(health.is_dead)
	health.take_damage(10.0)
	assert_eq(health.hp, 0.0)

func test_cura_nao_passa_do_maximo() -> void:
	health.take_damage(50.0)
	health.heal(999.0)
	assert_eq(health.hp, 100.0)

func test_ratio() -> void:
	health.take_damage(25.0)
	assert_almost_eq(health.ratio(), 0.75, 0.001)
