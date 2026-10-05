class_name LevelData
extends Resource
## Uma fase: N ondas + modificadores de dificuldade + modo de jogo.

enum Mode { MERGE, TOWER_DEFENSE }

@export var level_index := 1
@export var mode: Mode = Mode.MERGE
@export var hp_multiplier := 1.0
@export var speed_multiplier := 1.0
@export var waves: Array[WaveData] = []
## Habilidades desbloqueadas nesta fase (controle da curva de novidades).
@export var unlock_abilities: Array[StringName] = []
@export var is_boss_level := false
@export var coin_reward_base := 100
## Loja sorteia entre os primeiros N gatos do catálogo (define a variedade de merge).
@export var cat_pool_size := 4
