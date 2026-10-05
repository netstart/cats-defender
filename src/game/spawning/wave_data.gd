class_name WaveData
extends Resource
## Uma onda: lista de spawns {enemy_id, count, interval, delay}.

@export var spawns: Array[Dictionary] = []
## Segundos de descanso após a onda ser limpa antes da próxima.
@export var rest_time := 2.0
