class_name Ability
extends Node
## Base de habilidade: cooldown + custo + ativação. Efeito concreto em _activate().

signal cooldown_changed(ratio: float)
signal used(ability_id: StringName)

@export var id: StringName = &"spikes"
@export var cost := 100
@export var cooldown := 20.0

var _remaining := 0.0

func _process(delta: float) -> void:
	if _remaining > 0.0:
		_remaining -= delta
		cooldown_changed.emit(clampf(1.0 - _remaining / cooldown, 0.0, 1.0))

func can_use() -> bool:
	return _remaining <= 0.0 and GameManager.currency >= cost \
		and GameManager.state == GameManager.State.PLAYING

func use() -> bool:
	if not can_use():
		return false
	GameManager.try_spend(cost)
	_remaining = cooldown
	cooldown_changed.emit(0.0)
	_activate()
	used.emit(id)
	EventBus.ability_used.emit(id)
	AudioManager.vibrate_light()
	return true

func _activate() -> void:
	pass  # sobrescrever
