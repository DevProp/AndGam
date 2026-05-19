extends Node
## DifficultyManager - Dynamic Difficulty Adjustment (DDA) Engine
## Analyzes player performance metrics and adjusts mathematical parameters invisibly.
## Implements rolling averages, trend detection, and scaffolding systems.

class_name DifficultyManagerClass

# ============================================================================
# SIGNALS
# ============================================================================

signal difficulty_adjusted(puzzle_id: String, new_difficulty: float)
signal hint_recommended(puzzle_id: String, hint_type: String)

# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

const DIFFICULTY_MIN: float = 0.0
const DIFFICULTY_MAX: float = 1.0
const DEFAULT_DIFFICULTY: float = 0.5
const ADJUSTMENT_THRESHOLD: float = 0.15  # Minimum change to trigger adjustment

# Performance metric weights for difficulty calculation
const WEIGHT_SOLVE_TIME: float = 0.35
const WEIGHT_MISTAKE_RATE: float = 0.40
const WEIGHT_HINT_DEPENDENCY: float = 0.25

# Rolling window sizes for metrics
const ROLLING_WINDOW_SIZE: int = 10  # Last N puzzles for average calculation

# Target performance zones (ideal player experience)
const TARGET_SOLVE_TIME_SECONDS: float = 45.0
const TARGET_SUCCESS_RATE: float = 0.75  # 75% success rate ideal
const TARGET_HINT_USAGE: float = 0.30  # Hints on 30% of puzzles max

# ============================================================================
# ENUMS
# ============================================================================

enum DifficultyTier {
	VERY_EASY,    # 0.0 - 0.2
	EASY,         # 0.2 - 0.4
	MEDIUM,       # 0.4 - 0.6
	HARD,         # 0.6 - 0.8
	VERY_HARD     # 0.8 - 1.0
}

# ============================================================================
# PROPERTIES
# ============================================================================

# Global difficulty level (0.0 = easiest, 1.0 = hardest)
var global_difficulty: float = DEFAULT_DIFFICULTY

# Per-puzzle difficulty overrides
var puzzle_difficulties: Dictionary = {}  # {puzzle_id: difficulty}

# Performance tracking
var _performance_history: Array[Dictionary] = []  # Rolling window of recent performances
var _puzzle_specific_history: Dictionary = {}  # {puzzle_id: [performances]}

# Configuration per realm
var _realm_configs: Dictionary = {
	GameManager.RealmID.ISLE_OF_PATTERNS: {
		"base_number_range": [1, 10],
		"time_multiplier": 1.2,
		"visual_complexity": 0.3
	},
	GameManager.RealmID.COSMIC_GEARS: {
		"base_number_range": [1, 20],
		"time_multiplier": 1.1,
		"visual_complexity": 0.5
	},
	GameManager.RealmID.OASIS_OF_BALANCE: {
		"base_number_range": [2, 15],
		"time_multiplier": 1.0,
		"visual_complexity": 0.5,
		"variable_complexity": 1  # Number of X variables
	},
	GameManager.RealmID.CITADEL_OF_FLUIDS: {
		"base_number_range": [5, 25],
		"time_multiplier": 0.9,
		"visual_complexity": 0.7
	},
	GameManager.RealmID.LABYRINTH_OF_NETWORKS: {
		"base_number_range": [10, 50],
		"time_multiplier": 0.8,
		"visual_complexity": 0.9
	}
}

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	_initialize_difficulty()

func _initialize_difficulty() -> void:
	global_difficulty = DEFAULT_DIFFICULTY

# ============================================================================
# PERFORMANCE RECORDING
# ============================================================================

func record_performance(puzzle_id: String, solved: bool, time_taken: float, hints_used: int) -> void:
	var performance_data: Dictionary = {
		"puzzle_id": puzzle_id,
		"solved": solved,
		"time_taken": time_taken,
		"hints_used": hints_used,
		"timestamp": Time.get_unix_time_from_system(),
		"difficulty_at_attempt": get_difficulty_for_puzzle(puzzle_id)
	}
	
	# Add to global rolling window
	_performance_history.append(performance_data)
	if len(_performance_history) > ROLLING_WINDOW_SIZE:
		_performance_history.pop_front()
	
	# Add to puzzle-specific history
	if not _puzzle_specific_history.has(puzzle_id):
		_puzzle_specific_history[puzzle_id] = []
	_puzzle_specific_history[puzzle_id].append(performance_data)
	
	# Keep puzzle history bounded
	if len(_puzzle_specific_history[puzzle_id]) > ROLLING_WINDOW_SIZE * 2:
		_puzzle_specific_history[puzzle_id].pop_front()
	
	# Analyze and adjust if enough data collected
	if len(_performance_history) >= 5:
		_analyze_and_adjust(puzzle_id)

# ============================================================================
# DIFFICULTY ANALYSIS & ADJUSTMENT
# ============================================================================

