extends Node
## SceneRouter — troca de cenas com fade curto (120–220 ms, seção 4.1).
## Autoload: SceneRouter
## Observação: o fade usa um FadeLayer (CanvasLayer + ColorRect) próprio, pois
## Window (get_tree().root) não possui a propriedade "modulate" — tweenar
## "root.modulate:a" gera erro em tempo de execução no Godot 4.x.

var current_scene: Node = null
var _busy := false
var _fade: CanvasLayer = null
var _fade_node_path := NodePath()

const FADE_TIME := 0.15

func _ready() -> void:
	var root := get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func _exit_tree() -> void:
	# nunca deixar a tela coberta se o router sair no meio de um fade
	_reset_fade()

func goto(scene_path: String) -> void:
	if _busy:
		return
	_busy = true
	if GameSettings != null and not GameSettings.reduce_fx:
		await _fade_out()
	_change_scene(scene_path)
	if GameSettings != null and not GameSettings.reduce_fx:
		await _fade_in()
	else:
		_reset_fade()
	_busy = false

# ---------------- Transição ----------------

func _change_scene(scene_path: String) -> void:
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("SceneRouter: cena não encontrada: " + scene_path)
		_reset_fade()
		_busy = false
		return
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	current_scene = packed.instantiate()
	get_tree().root.add_child.call_deferred(current_scene)
	get_tree().current_scene = current_scene
	# garante que o nó da cena nova esteja pronto antes do fade-in
	await get_tree().process_frame

func _fade_out() -> void:
	var f := _ensure_fade()
	if f == null:
		return
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(f.rect, "color:a", 1.0, FADE_TIME)
	await tw.finished

func _fade_in() -> void:
	var f := _ensure_fade()
	if f == null:
		return
	f.rect.color.a = 1.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(f.rect, "color:a", 0.0, FADE_TIME)
	await tw.finished
	_reset_fade()

func _reset_fade() -> void:
	if _fade_node_path.is_empty():
		return
	var n := get_node_or_null(_fade_node_path)
	if n != null:
		n.queue_free()
	_fade = null
	_fade_node_path = NodePath()

func _ensure_fade() -> CanvasLayer:
	if is_instance_valid(_fade):
		return _fade as CanvasLayer
	_fade = FadeLayer.new()
	get_tree().root.add_child(_fade)  # adição síncrona: path/fade já valem neste frame
	_fade_node_path = _fade.get_path()
	return _fade
