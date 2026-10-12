extends Node
## GameSettings — toggles persistentes (som/música/vibração, reduzir efeitos,
## escala de texto, idioma). Persistido dentro do save principal.
## Autoload: GameSettings

const TEXT_SCALES := [100, 115, 130]

var sound_enabled := true
var music_enabled := true
var vibration_enabled := true
var reduce_fx := false
var text_scale_index := 0
var locale := "pt_BR"   # pt_BR | en

func to_dict() -> Dictionary:
	return {
		"sound": sound_enabled, "music": music_enabled, "vibration": vibration_enabled,
		"reduce_fx": reduce_fx, "text_scale": text_scale_index, "locale": locale,
	}

func from_dict(d: Dictionary) -> void:
	sound_enabled = d.get("sound", true)
	music_enabled = d.get("music", true)
	vibration_enabled = d.get("vibration", true)
	reduce_fx = d.get("reduce_fx", false)
	text_scale_index = clampi(int(d.get("text_scale", 0)), 0, TEXT_SCALES.size() - 1)
	locale = d.get("locale", "pt_BR")
	_apply()

func _apply() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not sound_enabled)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not music_enabled)

func set_sound(v: bool) -> void:
	sound_enabled = v
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not v)
	EventBus.sfx_changed.emit(v)

func set_music(v: bool) -> void:
	music_enabled = v
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not v)
	EventBus.music_changed.emit(v)

func set_vibration(v: bool) -> void:
	vibration_enabled = v
	EventBus.vibration_changed.emit(v)

func set_reduce_fx(v: bool) -> void:
	reduce_fx = v
	EventBus.reduce_fx_changed.emit(v)

func set_text_scale(i: int) -> void:
	text_scale_index = clampi(i, 0, TEXT_SCALES.size() - 1)
	EventBus.text_scale_changed.emit(TEXT_SCALES[text_scale_index])

func text_scale() -> int:
	return TEXT_SCALES[text_scale_index]
