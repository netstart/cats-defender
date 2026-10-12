extends Node
## AudioManager — buses Master > Music/SFX/UI, limite de vozes por SFX (M22),
## pitch ±5%, cache de streams, pooling de players.
## Autoload: AudioManager

const MAX_PLAYERS := 16
const VOICE_LIMIT := 4
const PITCH_VAR := 0.05
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

var _players: Array[AudioStreamPlayer] = []
var _active_counts: Dictionary = {}
var _music: AudioStreamPlayer = null
var _cache: Dictionary = {}
var _sfx_rng := RandomNumberGenerator.new()

func _ready() -> void:
	_sfx_rng.seed = 0xA0D10
	for i in MAX_PLAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.autoplay = false
	if _music.finished.is_connected(_on_music_finished) == false:
		_music.finished.connect(_on_music_finished)
	add_child(_music)
	ensure_buses()

func ensure_buses() -> void:
	# Garante buses SFX/UI/Music mesmo sem default_bus_layout personalizado.
	for b in ["SFX", "UI", "Music"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, "Master")

func _load_stream(name: String, dir: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	for ext in ["wav", "ogg", "mp3"]:
		var p: String = dir + name + "." + ext
		if ResourceLoader.exists(p):
			var s: AudioStream = load(p)
			if s is AudioStreamOggVorbis:
				s.loop = false
			_cache[name] = s
			return s
	return null

func play_sfx(name: String, bus := "SFX", volume_db := 0.0) -> void:
	if GameSettings and not GameSettings.sound_enabled:
		return
	var stream: AudioStream = _load_stream(name, SFX_DIR)
	if stream == null:
		return
	var count: int = int(_active_counts.get(name, 0))
	if count >= VOICE_LIMIT:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.bus = bus
			p.volume_db = volume_db
			p.pitch_scale = 1.0 + _sfx_rng.randf_range(-PITCH_VAR, PITCH_VAR)
			_active_counts[name] = count + 1
			p.finished.connect(_on_sfx_finished.bind(name), CONNECT_ONE_SHOT)
			p.play()
			return

func _on_sfx_finished(name: String) -> void:
	_active_counts[name] = maxi(0, int(_active_counts.get(name, 1)) - 1)

func play_ui(name: String) -> void:
	play_sfx(name, "UI")

func play_music(name: String, volume_db := -6.0) -> void:
	var stream: AudioStream = _load_stream(name, MUSIC_DIR)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music.stream = stream
	_music.volume_db = volume_db
	if GameSettings and GameSettings.music_enabled:
		_music.play()

func stop_music() -> void:
	_music.stop()

func duck_music(on: bool) -> void:
	if _music.stream == null:
		return
	var tw := create_tween()
	tw.tween_property(_music, "volume_db", -18.0 if on else -6.0, 0.4)

func _on_music_finished() -> void:
	if _music.stream and _music.stream is AudioStreamOggVorbis and _music.stream.loop:
		_music.play()

func pause_all(on: bool) -> void:
	for p in _players:
		if on:
			p.stream_paused = true
		else:
			p.stream_paused = false
	_music.stream_paused = on
