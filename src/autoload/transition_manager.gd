extends CanvasLayer
## TransitionManager: fades/slides com Tween + tela de loading com dicas.
## Uso: await TransitionManager.fade_to_scene("res://scenes/main/main_menu.tscn")

const FADE_TIME := 0.35
const TIPS: Array[String] = [
	"Faça merge de 2 gatos iguais para dobrar o poder!",
	"Conserte o muro antes da próxima onda.",
	"O TNT causa dano em área — guarde para grupos!",
	"O CatBoxing segura a linha de frente por alguns segundos.",
	"Chefes aparecem a cada 10 ondas. Prepare-se!",
]

var _rect: ColorRect
var _tip_label: Label
var _busy := false

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0.08, 0.08, 0.1)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_tip_label = Label.new()
	_tip_label.set_anchors_preset(Control.PRESET_CENTER)
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip_label.add_theme_font_size_override(&"font_size", 28)
	_tip_label.modulate.a = 0.0
	_rect.add_child(_tip_label)

func fade_out(with_tip := false) -> void:
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	if with_tip:
		_tip_label.text = TIPS[randi() % TIPS.size()]
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_rect, "modulate:a", 1.0, FADE_TIME)
	tween.tween_property(_tip_label, "modulate:a", 1.0 if with_tip else 0.0, FADE_TIME)
	await tween.finished

func fade_in() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_rect, "modulate:a", 0.0, FADE_TIME)
	tween.tween_property(_tip_label, "modulate:a", 0.0, FADE_TIME * 0.6)
	await tween.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

func fade_to_scene(path: String, with_tip := true) -> void:
	if _busy:
		return
	await fade_out(with_tip)
	get_tree().change_scene_to_file(path)
	await fade_in()

## Slide vertical usado em telas de resultado (win/game over).
func slide_in(control: Control) -> void:
	var start := control.position
	control.position = start + Vector2(0, 120)
	control.modulate.a = 0.0
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "position", start, 0.4)
	tween.tween_property(control, "modulate:a", 1.0, 0.3)
