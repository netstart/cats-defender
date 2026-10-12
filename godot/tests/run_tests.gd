extends SceneTree
## Runner de testes headless: godot --headless --path . -s res://tests/run_tests.gd
## Saída 0 = verde.

const SUITES := [
	"res://tests/test_sim.gd",
	"res://tests/test_data.gd",
]
const UT := "res://tests/framework/ut.gd"

func _initialize() -> void:
	var Ut = load(UT)
	Ut.reset()
	for path in SUITES:
		var suite: Variant = load(path)
		if suite == null:
			printerr("Suite não carregou: " + path)
			Ut.failed += 1
			continue
		print("== Suite: " + path)
		suite.run()
	var code: int = Ut.summary()
	quit(code)

func _process(_delta: float) -> bool:
	return true