func _analyze_and_adjust(puzzle_id: String) -> void:
	var metrics: Dictionary = _calculate_rolling_metrics()
	var performance_score: float = _calculate_performance_score(metrics)
	
	# Determine direction and magnitude of adjustment
	var adjustment: float = _calculate_adjustment(performance_score)
	
	if abs(adjustment) >= ADJUSTMENT_THRESHOLD:
		var old_difficulty: float = global_difficulty
		global_difficulty = clamp(global_difficulty + adjustment, DIFFICULTY_MIN, DIFFICULTY_MAX)
		
		difficulty_adjusted.emit(puzzle_id, global_difficulty)
		
		# Log adjustment for debugging
		print(f"[DDA] Difficulty adjusted: {old_difficulty:.2f} -> {global_difficulty:.2f} (score: {performance_score:.2f})")

func _calculate_rolling_metrics() -> Dictionary:
	var total_time: float = 0.0
	var solved_count: int = 0
	var total_hints: int = 0
	
	for perf in _performance_history:
		total_time += perf["time_taken"]
		if perf["solved"]:
			solved_count += 1
		total_hints += perf["hints_used"]
	
	var count: float = float(len(_performance_history))
	return {
		"avg_solve_time": total_time / count,
		"success_rate": solved_count / count,
		"avg_hints_per_puzzle": total_hints / count
	}

func _calculate_performance_score(metrics: Dictionary) -> float:
	# Score from 0.0 (struggling) to 1.0 (excelling)
	# Based on deviation from target performance zones
	
	var time_score: float = _calculate_time_score(metrics["avg_solve_time"])
	var success_score: float = metrics["success_rate"]
	var hint_score: float = 1.0 - min(metrics["avg_hints_per_puzzle"] / 2.0, 1.0)
	
	return (time_score * WEIGHT_SOLVE_TIME + 
			success_score * WEIGHT_MISTAKE_RATE + 
			hint_score * WEIGHT_HINT_DEPENDENCY)

func _calculate_time_score(avg_time: float) -> float:
	# Returns 1.0 if at target, decreases as time deviates
	if avg_time <= TARGET_SOLVE_TIME_SECONDS * 0.5:
		return 1.0  # Very fast
	elif avg_time <= TARGET_SOLVE_TIME_SECONDS:
		return 1.0 - ((avg_time - TARGET_SOLVE_TIME_SECONDS * 0.5) / (TARGET_SOLVE_TIME_SECONDS * 0.5)) * 0.3
	elif avg_time <= TARGET_SOLVE_TIME_SECONDS * 2.0:
		return 0.7 - ((avg_time - TARGET_SOLVE_TIME_SECONDS) / TARGET_SOLVE_TIME_SECONDS) * 0.4
	else:
		return 0.3  # Very slow

func _calculate_adjustment(performance_score: float) -> float:
	# Positive adjustment = increase difficulty, Negative = decrease
	if performance_score > 0.8:
		return min((performance_score - 0.8) * 0.5, 0.2)  # Player excelling
	elif performance_score < 0.4:
		return max((performance_score - 0.4) * 0.5, -0.2)  # Player struggling
	return 0.0  # In optimal zone

# ============================================================================
# DIFFICULTY QUERIES
# ============================================================================

func get_difficulty_for_puzzle(puzzle_id: String) -> float:
	if puzzle_difficulties.has(puzzle_id):
		return puzzle_difficulties[puzzle_id]
	return global_difficulty

func get_difficulty_tier() -> DifficultyTier:
	if global_difficulty < 0.2:
		return DifficultyTier.VERY_EASY
	elif global_difficulty < 0.4:
		return DifficultyTier.EASY
	elif global_difficulty < 0.6:
		return DifficultyTier.MEDIUM
	elif global_difficulty < 0.8:
		return DifficultyTier.HARD
	else:
		return DifficultyTier.VERY_HARD

func get_tier_name(tier: DifficultyTier) -> String:
	match tier:
		DifficultyTier.VERY_EASY: return "Very Easy"
		DifficultyTier.EASY: return "Easy"
		DifficultyTier.MEDIUM: return "Medium"
		DifficultyTier.HARD: return "Hard"
		DifficultyTier.VERY_HARD: return "Very Hard"
	return "Unknown"

# ============================================================================
# PARAMETER GENERATION
# ============================================================================

func generate_number_for_difficulty(realm: GameManager.RealmID, use_variable: bool = false) -> int:
	var config: Dictionary = _realm_configs.get(realm, _realm_configs[GameManager.RealmID.ISLE_OF_PATTERNS])
	var base_range: Array = config["base_number_range"]
	
	# Adjust range based on difficulty
	var range_span: int = base_range[1] - base_range[0]
	var difficulty_offset: int = int(float(range_span) * global_difficulty * 0.5)
	
	var adjusted_min: int = base_range[0]
	var adjusted_max: int = min(base_range[1] + difficulty_offset, base_range[1] * 2)
	
	return randi_range(adjusted_min, adjusted_max)

