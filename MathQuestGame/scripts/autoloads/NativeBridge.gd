extends Node
## NativeBridge - Android Native Integration Layer
## Provides interface to native Android features via GodotAndroidPlugin.
## Handles haptics, performance profiling, Play Games Services, and system dialogs.

class_name NativeBridgeClass

# ============================================================================
# SIGNALS
# ============================================================================

signal plugin_ready()
signal play_games_signed_in(player_name: String, player_id: String)
signal play_games_signed_out()
signal achievement_unlocked(achievement_id: String)
signal leaderboard_updated(leaderboard_id: String, score: int)
signal performance_data_received(cpu_usage: float, memory_mb: float, fps: float)

# ============================================================================
# CONSTANTS
# ============================================================================

const PLUGIN_NAME: String = "MathQuestPlugin"
const HAPTIC_PATTERN_LIGHT: String = "light"
const HAPTIC_PATTERN_MEDIUM: String = "medium"
const HAPTIC_PATTERN_HEAVY: String = "heavy"
const HAPTIC_PATTERN_SUCCESS: String = "success"
const HAPTIC_PATTERN_ERROR: String = "error"

# ============================================================================
# PROPERTIES
# ============================================================================

var _plugin_singleton: Object = null
var _is_plugin_available: bool = false
var _is_play_games_available: bool = false
var _performance_monitoring_enabled: bool = false
var _performance_update_interval: float = 2.0
var _performance_timer: float = 0.0

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	_initialize_plugin()

func _process(delta: float) -> void:
	if _performance_monitoring_enabled:
		_performance_timer += delta
		if _performance_timer >= _performance_update_interval:
			_performance_timer = 0.0
			_request_performance_data()

# ============================================================================
# PLUGIN INITIALIZATION
# ============================================================================

func _initialize_plugin() -> void:
	if Engine.has_singleton(PLUGIN_NAME):
		_plugin_singleton = Engine.get_singleton(PLUGIN_NAME)
		_is_plugin_available = true
		
		# Connect native signals if available
		if _plugin_singleton.has_signal("onPluginReady"):
			_plugin_singleton.onPluginReady.connect(_on_plugin_ready)
		if _plugin_singleton.has_signal("onPlayGamesSignedIn"):
			_plugin_singleton.onPlayGamesSignedIn.connect(_on_play_games_signed_in)
		if _plugin_singleton.has_signal("onPlayGamesSignedOut"):
			_plugin_singleton.onPlayGamesSignedOut.connect(_on_play_games_signed_out)
		if _plugin_singleton.has_signal("onAchievementUnlocked"):
			_plugin_singleton.onAchievementUnlocked.connect(_on_achievement_unlocked)
		if _plugin_singleton.has_signal("onPerformanceData"):
			_plugin_singleton.onPerformanceData.connect(_on_performance_data)
		
		plugin_ready.emit()
		print(f"[NativeBridge] Plugin '{PLUGIN_NAME}' initialized successfully")
	else:
		_is_plugin_available = false
		push_warning(f"[NativeBridge] Plugin '{PLUGIN_NAME}' not found. Running on desktop or plugin not loaded.")
		# Gracefully degrade - game will still function without native features

# ============================================================================
# HAPTIC FEEDBACK
# ============================================================================

func trigger_haptic(pattern: String = HAPTIC_PATTERN_LIGHT) -> void:
	if not _is_plugin_available:
		return
	
	match pattern:
		HAPTIC_PATTERN_LIGHT:
			_call_plugin_method("triggerHapticLight")
		HAPTIC_PATTERN_MEDIUM:
			_call_plugin_method("triggerHapticMedium")
		HAPTIC_PATTERN_HEAVY:
			_call_plugin_method("triggerHapticHeavy")
		HAPTIC_PATTERN_SUCCESS:
			_call_plugin_method("triggerHapticSuccess")
		HAPTIC_PATTERN_ERROR:
			_call_plugin_method("triggerHapticError")
		_:
			_call_plugin_method("triggerHapticLight")

func trigger_haptic_vibration(duration_ms: int) -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("triggerHapticVibration", [duration_ms])

func trigger_haptic_pattern(pattern_array: Array[int]) -> void:
	# pattern_array: alternating timings [off, on, off, on, ...] in milliseconds
	if not _is_plugin_available:
		return
	_call_plugin_method("triggerHapticPattern", [pattern_array])

# ============================================================================
# PLAY GAMES SERVICES
# ============================================================================

func sign_in_to_play_games() -> void:
	if not _is_plugin_available or not _is_play_games_available:
		return
	_call_plugin_method("signInToPlayGames")

func sign_out_from_play_games() -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("signOutFromPlayGames")

func is_play_games_connected() -> bool:
	if not _is_plugin_available:
		return false
	return _call_plugin_method_return_bool("isPlayGamesConnected", [], false)

func submit_score(leaderboard_id: String, score: int) -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("submitScore", [leaderboard_id, score])

func unlock_achievement(achievement_id: String) -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("unlockAchievement", [achievement_id])

func show_leaderboard(leaderboard_id: String) -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("showLeaderboard", [leaderboard_id])

func show_achievements() -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("showAchievements")

# ============================================================================
# PERFORMANCE MONITORING
# ============================================================================

func enable_performance_monitoring(enabled: bool) -> void:
	_performance_monitoring_enabled = enabled
	if enabled and _is_plugin_available:
		_call_plugin_method("startPerformanceMonitoring")

func disable_performance_monitoring() -> void:
	_performance_monitoring_enabled = false
	if _is_plugin_available:
		_call_plugin_method("stopPerformanceMonitoring")

func _request_performance_data() -> void:
	if _is_plugin_available:
		_call_plugin_method("requestPerformanceData")

