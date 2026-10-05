class_name CatTower
extends Node2D
## Gato atirador posicionado num slot atrás do muro (Merge Defense).
## tier vai de 1 a CatData.MAX_TIER; merge eleva o tier.

signal tier_upgraded(new_tier: int)

var data: CatData
var tier := 1

var _sprite: AnimatedSprite2D
var _shooting: Shooting
var _base_scale := Vector2(0.65, 0.65)

func setup(p_data: CatData, p_tier := 1) -> void:
	data = p_data
	tier = clampi(p_tier, 1, CatData.MAX_TIER)
	if is_node_ready():
		_apply()

func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = AtlasLoader.make_sprite_frames(data.atlas_name)
	_sprite.play(&"idle")
	add_child(_sprite)
	_shooting = Shooting.new()
	_shooting.target_acquired.connect(_on_target_acquired)
	add_child(_shooting)
	_apply()

func _apply() -> void:
	var dmg := CatData.damage_for_tier(data.damage, tier)
	_shooting.configure(dmg, data.fire_rate, data.projectile_speed, data.range, data.bullet_texture)
	_base_scale = Vector2.ONE * (0.65 + 0.1 * (tier - 1))
	_sprite.scale = _base_scale

## Merge: sobe um tier com squash & stretch (juice obrigatório).
func upgrade_tier() -> void:
	if tier >= CatData.MAX_TIER:
		return
	tier += 1
	_apply()
	tier_upgraded.emit(tier)
	_sprite.play(&"idle")
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_sprite.scale = _base_scale * 1.35
	tween.tween_property(_sprite, "scale", _base_scale, 0.25)
	AudioManager.play_sfx_id(&"merge", randf_range(0.95, 1.05))

func play_shoot() -> void:
	if _sprite.sprite_frames.has_animation(&"shoot"):
		_sprite.play(&"shoot")
		await _sprite.animation_finished
		if _sprite.sprite_frames.has_animation(&"idle"):
			_sprite.play(&"idle")

func _on_target_acquired(_target: Node2D) -> void:
	play_shoot()
