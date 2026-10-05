extends Node
## ScreenShake: trauma-based shake aplicado na Camera2D registrada.
## Juice premium: decay exponencial + shake por ruído.

var trauma := 0.0
var _camera: Camera2D
var _noise := FastNoiseLite.new()
var _time := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 4.0

func register_camera(cam: Camera2D) -> void:
	_camera = cam

func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)

func _process(delta: float) -> void:
	if _camera == null:
		return
	if trauma <= 0.0:
		_camera.offset = Vector2.ZERO
		return
	trauma = maxf(0.0, trauma - delta * 1.6)
	_time += delta * 30.0
	var power := trauma * trauma
	_camera.offset = Vector2(
		_noise.get_noise_1d(_time) * 24.0 * power,
		_noise.get_noise_1d(_time + 100.0) * 24.0 * power)
