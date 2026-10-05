extends SceneTree
## tools/gen_data.gd — gera todos os .tres (gatos, inimigos, economia, 30 fases merge + 10 TD).
## Rode: godot --headless --script tools/gen_data.gd

const CAT_COUNT := 15
const ENEMY_COUNT := 8

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/cats")
	DirAccess.make_dir_recursive_absolute("res://data/enemies")
	DirAccess.make_dir_recursive_absolute("res://data/waves")
	DirAccess.make_dir_recursive_absolute("res://data/economy")

	_gen_cats()
	_gen_enemies()
	_gen_economy()
	_gen_levels()
	print("[gen_data] done")
	quit()

func _gen_cats() -> void:
	var bullets := [
		"res://assets/art/sprites/bullets/bullet_yellow.png",
		"res://assets/art/sprites/bullets/bullet_red.png",
		"res://assets/art/sprites/bullets/bullet_blue.png",
	]
	for i in range(1, CAT_COUNT + 1):
		var c := CatData.new()
		c.id = StringName("cat_%02d" % i)
		c.atlas_name = "cat_%02d" % i
		c.display_name = "Gato %02d" % i
		# variação de papel: dano vs cadência
		c.damage = 10.0 + (i % 5) * 3.0
		c.fire_rate = 0.9 + (i % 3) * 0.25
		c.projectile_speed = 560.0 + (i % 4) * 60.0
		c.range = 950.0
		c.bullet_texture = load(bullets[i % 3])
		ResourceSaver.save(c, "res://data/cats/%s.tres" % c.id)

func _gen_enemies() -> void:
	var registry := EnemyRegistry.new()
	for i in range(1, ENEMY_COUNT + 1):
		var e := EnemyData.new()
		e.id = StringName("enemy_%02d" % i)
		e.atlas_name = "enemy_%02d" % i
		e.max_hp = 18.0 + i * 10.0
		e.move_speed = 65.0 + (i % 3) * 12.0
		e.damage = 6.0 + i * 2.0
		e.attack_rate = 0.7 + (i % 2) * 0.2
		e.attack_range = 14.0
		e.scale_mod = 0.9 + (i % 4) * 0.12
		registry.enemies.append(e)
		ResourceSaver.save(e, "res://data/enemies/%s.tres" % e.id)
	# boss
	var boss := EnemyData.new()
	boss.id = &"cat_guardian"
	boss.atlas_name = &"cat_guardian"
	boss.max_hp = 900.0
	boss.move_speed = 34.0
	boss.damage = 40.0
	boss.attack_rate = 0.6
	boss.attack_range = 26.0
	boss.is_boss = true
	boss.scale_mod = 1.6
	boss.coin_reward = 300
	registry.enemies.append(boss)
	ResourceSaver.save(boss, "res://data/enemies/cat_guardian.tres")
	registry.build_index()
	ResourceSaver.save(registry, "res://data/enemies/registry.tres")

func _gen_economy() -> void:
	var eco := EconomyData.new()
	ResourceSaver.save(eco, "res://data/economy/economy.tres")

## Curva de progressão (Plano §5): fases 1–30 merge + 10 TD.
func _gen_levels() -> void:
	for i in range(1, 31):
		var lv := LevelData.new()
		lv.level_index = i
		lv.mode = LevelData.Mode.MERGE
		lv.hp_multiplier = _hp_mult(i)
		lv.speed_multiplier = 1.0 + minf(0.6, (i - 1) * 0.02)
		lv.is_boss_level = i == 10 or i == 30
		lv.coin_reward_base = 80 + i * 12
		lv.cat_pool_size = clampi(3 + i / 3, 3, 9)
		if i >= 4:
			lv.unlock_abilities.append(&"spikes")
		if i >= 7:
			lv.unlock_abilities.append(&"tnt")
		if i >= 11:
			lv.unlock_abilities.append(&"boxer")
		lv.waves = _waves_for(i)
		ResourceSaver.save(lv, "res://data/waves/merge_%02d.tres" % i)
	for i in range(1, 11):
		var lv := LevelData.new()
		lv.level_index = i
		lv.mode = LevelData.Mode.TOWER_DEFENSE
		lv.hp_multiplier = 1.0 + (i - 1) * 2.0
		lv.speed_multiplier = 1.0 + i * 0.03
		lv.coin_reward_base = (80 + i * 12) * 2
		lv.waves = _waves_for(mini(i * 3, 30))
		ResourceSaver.save(lv, "res://data/waves/td_%02d.tres" % i)

func _hp_mult(i: int) -> float:
	match true:
		_ when i <= 3: return lerpf(1.0, 1.3, (i - 1) / 2.0)
		_ when i <= 6: return lerpf(1.5, 2.0, (i - 4) / 2.0)
		_ when i <= 9: return lerpf(2.2, 3.0, (i - 7) / 2.0)
		_ when i == 10: return 3.5
		_ when i <= 15: return lerpf(3.6, 4.6, (i - 11) / 4.0)
		_ when i <= 20: return lerpf(4.8, 5.8, (i - 16) / 4.0)
		_ when i <= 29: return lerpf(5.8, 6.2, (i - 21) / 8.0)
		_: return 7.0

func _waves_for(i: int) -> Array[WaveData]:
	var result: Array[WaveData] = []
	var wave_count: int
	if i <= 3:
		wave_count = 3
	elif i <= 6:
		wave_count = 5
	elif i <= 9:
		wave_count = 6
	elif i <= 15:
		wave_count = 7
	elif i <= 21:
		wave_count = 8
	else:
		wave_count = 6
	var max_enemy := clampi(1 + (i - 1) / 2, 2, 8)
	for w in wave_count:
		var wave := WaveData.new()
		wave.rest_time = 2.5
		var budget := mini(2 + i / 3 + w, 10)
		while budget > 0:
			var enemy_id := randi_range(1, max_enemy)
			var count := clampi(randi_range(2, 4), 1, budget)
			wave.spawns.append({
				"enemy_id": StringName("enemy_%02d" % enemy_id),
				"count": count,
				"interval": maxf(0.6, 1.6 - i * 0.03),
				"delay": float(wave.spawns.size()) * 2.0,
			})
			budget -= count
		result.append(wave)
	if i == 10 or i == 30:
		var boss_wave := WaveData.new()
		boss_wave.rest_time = 0.0
		boss_wave.spawns.append({
			"enemy_id": &"cat_guardian",
			"count": 1 + (1 if i == 30 else 0),
			"interval": 6.0,
			"delay": 4.0,
		})
		result.append(boss_wave)
	return result
