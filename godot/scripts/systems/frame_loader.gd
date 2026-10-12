extends RefCounted
class_name FrameLoader
## Carrega diretório de PNGs -> SpriteFrames (único ponto de criação de frames).
## FPS nunca hardcoded aqui (3.6): vem de CatData/EnemyData (argumento).
## Carregamento lazy por fase (3.3) + cache para reuso dentro da fase.

static var _cache: Dictionary = {}

static func load_dir(dir_path: String, anim_name: String, fps: float = 24.0, loop := true) -> SpriteFrames:
	var key := "%s|%s" % [dir_path, anim_name]
	if _cache.has(key):
		return _cache[key]
	var sf := SpriteFrames.new()
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("FrameLoader: diretório ausente: " + dir_path)
		_cache[key] = sf
		return sf
	var names: Array = []
	for f in dir.get_files():
		var clean: String = f.replace(".import", "")
		if clean.to_lower().ends_with(".png"):
			names.append(clean)
	names.sort()
	for n in names:
		var tex: Texture2D = load(dir_path.path_join(n))
		if tex:
			sf.add_frame(anim_name, tex)
	_cache[key] = sf
	return sf

static func load_character(base_dir: String, spec: Dictionary) -> SpriteFrames:
	# spec: {"idle": ["Idle", 18.0, true], "shoot": ["Shoot", 20.0, false]}
	var key := base_dir + "|char|" + str(spec.hash())
	if _cache.has(key):
		return _cache[key]
	var sf := SpriteFrames.new()
	for anim in spec:
		var s: Array = spec[anim]
		var sub := _load_folder_frames(base_dir.path_join(String(s[0])))
		if sub.is_empty():
			push_error("FrameLoader: sem frames em " + base_dir + "/" + String(s[0]))
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(s[1]))
		sf.set_animation_loop(anim, bool(s[2]))
		for tex in sub:
			sf.add_frame(anim, tex)
	_cache[key] = sf
	return sf

static func _load_folder_frames(dir_path: String) -> Array:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return []
	var names: Array = []
	for f in dir.get_files():
		var clean: String = f.replace(".import", "")
		if clean.to_lower().ends_with(".png"):
			names.append(clean)
	names.sort()
	var out: Array = []
	for n in names:
		var tex: Texture2D = load(dir_path.path_join(n))
		if tex:
			out.append(tex)
	return out

static func clear_cache() -> void:
	_cache.clear()
