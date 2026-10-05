class_name EnemyRegistry
extends Resource
## Catálogo de inimigos carregado de data/enemies (data-driven).

@export var enemies: Array[EnemyData] = []

var _by_id: Dictionary = {}

func build_index() -> void:
	_by_id.clear()
	for e in enemies:
		if e:
			_by_id[e.id] = e

func get_enemy(id: StringName) -> EnemyData:
	if _by_id.is_empty():
		build_index()
	return _by_id.get(id)

func boss() -> EnemyData:
	for e in enemies:
		if e and e.is_boss:
			return e
	return null
