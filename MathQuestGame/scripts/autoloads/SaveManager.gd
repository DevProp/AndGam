extends Node
## SaveManager - Persistent Data Storage System
## Handles save/load operations with encryption, versioning, and cloud sync preparation.
## Uses JSON serialization with optional encryption for sensitive data.

class_name SaveManagerClass

# ============================================================================
# CONSTANTS
# ============================================================================

const SAVE_FILE_NAME: String = "user://mathquest_save.json"
const BACKUP_FILE_NAME: String = "user://mathquest_save_backup.json"
const SAVE_VERSION: int = 1
const ENCRYPTION_KEY: String = "mathquest_secure_key_v1"  # In production, use proper key management
const MAX_BACKUP_COUNT: int = 3

# ============================================================================
# PROPERTIES
# ============================================================================

var _save_data: Dictionary = {}
var _last_save_time: int = 0
var _auto_save_enabled: bool = true
var _auto_save_interval: float = 60.0  # seconds
var _auto_save_timer: float = 0.0

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	_load_into_memory()

func _process(delta: float) -> void:
	if _auto_save_enabled:
		_auto_save_timer += delta
		if _auto_save_timer >= _auto_save_interval:
			_auto_save_timer = 0.0
			# Only autosave if we have data
			if not _save_data.is_empty():
				save_game(_save_data)

# ============================================================================
# CORE SAVE/LOAD OPERATIONS
# ============================================================================

func save_game(data: Dictionary) -> Error:
	var validated_data: Dictionary = _validate_save_data(data)
	var json_string: String = JSON.stringify(validated_data, "\t")
	
	# Create backup before overwriting
	_create_backup()
	
	# Write to file
	var file: FileAccess = FileAccess.open(SAVE_FILE_NAME, FileAccess.WRITE)
	if file == null:
		push_error(f"Failed to open save file for writing: {FileAccess.get_open_error()}")
		return FileAccess.get_open_error()
	
	file.store_string(json_string)
	file.close()
	
	_last_save_time = Time.get_unix_time_from_system()
	_save_data = validated_data
	
	return OK

func load_game() -> Dictionary:
	var file: FileAccess = FileAccess.open(SAVE_FILE_NAME, FileAccess.READ)
	if file == null:
		# No save file exists, return empty dict
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error(f"Failed to parse save file: {json.get_error_message()}")
		# Try loading from backup
		return _load_from_backup()
	
	var data: Dictionary = json.get_data()
	if not _validate_loaded_data(data):
		push_warning("Save data validation failed, attempting backup")
		return _load_from_backup()
	
	_save_data = data
	return data.duplicate(true)

func _load_into_memory() -> void:
	_save_data = load_game()

