class_name MergeController
extends Node2D
## Drag & drop: arrasta gato de um slot para outro (touch/mouse unificado).
## Soltou em slot vazio → move; em gato igual → merge; senão volta.

const DRAG_SCALE := Vector2(0.85, 0.85)

var grid: SlotGrid
var _drag_cat: CatTower = null
var _drag_from := -1
var _drag_origin := Vector2.ZERO
var _ghost: Node2D

func _ready() -> void:
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed
		var pos: Vector2 = event.position
		if pressed:
			_begin_drag(pos)
		else:
			_end_drag(pos)
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and _drag_cat:
		_update_drag(event.position)

func _begin_drag(screen_pos: Vector2) -> void:
	var idx := grid.slot_at_screen(_world_from_screen(screen_pos))
	if idx < 0 or grid.is_free(idx):
		return
	_drag_from = idx
	_drag_cat = grid.get_at(idx)
	_drag_origin = _drag_cat.global_position
	_ghost = _drag_cat.duplicate()
	_ghost.modulate = Color(1, 1, 1, 0.6)
	_ghost.scale = DRAG_SCALE
	add_child(_ghost)
	_ghost.global_position = _drag_cat.global_position
	_drag_cat.visible = false

func _update_drag(screen_pos: Vector2) -> void:
	if _ghost:
		_ghost.global_position = _world_from_screen(screen_pos)

func _end_drag(screen_pos: Vector2) -> void:
	if _drag_cat == null:
		return
	var idx := grid.slot_at_screen(_world_from_screen(screen_pos))
	var merged := -1
	if idx >= 0:
		if grid.is_free(idx):
			var cat := grid.remove_at(_drag_from)
			grid.place(cat, idx)
		else:
			merged = grid.try_merge(_drag_from, idx)
	if merged < 0:
		_drag_cat.visible = true
	_drag_cat = null
	_drag_from = -1
	if _ghost:
		_ghost.queue_free()
		_ghost = null

func _world_from_screen(screen_pos: Vector2) -> Vector2:
	var canvas := get_canvas_transform()
	return canvas.affine_inverse() * screen_pos
