extends Node2D
class_name CatTowerView
## View de uma torre-gato. Espelha o estado da SimWorld (3.4/3.6).
## Ranged: Characters/C{tier}/Idle+Shoot · Melee: CatGuardian/CatBoxing.

const ART := "res://assets/art/Characters/"

var slot := -1
var tier := 1
var kind := "ranged"
var sprite: AnimatedSprite2D = null

signal tapped(view)
signal long_pressed(view)
signal drag_began(view)

var _press_time := -1.0
var _shoot_back := 0.0

static func tier_dir(t: int) -> String:
	return "%sC%d" % [ART, t]

static func melee_dir(k: String) -> String:
	return "res://assets/art/CatGuardian" if k == "guardian" else "res://assets/art/CatBoxing"

func _ready() -> void:
	z_index = 5
	sprite = AnimatedSprite2D.new()
	sprite.centered = true
	add_child(sprite)

func setup(p_slot: int, p_tier: int, p_kind := "ranged") -> void:
	slot = p_slot
	kind = p_kind
	set_tier(p_tier)
	var area := Area2D.new()
	area.collision_layer = 8   # física: layer 4 = slots (3.7)
	area.input_pickable = true
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(104, 104)
	shape.shape = rect
	area.add_child(shape)
	area.input_event.connect(_on_area_input)
	add_child(area)

func set_tier(t: int) -> void:
	tier = t
	var frames: SpriteFrames
	if kind == "ranged":
		frames = FrameLoader.load_character(tier_dir(t), {
			"idle": ["Idle", 18.0, true],
			"shoot": ["Shoot", 22.0, false],
		})
	else:
		var base := melee_dir(kind)
		frames = FrameLoader.load_character(base, {
			"idle": ["Idle", 18.0, true],
			"attack": ["Attack", 22.0, false],
		})
	sprite.sprite_frames = frames
	if frames.has_animation("idle"):
		sprite.play("idle")

func play_shoot() -> void:
	if sprite.sprite_frames == null:
		return
	if kind == "ranged" and sprite.sprite_frames.has_animation("shoot"):
		sprite.play("shoot")
		_shoot_back = 0.45
	elif kind != "ranged" and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		_shoot_back = 0.45

func downgradeable() -> bool:
	return kind == "ranged"

func _process(delta: float) -> void:
	if _press_time >= 0.0:
		_press_time += delta
	if _shoot_back > 0.0:
		_shoot_back -= delta
		if _shoot_back <= 0.0 and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _on_area_input(_viewport, event: InputEvent, _idx: int) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_time = 0.0
		else:
			if _press_time >= 0.5:
				long_pressed.emit(self)
			else:
				tapped.emit(self)
			_press_time = -1.0
	elif event is InputEventScreenDrag and _press_time >= 0.0 and _press_time < 0.5:
		_press_time = -1.0
		drag_began.emit(self)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# suporte desktop (emulate touch off em Android; útil para testes)
		if event.pressed:
			_press_time = 0.0
		else:
			if _press_time >= 0.5:
				long_pressed.emit(self)
			else:
				tapped.emit(self)
			_press_time = -1.0
