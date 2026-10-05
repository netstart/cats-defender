class_name SlotGrid
extends Node2D
## Grid 2×5 de slots atrás do muro. Cada slot guarda no máximo um CatTower.

const COLS := 5
const ROWS := 2
const SLOT_SPACING := Vector2(110, 140)

var _slots: Array = []  # Array[CatTower|null]
var _markers: Array[Node2D] = []

func _ready() -> void:
	_slots.resize(COLS * ROWS)
	_markers.resize(COLS * ROWS)
	for i in COLS * ROWS:
		var m := Node2D.new()
		m.position = slot_position(i)
		add_child(m)
		_markers[i] = m
		var visual := ColorRect.new()
		visual.color = Color(1, 1, 1, 0.08)
		visual.size = Vector2(90, 110)
		visual.position = -visual.size / 2.0
		m.add_child(visual)

func slot_position(index: int) -> Vector2:
	var col := index % COLS
	var row := index / COLS
	## origem definida pela posição do próprio SlotGrid na cena
	return Vector2(col * SLOT_SPACING.x, row * SLOT_SPACING.y)

func slot_at_screen(world_pos: Vector2) -> int:
	var best := -1
	var best_d := 70.0  # raio de snap
	for i in COLS * ROWS:
		var d: float = to_local(world_pos).distance_to(slot_position(i))
		if d < best_d:
			best_d = d
			best = i
	return best

func is_free(index: int) -> bool:
	return index >= 0 and index < _slots.size() and _slots[index] == null

func free_slot() -> int:
	for i in _slots.size():
		if _slots[i] == null:
			return i
	return -1

func place(cat: CatTower, index: int) -> bool:
	if not is_free(index):
		return false
	_slots[index] = cat
	if cat.get_parent() != _markers[index]:
		if cat.get_parent():
			cat.get_parent().remove_child(cat)
		_markers[index].add_child(cat)
	cat.position = Vector2.ZERO
	return true

func remove_at(index: int) -> CatTower:
	var cat: CatTower = _slots[index]
	_slots[index] = null
	return cat

func get_at(index: int) -> CatTower:
	return _slots[index] if index >= 0 and index < _slots.size() else null

## Merge: 2 gatos iguais (mesmo id + tier) → tier+1. Retorna o slot resultante ou -1.
func try_merge(from_index: int, to_index: int) -> int:
	if from_index == to_index or _slots[from_index] == null or _slots[to_index] == null:
		return -1
	var a: CatTower = _slots[from_index]
	var b: CatTower = _slots[to_index]
	if a.data.id != b.data.id or a.tier != b.tier or a.tier >= CatData.MAX_TIER:
		return -1
	b.upgrade_tier()
	remove_at(from_index).queue_free()
	_slots[from_index] = null
	EventBus.cats_merged.emit(b.tier, to_index)
	AudioManager.play_sfx_id(&"merge", randf_range(0.95, 1.05))
	AudioManager.vibrate_light()
	return to_index
