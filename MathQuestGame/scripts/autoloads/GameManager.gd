extends Node
## GameManager - Core Game State Controller
## Manages game flow, scene transitions, realm progression, and player state persistence.
## Implements singleton pattern via autoload for global access.

class_name GameManagerClass

# ============================================================================
# SIGNALS
# ============================================================================

signal realm_completed(realm_id: int, stars_earned: int)
signal player_died()
signal game_paused(is_paused: bool)
signal currency_changed(amount: int, currency_type: String)
signal inventory_updated(item_id: String)

# ============================================================================
# ENUMS & CONSTANTS
# ============================================================================

enum GameState {
	LOADING,
	MENU,
	HUB,
	REALM_ACTIVE,
	TRANSITION,
	PAUSED,
	GAME_OVER
}

enum RealmID {
	NONE = -1,
	ISLE_OF_PATTERNS = 0,
	COSMIC_GEARS = 1,
	OASIS_OF_BALANCE = 2,
	CITADEL_OF_FLUIDS = 3,
	LABYRINTH_OF_NETWORKS = 4
}

const MAX_STARS_PER_REALM: int = 3
const INITIAL_CURRENCY: int = 100

# ============================================================================
# PROPERTIES
# ============================================================================

var current_state: GameState = GameState.LOADING:
	set(value):
		current_state = value
		_on_state_changed(value)

var current_realm: RealmID = RealmID.NONE
var total_currency: int = INITIAL_CURRENCY
var unlocked_realms: Array[int] = [0]  # Start with first realm unlocked
var collected_stars: Dictionary = {}  # {realm_id: star_count}
var inventory: Array[String] = []  # Collected cosmetic items/upgrades
var player_data: Dictionary = {}  # Persistent player statistics

var _scene_tree: SceneTree
var _current_scene: Node3D

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	_scene_tree = get_tree()
	_initialize_player_data()
	_load_progress()
	current_state = GameState.MENU

func _initialize_player_data() -> void:
	player_data = {
		"total_playtime": 0.0,
		"puzzles_solved": 0,
		"total_attempts": 0,
		"hint_usage": 0,
		"average_solve_time": 0.0,
		"mistake_rate": 0.0,
		"first_login": Time.get_unix_time_from_system()
	}

# ============================================================================
# SCENE MANAGEMENT
# ============================================================================

func change_scene(scene_path: String) -> Error:
	if not ResourceLoader.exists(scene_path):
		push_error(f"Scene not found: {scene_path}")
		return ERR_FILE_NOT_FOUND
	
	var err: Error = _scene_tree.change_scene_to_file(scene_path)
	if err == OK:
		await _scene_tree.process_frame
		_current_scene = _scene_tree.current_scene
	return err

func transition_to_realm(realm: RealmID) -> void:
	if current_state == GameState.REALM_ACTIVE:
		return
	
	current_state = GameState.TRANSITION
	current_realm = realm
	
	var scene_paths: Dictionary = {
		RealmID.ISLE_OF_PATTERNS: "res://scenes/realms/stage1_isle/Stage1Isle.tscn",
		RealmID.COSMIC_GEARS: "res://scenes/realms/stage2_cosmic/Stage2Cosmic.tscn",
		RealmID.OASIS_OF_BALANCE: "res://scenes/realms/stage3_oasis/Stage3Oasis.tscn",
		RealmID.CITADEL_OF_FLUIDS: "res://scenes/realms/stage4_citadel/Stage4Citadel.tscn",
		RealmID.LABYRINTH_OF_NETWORKS: "res://scenes/realms/stage5_labyrinth/Stage5Labyrinth.tscn"
	}
	
	if scene_paths.has(realm):
		await change_scene(scene_paths[realm])
		current_state = GameState.REALM_ACTIVE

func return_to_hub() -> void:
	current_state = GameState.TRANSITION
	await change_scene("res://scenes/hub/SkyBaseHub.tscn")
	current_state = GameState.HUB

# ============================================================================
# PROGRESSION SYSTEM
# ============================================================================

