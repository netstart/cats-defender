extends Node
## EventBus: barramento global de sinais para desacoplar sistemas.
## Regra: cenas NUNCA se referenciam diretamente; emitem/assinem aqui.

signal game_started
signal game_over(victory: bool)
signal wave_started(wave_index: int, wave_total: int)
signal wave_cleared(wave_index: int)
signal level_completed(stars: int)
signal enemy_killed(enemy: Node, reward: int)
signal enemy_leaked(enemy: Node)
signal cat_damaged(cat: Node, amount: int)
signal cat_died(cat: Node)
signal shot_fired(projectile: Node)
signal currency_changed(amount: int)
signal wall_damaged(current_hp: int, max_hp: int)
signal cat_bought(cat: Node)
signal cats_merged(result_tier: int, at_slot: int)
signal ability_used(ability_id: StringName)
signal boss_spawned(boss: Node)
signal damage_number_requested(world_pos: Vector2, amount: int, is_crit: bool)
signal score_changed(score: int)
signal request_pause_menu
signal request_game_over_screen

func emit_safe(sig: StringName, args: Array = []) -> void:
	callv(&"emit_signal", [sig] + args)
