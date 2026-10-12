extends Node
## SceneRouter — troca de cenas com fade curto (120–220 ms, seção 4.1).
## Autoload: SceneRouter

var current_scene: Node = null
var _busy := false

func _ready() -> void:
	var root := get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func goto(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	if GameSettings != null and not GameSettings.reduce_fx and is_instance_valid(current_scene):
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(get_tree().root, "modulate:a", 0.0, 0.15)
		await tw.finished
	_deferred_change(scene_path)

func _deferred_change(scene_path: String) -> void:
	if is_instance_valid(current_scene):
		current_scene.free()
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("SceneRouter: cena não encontrada: " + scene_path)
		get_tree().root.modulate.a = 1.0
		_busy = false
		return
	current_scene = packed.instantiate()
	get_tree().root.add_child.call_deferred(current_scene)
	get_tree().current_scene = current_scene
	if GameSettings != null and not GameSettings.reduce_fx:
		get_tree().root.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(get_tree().root, "modulate:a", 1.0, 0.15)
		await tw.finished
	else:
		get_tree().root.modulate.a = 1.0
	_busy = false
