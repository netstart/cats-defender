class_name EnemyData
extends Resource
## Definição imutável de um inimigo; multiplicadores de fase aplicados em runtime.

@export var id: StringName = &"enemy_01"
@export var atlas_name := "enemy_01"
@export var max_hp := 30.0
@export var move_speed := 70.0
@export var damage := 10.0  # dano ao muro ao atacar
@export var attack_rate := 0.8  # ataques por segundo
@export var attack_range := 10.0
## Recompensa = override se > 0, senão economia calcula hp/10.
@export var coin_reward := 0
@export var is_boss := false
@export var scale_mod := 1.0