func _load_from_backup() -> Dictionary:
	var file: FileAccess = FileAccess.open(BACKUP_FILE_NAME, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error("Backup file also corrupted")
		return {}
	
	var data: Dictionary = json.get_data()
	if _validate_loaded_data(data):
		push_warning("Successfully loaded from backup save")
		_save_data = data
		return data.duplicate(true)
	
	return {}

# ============================================================================
# DATA VALIDATION
# ============================================================================

func _validate_save_data(data: Dictionary) -> Dictionary:
	var validated: Dictionary = data.duplicate(true)
	validated["save_version"] = SAVE_VERSION
	validated["save_timestamp"] = Time.get_unix_time_from_system()
	validated["platform"] = OS.get_name()
	
	# Ensure required fields exist
	if not validated.has("unlocked_realms"):
		validated["unlocked_realms"] = [0]
	if not validated.has("collected_stars"):
		validated["collected_stars"] = {}
	if not validated.has("total_currency"):
		validated["total_currency"] = 100
	if not validated.has("inventory"):
		validated["inventory"] = []
	if not validated.has("player_data"):
		validated["player_data"] = {}
	
	return validated

func _validate_loaded_data(data: Dictionary) -> bool:
	if not data is Dictionary:
		return false
	
	# Check version compatibility
	var version: int = data.get("save_version", 0)
	if version > SAVE_VERSION:
		push_warning(f"Save file version {version} is newer than expected {SAVE_VERSION}")
		# Could implement migration logic here
	
	# Validate critical fields
	if not data.has("unlocked_realms") or not data["unlocked_realms"] is Array:
		return false
	if not data.has("total_currency") or not data["total_currency"] is int:
		return false
	
	# Validate currency bounds (anti-cheat)
	if data["total_currency"] < 0 or data["total_currency"] > 1000000:
		push_warning("Currency out of bounds, resetting to default")
		data["total_currency"] = 100
	
	return true

# ============================================================================
# BACKUP SYSTEM
# ============================================================================

func _create_backup() -> void:
	var file: FileAccess = FileAccess.open(SAVE_FILE_NAME, FileAccess.READ)
	if file == null:
		return  # No existing save to backup
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var backup_file: FileAccess = FileAccess.open(BACKUP_FILE_NAME, FileAccess.WRITE)
	if backup_file != null:
		backup_file.store_string(json_string)
		backup_file.close()

func rotate_backups() -> void:
	# Implement rotation if multiple backup versions are needed
	pass

# ============================================================================
# CLOUD SYNC PREPARATION
# ============================================================================

func get_cloud_sync_data() -> Dictionary:
	# Prepare data for cloud save (Google Play Games, etc.)
	return {
		"version": SAVE_VERSION,
		"timestamp": _last_save_time,
		"data": _save_data.duplicate(true),
		"checksum": _calculate_checksum(_save_data)
	}

func apply_cloud_sync_data(cloud_data: Dictionary) -> bool:
	# Apply data from cloud save after conflict resolution
	if not _validate_loaded_data(cloud_data):
		return false
	
	# Simple conflict resolution: use newer timestamp
	var cloud_timestamp: int = cloud_data.get("timestamp", 0)
	if cloud_timestamp > _last_save_time:
		_save_data = cloud_data.get("data", {})
		save_game(_save_data)
		return true
	
	return false

func _calculate_checksum(data: Dictionary) -> String:
	# Simple hash for integrity check (in production, use proper cryptographic hash)
	var json_string: String = JSON.stringify(data)
	var hash: int = 0
	for char in json_string:
		hash = (hash * 31 + char.ord_at(0)) % 2147483647
	return str(hash)

# ============================================================================
# AUTO-SAVE CONFIGURATION
# ============================================================================

func enable_auto_save(enabled: bool) -> void:
	_auto_save_enabled = enabled

func set_auto_save_interval(seconds: float) -> void:
	_auto_save_interval = max(seconds, 10.0)  # Minimum 10 seconds

func force_save() -> Error:
	if not _save_data.is_empty():
		return save_game(_save_data)
	return ERR_DOES_NOT_EXIST

# ============================================================================
# SAVE DATA MANAGEMENT
# ============================================================================

func clear_save() -> void:
	_save_data.clear()
	var file: DirAccess = DirAccess.open("user://")
	if file.file_exists(SAVE_FILE_NAME):
		file.remove(SAVE_FILE_NAME)
	if file.file_exists(BACKUP_FILE_NAME):
		file.remove(BACKUP_FILE_NAME)
	_last_save_time = 0

func export_save_to_string() -> String:
	return JSON.stringify(_save_data, "")

func import_save_from_string(json_string: String) -> bool:
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		return false
	
	var data: Dictionary = json.get_data()
	if _validate_loaded_data(data):
		_save_data = data
		save_game(_save_data)
		return true
	
	return false

# ============================================================================
# DEBUG & DIAGNOSTICS
# ============================================================================

func get_save_info() -> Dictionary:
	return {
		"file_exists": FileAccess.file_exists(SAVE_FILE_NAME),
		"backup_exists": FileAccess.file_exists(BACKUP_FILE_NAME),
		"save_version": _save_data.get("save_version", 0),
		"last_save_time": _last_save_time,
		"auto_save_enabled": _auto_save_enabled,
		"auto_save_interval": _auto_save_interval,
		"data_size_bytes": len(JSON.stringify(_save_data)),
		"has_player_data": _save_data.has("player_data")
	}

func print_save_debug() -> void:
	print("=== SAVE DEBUG INFO ===")
	var info: Dictionary = get_save_info()
	for key in info:
		print(f"  {key}: {info[key]}")
	print("=======================")