func generate_equation_parameters(realm: GameManager.RealmID) -> Dictionary:
	var params: Dictionary = {
		"difficulty": global_difficulty,
		"tier": get_difficulty_tier()
	}
	
	match realm:
		GameManager.RealmID.OASIS_OF_BALANCE:
			params["number_range"] = _get_adjusted_range(realm)
			params["variable_count"] = 1 + int(global_difficulty * 2)  # 1-3 variables
			params["operation_complexity"] = _get_operation_complexity()
		GameManager.RealmID.COSMIC_GEARS:
			params["place_values"] = 2 + int(global_difficulty * 2)  # 2-4 place values
			params["fraction_denominators"] = _get_fraction_denominators()
		GameManager.RealmID.CITADEL_OF_FLUIDS:
			params["volume_ratios"] = _get_volume_ratios()
			params["displacement_shapes"] = _get_shape_complexity()
	
	return params

func _get_adjusted_range(realm: GameManager.RealmID) -> Array:
	var config: Dictionary = _realm_configs.get(realm, {})
	var base_range: Array = config.get("base_number_range", [1, 10])
	var span: int = base_range[1] - base_range[0]
	var offset: int = int(float(span) * global_difficulty)
	return [base_range[0], base_range[1] + offset]

func _get_operation_complexity() -> int:
	if global_difficulty < 0.3:
		return 1  # Addition/subtraction only
	elif global_difficulty < 0.6:
		return 2  # Include multiplication
	else:
		return 3  # All operations including division

func _get_fraction_denominators() -> Array:
	if global_difficulty < 0.4:
		return [2, 4, 8]  # Simple halves, quarters
	elif global_difficulty < 0.7:
		return [2, 3, 4, 5, 6, 8, 10]
	else:
		return [2, 3, 4, 5, 6, 7, 8, 9, 10, 12]

func _get_volume_ratios() -> Array:
	if global_difficulty < 0.5:
		return [1, 2, 3, 4, 5]
	else:
		return [1, 2, 3, 4, 5, 6, 7, 8, 10, 12]

func _get_shape_complexity() -> int:
	if global_difficulty < 0.4:
		return 1  # Cubes and spheres only
	elif global_difficulty < 0.7:
		return 2  # Include cylinders, pyramids
	else:
		return 3  # All shapes including complex polyhedra

# ============================================================================
# HINT SYSTEM
# ============================================================================

func should_offer_hint(puzzle_id: String, time_elapsed: float, mistake_count: int) -> bool:
	var config: Dictionary = _realm_configs.get(GameManager.current_realm, {})
	var time_threshold: float = TARGET_SOLVE_TIME_SECONDS * config.get("time_multiplier", 1.0)
	
	# Offer hint if player is taking too long or making multiple mistakes
	if time_elapsed > time_threshold * 1.5:
		return true
	if mistake_count >= 3:
		return true
	
	# Check puzzle-specific history for repeated failures
	if _puzzle_specific_history.has(puzzle_id):
		var history: Array = _puzzle_specific_history[puzzle_id]
		var recent_failures: int = 0
		for perf in history.slice(-3):  # Last 3 attempts
			if not perf["solved"]:
				recent_failures += 1
		if recent_failures >= 2:
			return true
	
	return false

func get_hint_type(puzzle_id: String, realm: GameManager.RealmID) -> String:
	# Return contextual hint type based on realm and difficulty
	match realm:
		GameManager.RealmID.OASIS_OF_BALANCE:
			if global_difficulty < 0.4:
				return "visual_balance"  # Show which side is heavier
			else:
				return "algebraic_step"  # Show next algebraic step
		GameManager.RealmID.COSMIC_GEARS:
			return "gear_alignment"
		GameManager.RealmID.CITADEL_OF_FLUIDS:
			return "volume_visualization"
		GameManager.RealmID.LABYRINTH_OF_NETWORKS:
			return "path_highlight"
	
	return "generic"

# ============================================================================
# RESET & CALIBRATION
# ============================================================================

func reset_difficulty() -> void:
	global_difficulty = DEFAULT_DIFFICULTY
	puzzle_difficulties.clear()
	_performance_history.clear()
	_puzzle_specific_history.clear()

func calibrate_for_player(skill_level: float) -> void:
	# Direct calibration (e.g., from age selection or diagnostic quiz)
	# skill_level: 0.0 (beginner) to 1.0 (advanced)
	global_difficulty = clamp(skill_level * 0.8, DIFFICULTY_MIN, DIFFICULTY_MAX * 0.8)
	# Start slightly below assessed level to build confidence

# ============================================================================
# TELEMETRY EXPORT
# ============================================================================

func get_performance_summary() -> Dictionary:
	var metrics: Dictionary = _calculate_rolling_metrics()
	return {
		"global_difficulty": global_difficulty,
		"difficulty_tier": get_difficulty_tier(),
		"avg_solve_time": metrics.get("avg_solve_time", 0.0),
		"success_rate": metrics.get("success_rate", 0.0),
		"avg_hints_used": metrics.get("avg_hints_per_puzzle", 0.0),
		"total_puzzles_attempted": len(_performance_history),
		"timestamp": Time.get_unix_time_from_system()
	}
