extends RefCounted
class_name ObjectPool
## Pool genérico de nós com capacidade máxima (3.8). Overflow loga degradando
## efeito cosmético, nunca aloca indefinidamente.

var scene: PackedScene
var capacity: int
var parent: Node
var _free: Array = []
var _used: Array = []
var overflow_count := 0

func _init(p_scene: PackedScene, p_capacity: int, p_parent: Node) -> void:
	scene = p_scene
	capacity = p_capacity
	parent = p_parent

func prewarm() -> void:
	for i in capacity:
		var node: Node = scene.instantiate()
		node.visible = false
		if node.has_method("pool_deactivate"):
			node.pool_deactivate()
		parent.add_child(node)
		_free.append(node)

func acquire() -> Node:
	if _free.is_empty():
		overflow_count += 1
		return null
	var node: Node = _free.pop_back()
	_used.append(node)
	node.visible = true
	if node.has_method("pool_activate"):
		node.pool_activate()
	return node

func release(node: Node) -> void:
	if node not in _used:
		return
	_used.erase(node)
	node.visible = false
	if node.has_method("pool_deactivate"):
		node.pool_deactivate()
	_free.append(node)

func used_count() -> int:
	return _used.size()
