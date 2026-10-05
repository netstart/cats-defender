class_name HitFlash
extends Node
## Juice: flash branco no CanvasItem alvo ao receber dano (barato, sem shader).

@export var flash_time := 0.08

var _target: CanvasItem
var _tween: Tween

func _ready() -> void:
	_target = get_parent() as CanvasItem
	var health := get_parent().get_node_or_null(^"Health") as Health
	if health:
		health.damaged.connect(_on_damaged)

func _on_damaged(_amount: float) -> void:
	if _target == null:
		return
	if _tween and _tween.is_running():
		_tween.kill()
	if not _target.is_inside_tree():
		return
	_target.modulate = Color(3.0, 3.0, 3.0)
	_tween = create_tween()
	_tween.tween_property(_target, "modulate", Color.WHITE, flash_time)
