class_name Moving
extends Node
## Movimento horizontal simples para Area2D (sem physics server pesado).

@export var enabled := true

var speed := 70.0
var direction := Vector2.LEFT
var stop_x := -INF  # posição de parada (muro); -INF = nunca para

func _process(delta: float) -> void:
	if not enabled or GameManager.state != GameManager.State.PLAYING:
		return
	var body := get_parent() as Node2D
	if body == null:
		return
	var next_x := body.global_position.x + direction.x * speed * delta
	if direction.x < 0.0 and next_x < stop_x:
		next_x = stop_x
	body.global_position.x = next_x
