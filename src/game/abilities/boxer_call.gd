class_name BoxerCallAbility
extends Ability
## CatBoxing: unidade melee temporária posicionada à frente do muro.

func _init() -> void:
	id = &"boxer"
	cost = 150
	cooldown = 30.0

@export var lifetime := 12.0
@export var boxer_hp := 400.0
@export var boxer_dps := 25.0
@export var punch_range := 70.0

func _activate() -> void:
	AudioManager.play_sfx_id(&"boxer", randf_range(0.95, 1.05))
	var boxer := CatBoxer.new()
	boxer.setup(boxer_hp, boxer_dps, punch_range, lifetime)
	boxer.global_position = Vector2(520, 360)
	add_child(boxer)
