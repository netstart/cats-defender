extends RefCounted
class_name SimRng
## RNG determinístico (xorshift32) serializável — proibido randf()/randi()
## globais dentro de sim/ (M08).

var state: int

func _init(seed_: int = 1) -> void:
	state = seed_ if seed_ != 0 else 0x2545F491

func next_u32() -> int:
	var x := state
	x ^= (x << 13) & 0xFFFFFFFF
	x ^= (x >> 17)
	x ^= (x << 5) & 0xFFFFFFFF
	state = x & 0xFFFFFFFF
	return state

func randf() -> float:
	return float(next_u32()) / float(0xFFFFFFFF)

func randf_range(a: float, b: float) -> float:
	return a + randf() * (b - a)

func randi_range(a: int, b: int) -> int:
	if b < a:
		return a
	return a + int(next_u32() % (b - a + 1))

func serialize() -> int:
	return state

func restore(s: int) -> void:
	state = s if s != 0 else 0x2545F491