func complete_realm(realm: RealmID, stars: int) -> void:
	stars = clamp(stars, 0, MAX_STARS_PER_REALM)
	collected_stars[realm] = max(collected_stars.get(realm, 0), stars)
	
	# Unlock next realm if this is the current sequential one
	if realm == len(unlocked_realms) - 1 and realm < RealmID.size() - 1:
		unlocked_realms.append(realm + 1)
	
	realm_completed.emit(realm, stars)
	_save_progress()

func is_realm_unlocked(realm: RealmID) -> bool:
	return unlocked_realms.has(realm)

func get_stars_for_realm(realm: RealmID) -> int:
	return collected_stars.get(realm, 0)

func get_total_stars() -> int:
	var total: int = 0
	for stars in collected_stars.values():
		total += stars
	return total

# ============================================================================
# CURRENCY & INVENTORY
# ============================================================================

func add_currency(amount: int, currency_type: String = "coins") -> void:
	if amount > 0:
		total_currency += amount
		currency_changed.emit(amount, currency_type)
		_save_progress()

func spend_currency(amount: int, currency_type: String = "coins") -> bool:
	if total_currency >= amount:
		total_currency -= amount
		currency_changed.emit(-amount, currency_type)
		_save_progress()
		return true
	return false

func add_to_inventory(item_id: String) -> void:
	if not inventory.has(item_id):
		inventory.append(item_id)
		inventory_updated.emit(item_id)
		_save_progress()

func has_item(item_id: String) -> bool:
	return inventory.has(item_id)

# ============================================================================
# TELEMETRY & DIFFICULTY ADAPTATION
# ============================================================================

func record_puzzle_attempt(puzzle_id: String, solved: bool, time_taken: float, hints_used: int) -> void:
	player_data["total_attempts"] += 1
	if solved:
		player_data["puzzles_solved"] += 1
	
	# Update average solve time (exponential moving average)
	var old_avg: float = player_data["average_solve_time"]
	player_data["average_solve_time"] = old_avg * 0.9 + time_taken * 0.1
	
	# Update mistake rate
	player_data["mistake_rate"] = float(player_data["total_attempts"] - player_data["puzzles_solved"]) / player_data["total_attempts"]
	
	player_data["hint_usage"] += hints_used
	
	# Notify difficulty manager for adaptive adjustment
	DifficultyManager.record_performance(puzzle_id, solved, time_taken, hints_used)

func update_playtime(delta: float) -> void:
	player_data["total_playtime"] += delta

# ============================================================================
# SAVE/LOAD SYSTEM
# ============================================================================

func _save_progress() -> void:
	SaveManager.save_game(get_save_data())

func _load_progress() -> void:
	var save_data: Dictionary = SaveManager.load_game()
	if not save_data.is_empty():
		load_save_data(save_data)

func get_save_data() -> Dictionary:
	return {
		"version": 1,
		"unlocked_realms": unlocked_realms,
		"collected_stars": collected_stars,
		"total_currency": total_currency,
		"inventory": inventory,
		"player_data": player_data,
		"timestamp": Time.get_unix_time_from_system()
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("unlocked_realms"):
		unlocked_realms = data["unlocked_realms"]
	if data.has("collected_stars"):
		collected_stars = data["collected_stars"]
	if data.has("total_currency"):
		total_currency = data["total_currency"]
	if data.has("inventory"):
		inventory = data["inventory"]
	if data.has("player_data"):
		player_data = data["player_data"]

# ============================================================================
# STATE CALLBACKS
# ============================================================================

func _on_state_changed(new_state: GameState) -> void:
	match new_state:
		GameState.PAUSED:
			game_paused.emit(true)
			_scene_tree.paused = true
		GameState.GAME_OVER:
			game_paused.emit(true)
		_:
			if current_state != GameState.PAUSED:
				game_paused.emit(false)
				_scene_tree.paused = false

func pause_game() -> void:
	if current_state == GameState.REALM_ACTIVE or current_state == GameState.HUB:
		current_state = GameState.PAUSED

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.REALM_ACTIVE if current_realm != RealmID.NONE else GameState.HUB

func quit_game() -> void:
	_save_progress()
	_scene_tree.quit()
