extends Node
## EquationGenerator - Procedural Algebra Problem Generator
## Generates age-appropriate algebraic equations for the balance scale puzzle.
## Supports multiple equation types with adaptive difficulty scaling.
## Provides step-by-step hints and solution validation.

class_name EquationGenerator

# ============================================================================
# SIGNALS
# ============================================================================

signal equation_generated(equation: String, solution: float, difficulty: int)
signal hint_requested(hint_text: String, hint_level: int)
signal problem_completed(equation: String, steps_taken: int, time_elapsed: float)

# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

const DIFFICULTY_LEVELS: int = 5
const MIN_SOLUTION_VALUE: float = 1.0
const MAX_SOLUTION_VALUE: float = 20.0
const MAX_COEFFICIENT: int = 10
const HINT_LEVELS: int = 3

# Equation types
enum EquationType {
	ADDITION_SIMPLE,      # a + X = b
	SUBTRACTION_SIMPLE,   # a - X = b or X - a = b
	MULTIPLICATION_SIMPLE,# a * X = b
	DIVISION_SIMPLE,      # X / a = b
	TWO_STEP              # a * X + b = c
}

# Hint templates
const HINT_TEMPLATES: Dictionary = {
	EquationType.ADDITION_SIMPLE: [
		"The equation is: %s. Think about what number plus %d equals %d.",
		"To find X, subtract %d from both sides: X = %d - %d",
		"The solution is X = %d. Place weights totaling %d kg on the left side."
	],
	EquationType.SUBTRACTION_SIMPLE: [
		"The equation is: %s. What number subtracted from %d gives %d?",
		"Rearrange: X = %d - %d",
		"The solution is X = %d. Balance the scale accordingly."
	],
	EquationType.MULTIPLICATION_SIMPLE: [
		"The equation is: %s. What number multiplied by %d equals %d?",
		"To find X, divide %d by %d: X = %d / %d",
		"The solution is X = %.1f. Use the appropriate weight combination."
	],
	EquationType.DIVISION_SIMPLE: [
		"The equation is: %s. What number divided by %d equals %d?",
		"Multiply both sides by %d: X = %d * %d",
		"The solution is X = %d. Place the correct weights."
	],
	EquationType.TWO_STEP: [
		"The equation is: %s. First, isolate the term with X.",
		"Subtract %d from both sides, then divide by %d.",
		"The solution is X = %.1f. This requires careful weight placement."
	]
}

# ============================================================================
# PROPERTIES
# ============================================================================

@export_group("Generation Settings")
@export var current_difficulty: int = 1
@export var allow_negative_solutions: bool = false
@export var allow_decimal_solutions: bool = false
@export var max_equations_before_repeat: int = 10

@export_group("Adaptive Settings")
@export var enable_adaptive_difficulty: bool = true
@export var performance_threshold_increase: float = 0.75  # 75% success rate to increase difficulty
@export var performance_threshold_decrease: float = 0.40  # 40% success rate to decrease difficulty

# State tracking
var _generated_equations: Array[String] = []
var _current_equation: String = ""
var _current_solution: float = 0.0
var _current_type: EquationType = EquationType.ADDITION_SIMPLE
var _consecutive_successes: int = 0
var _consecutive_failures: int = 0
var _total_problems: int = 0
var _correct_problems: int = 0
var _start_time: float = 0.0
var _random_generator: RandomNumberGenerator = RandomNumberGenerator.new()

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	_random_generator.seed = randi()
	print("[EquationGenerator] Initialized with difficulty level %d" % current_difficulty)

# ============================================================================
# EQUATION GENERATION
# ============================================================================

