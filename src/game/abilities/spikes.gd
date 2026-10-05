class_name SpikesAbility
extends Ability
## Espinhos: slow + DoT em todos os inimigos na área da pista (perto do muro).

func _init() -> void:
	id = &"spikes"
	cost = 60
	cooldown = 14.0

@export var slow_factor := 0.45
@export var slow_duration := 4.0
@export var dot_dps := 8.0
@export var dot_duration := 4.0
@export var area_min_x := 0.0
@export var area_max_x := 800.0

func _activate() -> void:
	AudioManager.play_sfx_id(&"spikes", randf_range(0.95, 1.05))
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var e := node as Enemy
		if e == null or e.is_dead:
			continue
		if e.global_position.x <= area_max_x and e.global_position.x >= area_min_x:
			e.apply_slow(slow_factor, slow_duration)
			e.apply_dot(dot_dps, dot_duration)