func _on_performance_data(data: Dictionary) -> void:
	var cpu: float = data.get("cpuUsage", 0.0)
	var memory: float = data.get("memoryMB", 0.0)
	var fps: float = data.get("fps", 0.0)
	performance_data_received.emit(cpu, memory, fps)
	
	# Log warnings for performance issues
	if cpu > 80.0:
		push_warning(f"[NativeBridge] High CPU usage detected: {cpu:.1f}%")
	if memory > 500.0:  # 500MB threshold
		push_warning(f"[NativeBridge] High memory usage detected: {memory:.1f}MB")

# ============================================================================
# SYSTEM DIALOGS & NATIVE UI
# ============================================================================

func show_native_toast(message: String) -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("showToast", [message])

func show_rate_app_dialog() -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("showRateAppDialog")

func share_to_social_media(title: String, text: String, url: String = "") -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("shareToSocialMedia", [title, text, url])

# ============================================================================
# DEVICE INFORMATION
# ============================================================================

func get_device_info() -> Dictionary:
	if not _is_plugin_available:
		return {}
	return _call_plugin_method_return_dict("getDeviceInfo", [], {})

func get_battery_level() -> int:
	if not _is_plugin_available:
		return -1
	return _call_plugin_method_return_int("getBatteryLevel", [], -1)

func is_charging() -> bool:
	if not _is_plugin_available:
		return false
	return _call_plugin_method_return_bool("isCharging", [], false)

func get_network_type() -> String:
	if not _is_plugin_available:
		return "unknown"
	return _call_plugin_method_return_string("getNetworkType", [], "unknown")

# ============================================================================
# ANALYTICS EVENTS (Firebase/Crashlytics preparation)
# ============================================================================

func log_analytics_event(event_name: String, parameters: Dictionary) -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("logAnalyticsEvent", [event_name, parameters])

func log_screen_view(screen_name: String) -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("logScreenView", [screen_name])

func log_error(error_code: String, message: String, stack_trace: String = "") -> void:
	if not _is_plugin_available:
		return
	_call_plugin_method("logError", [error_code, message, stack_trace])

# ============================================================================
# UTILITY METHODS
# ============================================================================

func _call_plugin_method(method_name: String, args: Array = []) -> void:
	if _plugin_singleton and _plugin_singleton.has_method(method_name):
		match len(args):
			0: _plugin_singleton.call(method_name)
			1: _plugin_singleton.call(method_name, args[0])
			2: _plugin_singleton.call(method_name, args[0], args[1])
			3: _plugin_singleton.call(method_name, args[0], args[1], args[2])
			_: push_error(f"[NativeBridge] Method {method_name} called with unsupported argument count")
	else:
		push_warning(f"[NativeBridge] Method {method_name} not found on plugin")

func _call_plugin_method_return_bool(method_name: String, args: Array, default_value: bool) -> bool:
	if _plugin_singleton and _plugin_singleton.has_method(method_name):
		var result = _plugin_singleton.call(method_name) if len(args) == 0 else _plugin_singleton.callv(method_name, args)
		return result if typeof(result) == TYPE_BOOL else default_value
	return default_value

func _call_plugin_method_return_int(method_name: String, args: Array, default_value: int) -> int:
	if _plugin_singleton and _plugin_singleton.has_method(method_name):
		var result = _plugin_singleton.call(method_name) if len(args) == 0 else _plugin_singleton.callv(method_name, args)
		return result if typeof(result) == TYPE_INT else default_value
	return default_value

func _call_plugin_method_return_string(method_name: String, args: Array, default_value: String) -> String:
	if _plugin_singleton and _plugin_singleton.has_method(method_name):
		var result = _plugin_singleton.call(method_name) if len(args) == 0 else _plugin_singleton.callv(method_name, args)
		return result if typeof(result) == TYPE_STRING else default_value
	return default_value

func _call_plugin_method_return_dict(method_name: String, args: Array, default_value: Dictionary) -> Dictionary:
	if _plugin_singleton and _plugin_singleton.has_method(method_name):
		var result = _plugin_singleton.call(method_name) if len(args) == 0 else _plugin_singleton.callv(method_name, args)
		return result if typeof(result) == TYPE_DICTIONARY else default_value
	return default_value

# ============================================================================
# NATIVE SIGNAL HANDLERS
# ============================================================================

func _on_plugin_ready() -> void:
	print("[NativeBridge] Native plugin ready")

func _on_play_games_signed_in(player_name: String, player_id: String) -> void:
	_is_play_games_available = true
	play_games_signed_in.emit(player_name, player_id)
	print(f"[NativeBridge] Play Games signed in: {player_name} ({player_id})")

func _on_play_games_signed_out() -> void:
	_is_play_games_available = false
	play_games_signed_out.emit()
	print("[NativeBridge] Play Games signed out")

func _on_achievement_unlocked(achievement_id: String) -> void:
	achievement_unlocked.emit(achievement_id)
	print(f"[NativeBridge] Achievement unlocked: {achievement_id}")

# ============================================================================
# DEBUG & DIAGNOSTICS
# ============================================================================

func get_plugin_status() -> Dictionary:
	return {
		"plugin_available": _is_plugin_available,
		"play_games_available": _is_play_games_available,
		"performance_monitoring": _performance_monitoring_enabled,
		"plugin_singleton_exists": _plugin_singleton != null,
		"running_on_android": OS.get_name() == "Android"
	}

func print_plugin_debug() -> void:
	print("=== NATIVE BRIDGE DEBUG ===")
	var status: Dictionary = get_plugin_status()
	for key in status:
		print(f"  {key}: {status[key]}")
	print("===========================")