func generate_equation(force_type: EquationType = -1) -> Dictionary:
	"""
	Generate a new algebraic equation based on current difficulty.
	
	PARAMETERS:
	- force_type: Optional specific equation type, -1 for automatic selection
	
	RETURNS:
	Dictionary with keys: equation, solution, type, difficulty
	"""
	_start_time = Time.get_ticks_msec()
	
	# Select equation type based on difficulty
	var equation_type: EquationType = _select_equation_type(force_type)
	
	# Generate equation based on type
	var equation_data: Dictionary = _generate_equation_by_type(equation_type)
	
	# Ensure uniqueness
	var max_attempts: int = 20
	var attempts: int = 0
	while equation_data.equation in _generated_equations and attempts < max_attempts:
		equation_data = _generate_equation_by_type(equation_type)
		attempts += 1
	
	# Store generated equation
	_current_equation = equation_data.equation
	_current_solution = equation_data.solution
	_current_type = equation_type
	
	_generated_equations.append(_current_equation)
	if _generated_equations.size() > max_equations_before_repeat:
		_generated_equations.pop_front()
	
	# Update statistics
	_total_problems += 1
	
	# Emit signal
	equation_generated.emit(_current_equation, _current_solution, current_difficulty)
	
	print("[EquationGenerator] Generated: %s (X=%.2f, type=%s, difficulty=%d)" % [
		_current_equation, 
		_current_solution,
		EquationType.keys()[equation_type],
		current_difficulty
	])
	
	return equation_data

func _select_equation_type(force_type: EquationType) -> EquationType:
	"""Select appropriate equation type based on difficulty."""
	if force_type >= 0:
		return force_type as EquationType
	
	match current_difficulty:
		1:
			return EquationType.ADDITION_SIMPLE
		2:
			var types: Array = [EquationType.ADDITION_SIMPLE, EquationType.SUBTRACTION_SIMPLE]
			return types[_random_generator.randi() % types.size()]
		3:
			var types: Array = [
				EquationType.ADDITION_SIMPLE,
				EquationType.SUBTRACTION_SIMPLE,
				EquationType.MULTIPLICATION_SIMPLE
			]
			return types[_random_generator.randi() % types.size()]
		4:
			var types: Array = [
				EquationType.ADDITION_SIMPLE,
				EquationType.SUBTRACTION_SIMPLE,
				EquationType.MULTIPLICATION_SIMPLE,
				EquationType.DIVISION_SIMPLE
			]
			return types[_random_generator.randi() % types.size()]
		_:
			var types: Array = [
				EquationType.ADDITION_SIMPLE,
				EquationType.SUBTRACTION_SIMPLE,
				EquationType.MULTIPLICATION_SIMPLE,
				EquationType.DIVISION_SIMPLE,
				EquationType.TWO_STEP
			]
			return types[_random_generator.randi() % types.size()]
	
	return EquationType.ADDITION_SIMPLE

func _generate_equation_by_type(type: EquationType) -> Dictionary:
	"""Generate equation of specified type with valid solution."""
	match type:
		EquationType.ADDITION_SIMPLE:
			return _generate_addition_equation()
		EquationType.SUBTRACTION_SIMPLE:
			return _generate_subtraction_equation()
		EquationType.MULTIPLICATION_SIMPLE:
			return _generate_multiplication_equation()
		EquationType.DIVISION_SIMPLE:
			return _generate_division_equation()
		EquationType.TWO_STEP:
			return _generate_two_step_equation()
	
	return _generate_addition_equation()

func _generate_addition_equation() -> Dictionary:
	"""Generate addition equation: a + X = b"""
	var solution: int = _random_generator.randi_range(int(MIN_SOLUTION_VALUE), int(MAX_SOLUTION_VALUE))
	var addend: int = _random_generator.randi_range(1, MAX_COEFFICIENT)
	var total: int = solution + addend
	
	var equation: String = "%d + X = %d" % [addend, total]
	
	return {
		"equation": equation,
		"solution": float(solution),
		"type": EquationType.ADDITION_SIMPLE,
		"difficulty": current_difficulty,
		"components": {"a": addend, "b": total}
	}

