extends Node
## AudioManager - Centralized Audio System
## Manages music, SFX, and ambient audio with pooling and crossfading.
## Optimized for mobile with voice limiting and resource management.

class_name AudioManagerClass

# ============================================================================
# SIGNALS
# ============================================================================

signal music_track_changed(track_name: String)
signal volume_changed(bus_index: int, volume_db: float)

# ============================================================================
# CONSTANTS
# ============================================================================

const MAX_CONCURRENT_SFX: int = 8
const MUSIC_FADE_DURATION: float = 1.5
const SFX_VOLUME_DEFAULT: float = -3.0
const MUSIC_VOLUME_DEFAULT: float = -6.0
const AMBIENT_VOLUME_DEFAULT: float = -12.0

enum AudioBus {
	MASTER = 0,
	MUSIC = 1,
	SFX = 2,
	AMBIENT = 3
}

# ============================================================================
# PROPERTIES
# ============================================================================

@export_group("Audio Buses")
@export var music_bus_name: String = "Music"
@export var sfx_bus_name: String = "SFX"
@export var ambient_bus_name: String = "Ambient"

var _music_players: Array[AudioStreamPlayer] = []
var _sfx_pool: Array[AudioStreamPlayer] = []
var _ambient_player: AudioStreamPlayer
var _current_music_index: int = 0
var _is_muted: Dictionary = {}  # {bus_index: bool}

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	_setup_audio_buses()
	_create_audio_players()
	_initialize_volume()

func _setup_audio_buses() -> void:
	# Ensure buses exist (created in Godot's Audio bus layout)
	var master_bus_idx: int = AudioServer.get_bus_index("Master")
	if master_bus_idx == -1:
		push_warning("Master audio bus not found. Check Audio bus layout.")

func _create_audio_players() -> void:
	# Create two music players for crossfading
	for i in range(2):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = music_bus_name
		add_child(player)
		_music_players.append(player)
	
	# Create ambient player
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = ambient_bus_name
	_ambient_player.volume_db = AMBIENT_VOLUME_DEFAULT
	add_child(_ambient_player)
	
	# Create SFX pool
	for i in range(MAX_CONCURRENT_SFX):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = sfx_bus_name
		add_child(player)
		_sfx_pool.append(player)

func _initialize_volume() -> void:
	set_bus_volume(AudioBus.MUSIC, MUSIC_VOLUME_DEFAULT)
	set_bus_volume(AudioBus.SFX, SFX_VOLUME_DEFAULT)
	set_bus_volume(AudioBus.AMBIENT, AMBIENT_VOLUME_DEFAULT)

# ============================================================================
# MUSIC CONTROL
# ============================================================================

func play_music(stream: AudioStream, fade_in: bool = true) -> void:
	if stream == null:
		push_warning("Attempted to play null music stream")
		return
	
	var current_player: AudioStreamPlayer = _music_players[_current_music_index]
	var next_player: AudioStreamPlayer = _music_players[1 - _current_music_index]
	
	# Stop current music with fade out if playing
	if current_player.playing:
		await _fade_out(current_player, MUSIC_FADE_DURATION / 2.0)
		current_player.stop()
	
	# Load new track
	next_player.stream = stream
	next_player.volume_db = -INF if fade_in else get_bus_volume(AudioBus.MUSIC)
	next_player.play()
	
	# Fade in
	if fade_in:
		await _fade_in(next_player, MUSIC_FADE_DURATION / 2.0)
	
	_current_music_index = 1 - _current_music_index
	music_track_changed.emit(stream.resource_path.get_file())

func stop_music(fade_out_duration: float = MUSIC_FADE_DURATION) -> void:
	var player: AudioStreamPlayer = _music_players[_current_music_index]
	if player.playing:
		await _fade_out(player, fade_out_duration)
		player.stop()

func is_music_playing() -> bool:
	return _music_players[_current_music_index].playing

