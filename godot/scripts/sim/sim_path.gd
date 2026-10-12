extends RefCounted
class_name SimPath
## Caminho 1D: inimigos têm progress ∈ [0,1] (M08). Sem consultas espaciais.
## `length` é o comprimento lógico do caminho em "unidades" (px de referência
## do layout 1200x540); velocidades vêm em unidades/s.

var length: float = 1000.0
var base_at := 1.0          # posição da base no caminho
var melee_slots: Array[float] = [0.82, 0.88]   # slots de melee na frente da base

func _init(path_length: float = 1000.0) -> void:
	length = path_length

func position_x(progress: float) -> float:
	return progress * length

func clamp_progress(p: float) -> float:
	return clampf(p, 0.0, base_at)