func _generate_subtraction_equation() -> Dictionary:
	"""Generate subtraction equation: a - X = b OR X - a = b"""
	var variant: int = _random_generator.randi_range(0, 1)
	
	if variant == 0:
		# a - X = b
		var solution: int = _random_generator.randi_range(int(MIN_SOLUTION_VALUE), int(MAX_SOLUTION_VALUE))
		var minuend: int = solution + _random_generator.randi_range(1, MAX_COEFFICIENT)
		var difference: int = minuend - solution
		
		var equation: String = "%d - X = %d" % [minuend, difference]
		
		return {
			"equation": equation,
			"solution": float(solution),
			"type": EquationType.SUBTRACTION_SIMPLE,
			"difficulty": current_difficulty,
			"components": {"a": minuend, "b": difference}
		}
	else:
		# X - a = b
		var solution: int = _random_generator.randi_range(int(MIN_SOLUTION_VALUE) + 1, int(MAX_SOLUTION_VALUE))
		var subtrahend: int = _random_generator.randi_range(1, solution - 1)
		var difference: int = solution - subtrahend
		
		var equation: String = "X - %d = %d" % [subtrahend, difference]
		
		return {
			"equation": equation,
			"solution": float(solution),
			"type": EquationType.SUBTRACTION_SIMPLE,
			"difficulty": current_difficulty,
			"components": {"a": subtrahend, "b": difference}
		}

func _generate_multiplication_equation() -> Dictionary:
	"""Generate multiplication equation: a * X = b"""
	var solution: int = _random_generator.randi_range(int(MIN_SOLUTION_VALUE), min(10, int(MAX_SOLUTION_VALUE)))
	var coefficient: int = _random_generator.randi_range(2, min(5, MAX_COEFFICIENT))
	var product: int = solution * coefficient
	
	var equation: String = "%d * X = %d" % [coefficient, product]
	
	return {
		"equation": equation,
		"solution": float(solution),
		"type": EquationType.MULTIPLICATION_SIMPLE,
		"difficulty": current_difficulty,
		"components": {"a": coefficient, "b": product}
	}

func _generate_division_equation() -> Dictionary:
	"""Generate division equation: X / a = b"""
	var solution: int = _random_generator.randi_range(int(MIN_SOLUTION_VALUE), int(MAX_SOLUTION_VALUE))
	var divisor: int = _random_generator.randi_range(2, min(5, MAX_COEFFICIENT))
	var dividend: int = solution * divisor
	
	var equation: String = "X / %d = %d" % [divisor, dividend]
	
	return {
		"equation": equation,
		"solution": float(solution),
		"type": EquationType.DIVISION_SIMPLE,
		"difficulty": current_difficulty,
		"components": {"a": divisor, "b": dividend}
	}

func _generate_two_step_equation() -> Dictionary:
	"""Generate two-step equation: a * X + b = c"""
	var solution: int = _random_generator.randi_range(int(MIN_SOLUTION_VALUE), int(MAX_SOLUTION_VALUE / 2))
	var coefficient: int = _random_generator.randi_range(2, 4)
	var constant: int = _random_generator.randi_range(1, 10)
	var result: int = (solution * coefficient) + constant
	
	var equation: String = "%d * X + %d = %d" % [coefficient, constant, result]
	
	return {
		"equation": equation,
		"solution": float(solution),
		"type": EquationType.TWO_STEP,
		"difficulty": current_difficulty,
		"components": {"a": coefficient, "b": constant, "c": result}
	}

# ============================================================================
# HINT SYSTEM
# ============================================================================

