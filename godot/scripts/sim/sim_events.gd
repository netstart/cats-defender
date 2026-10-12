extends RefCounted
class_name SimEvents
## Tipos de evento emitidos pela simulação para a view (SimWorld.tick_all
## devolve uma lista de Dictionaries com {type, ...} a cada tick).

const ENEMY_SPAWNED := "enemy_spawned"
const ENEMY_DIED := "enemy_died"
const ENEMY_SIEGED := "enemy_sieged"        # entrou em estado SIEGE na base
const BASE_DAMAGED := "base_damaged"
const BULLET_FIRED := "bullet_fired"
const BULLET_HIT := "bullet_hit"
const EXPLOSION := "explosion"
const COIN_SPAWNED := "coin_spawned"
const WAVE_STARTED := "wave_started"
const WAVE_CLEARED := "wave_cleared"
const BOSS_SPAWNED := "boss_spawned"
const BOSS_ENRAGED := "boss_enraged"
const STAGE_WON := "stage_won"
const STAGE_LOST := "stage_lost"
const CAT_FIRED := "cat_fired"              # para tocar animação Shoot
const MELEE_HIT := "melee_hit"

static func ev(type: String, data := {}) -> Dictionary:
	var d := {"type": type}
	d.merge(data)
	return d
