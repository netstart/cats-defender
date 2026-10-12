extends RefCounted
class_name Ut
## Mini-framework de testes (headless). Acumula resultados; o runner imprime
## o resumo e sai com código de saída (0 = verde).

static var passed := 0
static var failed := 0
static var failures: Array = []

static func reset() -> void:
	passed = 0
	failed = 0
	failures = []

static func ok(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		failures.append(msg)
		printerr("[FAIL] " + msg)

static func eq(a: Variant, b: Variant, msg: String) -> void:
	ok(a == b, "%s (esperado=%s obtido=%s)" % [msg, str(b), str(a)])

static func ne(a: Variant, b: Variant, msg: String) -> void:
	ok(a != b, "%s (não deveria ser %s)" % [msg, str(b)])

static func gt(a: Variant, b: Variant, msg: String) -> void:
	ok(float(a) > float(b), "%s (%s > %s)" % [msg, str(a), str(b)])

static func le(a: Variant, b: Variant, msg: String) -> void:
	ok(float(a) <= float(b), "%s (%s <= %s)" % [msg, str(a), str(b)])

static func ge(a: Variant, b: Variant, msg: String) -> void:
	ok(float(a) >= float(b), "%s (%s >= %s)" % [msg, str(a), str(b)])

static func summary() -> int:
	print("== Testes: %d OK, %d falhas ==" % [passed, failed])
	if failed > 0:
		for f in failures:
			print("  FAIL: " + f)
	return 0 if failed == 0 else 1