func get_hint(hint_level: int = 0) -> String:
	"""
	Get a hint for the current equation.
	
	PARAMETERS:
	- hint_level: 0 = subtle, 1 = moderate, 2 = explicit
	
	RETURNS:
	Hint text string
	"""
	hint_level = clamp(hint_level, 0, HINT_LEVELS - 1)
	
	var templates: Array = HINT_TEMPLATES.get(_current_type, HINT_TEMPLATES[EquationType.ADDITION_SIMPLE])
	var template: String = templates[hint_level] if hint_level < templates.size() else templates[templates.size() - 1]
	
	# Format template with equation data
	var hint_text: String = template % [_current_equation, 
		_current_solution, _current_solution, 
		_current_solution, _current_solution,
		_current_solution, _current_solution]
	
	# Emit signal
	hint_requested.emit(hint_text, hint_level)
	
	return hint_text

# ============================================================================
# ADAPTIVE DIFFICULTY
# ============================================================================

func record_result(is_correct: bool) -> void:
	"""
	Record problem completion result for adaptive difficulty.
	
	PARAMETERS:
	- is_correct: Whether the solution was correct
	"""
	if is_correct:
		_consecutive_successes += 1
		_consecutive_failures = 0
		_correct_problems += 1
	else:
		_consecutive_failures += 1
		_consecutive_successes = 0
	
	# Check for difficulty adjustment
	if enable_adaptive_difficulty:
		_check_difficulty_adjustment()

func _check_difficulty_adjustment() -> void:
	"""Adjust difficulty based on performance metrics."""
	var success_rate: float = float(_correct_problems) / float(max(_total_problems, 1))
	
	# Increase difficulty
	if success_rate >= performance_threshold_increase and current_difficulty < DIFFICULTY_LEVELS:
		if _consecutive_successes >= 3:
			current_difficulty += 1
			_consecutive_successes = 0
			print("[EquationGenerator] Difficulty increased to %d (success rate: %.1f%%)" % [
				current_difficulty, success_rate * 100
			])
	
	# Decrease difficulty
	elif success_rate <= performance_threshold_decrease and current_difficulty > 1:
		if _consecutive_failures >= 3:
			current_difficulty -= 1
			_consecutive_failures = 0
			print("[EquationGenerator] Difficulty decreased to %d (success rate: %.1f%%)" % [
				current_difficulty, success_rate * 100
			])

func get_performance_stats() -> Dictionary:
	"""Return current performance statistics."""
	var success_rate: float = float(_correct_problems) / float(max(_total_problems, 1))
	
	return {
		"total_problems": _total_problems,
		"correct_problems": _correct_problems,
		"success_rate": success_rate,
		"current_difficulty": current_difficulty,
		"consecutive_successes": _consecutive_successes,
		"consecutive_failures": _consecutive_failures,
		"equations_in_history": _generated_equations.size()
	}

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

func reset_statistics() -> void:
	"""Reset all performance tracking."""
	_generated_equations.clear()
	_consecutive_successes = 0
	_consecutive_failures = 0
	_total_problems = 0
	_correct_problems = 0
	current_difficulty = 1
	
	print("[EquationGenerator] Statistics reset")

func get_current_problem_info() -> Dictionary:
	"""Return information about the current problem."""
	return {
		"equation": _current_equation,
		"solution": _current_solution,
		"type": EquationType.keys()[_current_type],
		"difficulty": current_difficulty,
		"time_elapsed_ms": Time.get_ticks_msec() - _start_time
	}

# ============================================================================
# DEBUG & UTILITIES
# ============================================================================

func debug_print_stats() -> void:
	"""Print performance statistics to console."""
	var stats: Dictionary = get_performance_stats()
	print("=== EQUATION GENERATOR STATS ===")
	for key in stats:
		print("  %s: %s" % [key, stats[key]])
	print("===============================")

func test_generation(count: int = 5) -> void:
	"""Test equation generation for debugging."""
	print("\n=== TESTING EQUATION GENERATION (%d problems) ===" % count)
	for i in range(count):
		var data: Dictionary = generate_equation()
		print("%d. %s → X = %.2f" % [i + 1, data.equation, data.solution])
	print("==========================================\n")
