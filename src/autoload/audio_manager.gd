extends Node
## AudioManager: música dinâmica + SFX com pool de 16 players, pitch ±8%,
## buses Master/Music/SFX e volumes persistentes (settings).
## SFX são WAVs procedurais gerados por tools/build_audio.py (CC0).

const POOL_SIZE := 16
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _sfx_cache: Dictionary = {}  # StringName -> AudioStream

func _ready() -> void:
	_ensure_buses()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	add_child(_music)
	_apply_saved_volumes()

func _ensure_buses() -> void:
	for bus in [&"Music", &"SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.get_bus_index(bus), &"Master")

func play_sfx_id(id: StringName, pitch := 1.0) -> void:
	if not _sfx_cache.has(id):
		var path := "%s%s.wav" % [SFX_DIR, id]
		if not ResourceLoader.exists(path):
			return
		_sfx_cache[id] = load(path)
	play_sfx(_sfx_cache[id], pitch)

func play_sfx(stream: AudioStream, pitch := 1.0) -> void:
	if stream == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = clampf(pitch, 0.8, 1.2)
			p.play()
			return

## Música de menu/batalha com duck quando jogo pausa.
func play_music(track: StringName) -> void:
	var path := "%s%s.wav" % [MUSIC_DIR, track]
	if not ResourceLoader.exists(path):
		return
	_music.stream = load(path)
	_music.play()

func stop_music() -> void:
	_music.stop()

func duck_music(enabled: bool) -> void:
	var idx := AudioServer.get_bus_index(&"Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, -10.0 if enabled else 0.0)

func set_bus_volume(bus: StringName, volume_0_to_1: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(volume_0_to_1, 0.001, 1.0)))

func get_bus_volume(bus: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx >= 0 else 1.0

func _apply_saved_volumes() -> void:
	var data: Dictionary = SaveManager.load_game()
	var settings: Dictionary = data.get("settings", {})
	for bus in [&"Master", &"Music", &"SFX"]:
		if settings.has(bus):
			set_bus_volume(bus, float(settings[bus]))

func vibrate_light() -> void:
	# Haptics: Android Vibrate API (no-op em desktop/editor)
	if OS.has_feature("android"):
		Input.vibrate_handheld(40)
