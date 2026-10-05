class_name Health
extends Node
## Componente de vida reutilizável (gato, inimigo, muro, boss).

signal hp_changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

@export var max_hp := 100.0

var hp: float:
	set(value):
		hp = clampf(value, 0.0, max_hp)
		hp_changed.emit(hp, max_hp)

var is_dead := false

func _ready() -> void:
	hp = max_hp

func setup(value: float) -> void:
	max_hp = value
	is_dead = false
	hp = value

func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	hp -= amount
	damaged.emit(amount)
	if hp <= 0.0:
		is_dead = true
		died.emit()

func heal(amount: float) -> void:
	if is_dead:
		return
	hp = minf(hp + amount, max_hp)

func ratio() -> float:
	return hp / max_hp if max_hp > 0.0 else 0.0
