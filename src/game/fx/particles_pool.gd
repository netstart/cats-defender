class_name ParticlesPool
extends Node2D
## Rajadas de partículas GPU pré-alocadas (zero alocação no loop).

const POOL_SIZE := 12

var _bursts: Array[GPUParticles2D] = []
var _next := 0

func _ready() -> void:
	for i in POOL_SIZE:
		var p := GPUParticles2D.new()
		p.amount = 14
		p.one_shot = true
		p.explosiveness = 0.9
		p.lifetime = 0.5
		var mat := ParticleProcessMaterial.new()
		mat.direction = Vector3(0, -1, 0)
		mat.spread = 60.0
		mat.initial_velocity_min = 120.0
		mat.initial_velocity_max = 260.0
		mat.gravity = Vector3(0, 400, 0)
		mat.scale_min = 2.0
		mat.scale_max = 5.0
		mat.color = Color(1.0, 0.85, 0.35)
		p.process_material = mat
		p.emitting = false
		add_child(p)
		_bursts.append(p)
	EventBus.enemy_killed.connect(_on_enemy_killed)

func burst(at: Vector2, color: Color = Color.WHITE) -> void:
	var p := _bursts[_next]
	_next = (_next + 1) % POOL_SIZE
	p.global_position = at
	(p.process_material as ParticleProcessMaterial).color = color
	p.restart()
	p.emitting = true

func _on_enemy_killed(enemy: Node, _reward: int) -> void:
	var n := enemy as Node2D
	if n:
		burst(n.global_position, Color(1.0, 0.85, 0.35))
