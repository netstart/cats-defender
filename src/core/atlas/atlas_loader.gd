class_name AtlasLoader
extends RefCounted
## Constrói SpriteFrames a partir dos atlases gerados por tools/build_atlas.py.
## 1 atlas por animação = 1 draw call por unidade no renderer Mobile.

const INDEX_PATH := "res://assets/art/atlases/atlas_index.json"
const ATLAS_DIR := "res://assets/art/atlases/"

static var _texture_cache: Dictionary = {}

static func load_index() -> Dictionary:
	var file := FileAccess.open(INDEX_PATH, FileAccess.READ)
	if file == null:
		push_error("AtlasLoader: atlas_index.json não encontrado — rode tools/build_atlas.py")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func _get_texture(png_name: String) -> Texture2D:
	if _texture_cache.has(png_name):
		return _texture_cache[png_name]
	var tex: Texture2D = load(ATLAS_DIR + png_name)
	_texture_cache[png_name] = tex
	return tex

## Retorna SpriteFrames com todas as animações do personagem (ex.: "cat_01").
static func make_sprite_frames(char_name: String, fps := 8.0) -> SpriteFrames:
	var index := load_index()
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	if not index.has(char_name):
		push_error("AtlasLoader: personagem '%s' ausente no índice" % char_name)
		return frames
	var anims: Dictionary = index[char_name]["anims"]
	for anim: String in anims:
		var info: Dictionary = anims[anim]
		var tex := _get_texture(info["png"])
		var count: int = info["frames"]
		var fw: int = info["frame_w"]
		var fh: int = info["frame_h"]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		frames.set_animation_loop(anim, anim != "dead")
		for i in count:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * fw, 0, fw, fh)
			frames.add_frame(anim, at)
	return frames
