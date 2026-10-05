class_name GridPlacement
extends Node2D
## Posicionamento livre em grid (modo TD). Células de 96px; não bloqueia o caminho.

const CELL := 96


var path_cells: Dictionary = {}  # Vector2i -> true (não pode construir)
var _grid_size := Vector2i(1280 / CELL, 720 / CELL)
var _occupied: Dictionary = {}  # Vector2i -> CatTower

func world_to_cell(world: Vector2) -> Vector2i:
	return Vector2i(int(world.x / CELL), int(world.y / CELL))

func is_free(cell: Vector2i) -> bool:
	return not _occupied.has(cell) and not path_cells.has(cell) \
		and cell.x >= 0 and cell.y >= 0 and cell.x < _grid_size.x and cell.y < _grid_size.y

func place(cat: CatTower, cell: Vector2i) -> bool:
	if not is_free(cell):
		return false
	_occupied[cell] = cat
	cat.global_position = Vector2(cell.x * CELL + CELL / 2.0, cell.y * CELL + CELL / 2.0)
	if cat.get_parent() == null:
		add_child(cat)
	return true

func get_at(cell: Vector2i) -> CatTower:
	return _occupied.get(cell)

func mark_path(cell: Vector2i) -> void:
	path_cells[cell] = true
