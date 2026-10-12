extends CanvasLayer
class_name FadeLayer
## Camada preta de fade usada pelo SceneRouter. Window (root) não possui a
## propriedade "modulate", por isso o fade precisa viver num CanvasLayer/ColorRect.

var rect: ColorRect

func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # funciona mesmo com a árvore pausada
	# rect criado em _init para que exista imediatamente (antes do ready)
	rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rect)