# ============================================================================
# SFX CONTROL
# ============================================================================

func play_sfx(stream: AudioStream, volume_db: float = SFX_VOLUME_DEFAULT, pitch: float = 1.0) -> void:
	if stream == null:
		return
	
	# Find available player from pool
	var player: AudioStreamPlayer = _get_available_sfx_player()
	if player == null:
		push_warning("SFX pool exhausted, dropping sound")
		return
	
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

func play_sfx_3d(stream: AudioStream, position: Vector3, volume_db: float = SFX_VOLUME_DEFAULT) -> void:
	if stream == null:
		return
	
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.bus = sfx_bus_name
	player.stream = stream
	player.volume_db = volume_db
	player.global_position = position
	add_child(player)
	player.play()
	
	# Auto cleanup after playback
	await player.finished
	player.queue_free()

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return null

# ============================================================================
# AMBIENT SOUND
# ============================================================================

func play_ambient(stream: AudioStream, loop: bool = true) -> void:
	if stream == null:
		return
	
	_ambient_player.stream = stream
	_ambient_player.loop = loop
	_ambient_player.play()

func stop_ambient(fade_duration: float = 1.0) -> void:
	if _ambient_player.playing:
		await _fade_out(_ambient_player, fade_duration)
		_ambient_player.stop()

func set_ambient_volume(volume_db: float) -> void:
	_ambient_player.volume_db = volume_db

# ============================================================================
# VOLUME CONTROL
# ============================================================================

func set_bus_volume(bus: AudioBus, volume_db: float) -> void:
	var bus_name: String = ""
	match bus:
		AudioBus.MUSIC: bus_name = music_bus_name
		AudioBus.SFX: bus_name = sfx_bus_name
		AudioBus.AMBIENT: bus_name = ambient_bus_name
	
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, volume_db)
		volume_changed.emit(bus, volume_db)

func get_bus_volume(bus: AudioBus) -> float:
	var bus_name: String = ""
	match bus:
		AudioBus.MUSIC: bus_name = music_bus_name
		AudioBus.SFX: bus_name = sfx_bus_name
		AudioBus.AMBIENT: bus_name = ambient_bus_name
	
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return AudioServer.get_bus_volume_db(bus_idx)
	return -INF

func mute_bus(bus: AudioBus, muted: bool) -> void:
	_is_muted[bus] = muted
	var bus_name: String = ""
	match bus:
		AudioBus.MUSIC: bus_name = music_bus_name
		AudioBus.SFX: bus_name = sfx_bus_name
		AudioBus.AMBIENT: bus_name = ambient_bus_name
	
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, muted)

func is_bus_muted(bus: AudioBus) -> bool:
	return _is_muted.get(bus, false)

func set_master_volume(volume_db: float) -> void:
	var master_idx: int = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_volume_db(master_idx, volume_db)

# ============================================================================
# NATIVE BRIDGE INTEGRATION
# ============================================================================

func trigger_haptic_feedback(pattern: String = "light") -> void:
	# Delegate to native Android haptics via NativeBridge
	if NativeBridge:
		NativeBridge.trigger_haptic(pattern)

# ============================================================================
# FADE UTILITIES
# ============================================================================

func _fade_in(player: AudioStreamPlayer, duration: float) -> void:
	var target_volume: float = get_bus_volume(AudioBus.MUSIC) if player.bus == music_bus_name else SFX_VOLUME_DEFAULT
	player.volume_db = -INF
	player.play()
	
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", target_volume, duration)
	await tween.finished

func _fade_out(player: AudioStreamPlayer, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", -INF, duration)
	await tween.finished

# ============================================================================
# CLEANUP
# ============================================================================

func stop_all() -> void:
	for player in _music_players:
		player.stop()
	for player in _sfx_pool:
		player.stop()
	_ambient_player.stop()

func _exit_tree() -> void:
	stop_all()
