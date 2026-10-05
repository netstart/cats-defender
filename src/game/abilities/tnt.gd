class_name TntAbility
extends Ability
## TNT: dano em área no ponto mais denso de inimigos + screenshake + explosão.

func _init() -> void:
	id = &"tnt"
	cost = 100
	cooldown = 20.0

@export var damage := 120.0
@export var radius := 150.0

func _activate() -> void:
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	if enemies.is_empty():
		return
	# alvo: inimigo mais avançado (menor x) ainda longe do muro
	var best: Enemy = null
	for node in enemies:
		var e := node as Enemy
		if e and not e.is_dead and (best == null or e.global_position.x < best.global_position.x) \
				and e.global_position.x > 400.0:
			best = e
	var center: Vector2 = best.global_position if best else (enemies[0] as Node2D).global_position
	AudioManager.play_sfx_id(&"explosion", randf_range(0.9, 1.1))
	_spawn_explosion(center)
	ScreenShake.add_trauma(0.8)
	for node in enemies:
		var e := node as Enemy
		if e and not e.is_dead and e.global_position.distance_to(center) <= radius:
			e.take_damage(damage)

func _spawn_explosion(at: Vector2) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"boom")
	frames.set_animation_speed(&"boom", 16.0)
	frames.set_animation_loop(&"boom", false)
	var tex: Texture2D = load("res://assets/art/fx/explosion.png")
	const COUNT := 8
	for i in COUNT:
		var at_tex := AtlasTexture.new()
		at_tex.atlas = tex
		at_tex.region = Rect2(i * 128, 0, 128, 128)
		frames.add_frame(&"boom", at_tex)
	var anim := AnimatedSprite2D.new()
	anim.sprite_frames = frames
	anim.global_position = at
	anim.scale = Vector2.ONE * 2.0
	add_child(anim)
	anim.play(&"boom")
	var light := PointLight2D.new()
	light.energy = 1.6
	light.texture_scale = 2.0
	light.color = Color(1.0, 0.7, 0.3)
	anim.add_child(light)
	var tween := light.create_tween()
	tween.tween_property(light, "energy", 0.0, 0.4)
	anim.animation_finished.connect(func() -> void: anim.queue_free())
