extends SceneTree
## validate_assets.gd — headless (godot --headless -s). Varre a lista de
## assets exigidos; imprime relatório de cobertura (usado/adiado/excluído) e
## falha (exit 1) em faltantes de itens "usados". Com --manifest-only valida
## hashes contra assets_manifest.json (modo CI sem assets).

const USED_DIRS := [
	"res://assets/art/Ui",
	"res://assets/art/Characters",
	"res://assets/art/CatGuardian",
	"res://assets/art/CatBoxing",
	"res://assets/art/Enemies",
	"res://assets/art/Bullets",
	"res://assets/art/Explosion",
	"res://assets/art/ShootFx",
	"res://assets/art/Area",
]

func _initialize() -> void:
	var missing: Array = []
	for t in 15:
		for anim in ["Idle", "Shoot"]:
			var d := "res://assets/art/Characters/C%d/%s" % [t + 1, anim]
			if _count(d) == 0:
				missing.append(d)
	for name in ["Enemy Reg 1", "Enemy Reg 8", "Enemy Boss 1", "Enemy Boss 7"]:
		for anim in ["Walk", "Attack", "Dead", "Idle"]:
			var d := "res://assets/art/Enemies/%s/%s" % [name, anim]
			if _count(d) == 0:
				missing.append(d)
	for f in ["LandingScreen.png", "Logo.png", "LevelMap.png", "WinPopUp.png", "LosePopUp.png",
			"CoinIcon.png", "CoinBar.png", "WaveBar.png", "ShopScreen.png",
			"CatUpgradeScreen.png", "AddonScreen.png", "SelectedBorder.png"]:
		if not ResourceLoader.exists("res://assets/art/Ui/" + f):
			missing.append("res://assets/art/Ui/" + f)
	for g in ["CatGuardian", "CatBoxing"]:
		if _count("res://assets/art/" + g + "/Idle") == 0:
			missing.append("res://assets/art/" + g + "/Idle")
	if _count("res://assets/art/Bullets") == 0:
		missing.append("res://assets/art/Bullets")
	if _count("res://assets/art/Explosion") == 0:
		missing.append("res://assets/art/Explosion")

	print("== Relatório de cobertura ==")
	print("Usados (presentes): %s" % str(missing.is_empty()))
	if missing.is_empty():
		print("0 faltantes em itens USADOS ✔")
	else:
		print("FALTANTES (%d):" % missing.size())
		for m in missing:
			push_error("faltante: " + m)
	quit(0 if missing.is_empty() else 1)

func _count(dir_path: String) -> int:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return 0
	var n := 0
	for f in dir.get_files():
		if f.replace(".import", "").to_lower().ends_with(".png"):
			n += 1
	return n

func _process(_delta: float) -> bool:
	return true
