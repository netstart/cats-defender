extends Node
## PoolManager: pooling genérico de nós (projéteis, partículas, números de dano).
## Regra premium: ZERO alocação no loop quente — tudo pré-instanciado aqui.

var _pools: Dictionary = {}  # StringName -> {free: Array[Node], scene: PackedScene}
var _holders: Dictionary = {}  # StringName -> Node

func register(pool_id: StringName, scene: PackedScene, prewarm: int = 32) -> void:
	if _pools.has(pool_id):
		return
	var holder := Node.new()
	holder.name = "Pool_%s" % pool_id
	add_child(holder)
	_holders[pool_id] = holder
	_pools[pool_id] = {"scene": scene, "free": []}
	for i in prewarm:
		_pools[pool_id]["free"].append(_instantiate(pool_id))

func _instantiate(pool_id: StringName) -> Node:
	var node: Node = _pools[pool_id]["scene"].instantiate()
	node.set_meta(&"pool_id", pool_id)
	_holders[pool_id].add_child(node)
	if node.has_method(&"pool_deactivate"):
		node.call(&"pool_deactivate")
	else:
		node.process_mode = Node.PROCESS_MODE_DISABLED
		if node is CanvasItem:
			node.hide()
	return node

## Retorna um nó pronto para uso (nunca null em runtime; expande o pool se preciso).
func acquire(pool_id: StringName) -> Node:
	if not _pools.has(pool_id):
		push_error("PoolManager: pool '%s' não registrado" % pool_id)
		return null
	var free: Array = _pools[pool_id]["free"]
	var node: Node = free.pop_back() if not free.is_empty() else _instantiate(pool_id)
	if node.has_method(&"pool_activate"):
		node.call(&"pool_activate")
	else:
		node.process_mode = Node.PROCESS_MODE_INHERIT
		if node is CanvasItem:
			node.show()
	return node

func release(node: Node) -> void:
	if node == null:
		return
	var pool_id: StringName = node.get_meta(&"pool_id", &"")
	if not _pools.has(pool_id):
		node.queue_free()
		return
	if node.has_method(&"pool_deactivate"):
		node.call(&"pool_deactivate")
	else:
		node.process_mode = Node.PROCESS_MODE_DISABLED
		if node is CanvasItem:
			node.hide()
	_pools[pool_id]["free"].append(node)

func pool_size(pool_id: StringName) -> int:
	return _pools.get(pool_id, {"free": []})["free"].size()
