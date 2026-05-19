class_name EquationGenerator
extends RefCounted
## EquationGenerator - Procedural algebraic equation generator for Stage 3.
## Generates valid balancing equations based on difficulty parameters.
## Ensures all generated equations have integer solutions for child-friendly gameplay.

# ============================================================================
# CONSTANTS
# ============================================================================

const MIN_VARIABLE_VALUE: int = 2
const MAX_VARIABLE_VALUE: int = 10
const MIN_COEFFICIENT: int = 1
const MAX_COEFFICIENT: int = 5
const MIN_CONSTANT: int = 1
const MAX_CONSTANT: int = 20

# ============================================================================
# EQUATION TYPES
# ============================================================================

enum EquationType {
	SIMPLE_AX_B,           # ax = b
	AX_PLUS_C_B,          # ax + c = b
	AX_MINUS_C_B,         # ax - c = b
	AX_PLUS_C_DX,         # ax + c = dx (variables on both sides)
	AX_PLUS_B_CX_PLUS_D   # ax + b = cx + d (full linear equation)
}

# ============================================================================
# PROPERTIES
# ============================================================================

var difficulty_level: float = 0.5  # 0.0 to 1.0
var variable_symbol: String = "X"
var ensure_positive_solution: bool = true
var ensure_integer_solution: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(difficulty: float = 0.5) -> void:
	difficulty_level = clamp(difficulty, 0.0, 1.0)

# ============================================================================
# EQUATION GENERATION
# ============================================================================

func generate_equation(equation_type: EquationType = EquationType.AX_PLUS_C_B) -> Dictionary:
	match equation_type:
		EquationType.SIMPLE_AX_B:
			return _generate_simple_ax_b()
		EquationType.AX_PLUS_C_B:
			return _generate_ax_plus_c_b()
		EquationType.AX_MINUS_C_B:
			return _generate_ax_minus_c_b()
		EquationType.AX_PLUS_C_DX:
			return _generate_ax_plus_c_dx()
		EquationType.AX_PLUS_B_CX_PLUS_D:
			return _generate_full_linear()
	
	return {}

func _generate_simple_ax_b() -> Dictionary:
	# Generate equation: ax = b
	# Solution: x = b/a
	
	var a: int = randi_range(MIN_COEFFICIENT, MAX_COEFFICIENT)
	var x: int = _get_variable_value()
	var b: int = a * x  # Ensure integer solution
	
	return {
		"type": "ax = b",
		"coefficients": {"a": a, "b": b},
		"solution": x,
		"left_side": "%d%s" % [a, variable_symbol],
		"right_side": str(b),
		"full_equation": "%d%s = %d" % [a, variable_symbol, b],
		"difficulty": 0.2
	}

func _generate_ax_plus_c_b() -> Dictionary:
	# Generate equation: ax + c = b
	# Solution: x = (b - c) / a
	
	var a: int = randi_range(MIN_COEFFICIENT, MAX_COEFFICIENT)
	var c: int = randi_range(MIN_CONSTANT, MAX_CONSTANT)
	var x: int = _get_variable_value()
	var b: int = a * x + c  # Ensure integer solution
	
	# Randomly decide if constant is on left or right
	if randf() < 0.5:
		# ax = b - c form
		return {
			"type": "ax + c = b",
			"coefficients": {"a": a, "c": c, "b": b},
			"solution": x,
			"left_side": "%d%s + %d" % [a, variable_symbol, c],
			"right_side": str(b),
			"full_equation": "%d%s + %d = %d" % [a, variable_symbol, c, b],
			"difficulty": 0.4
		}
	else:
		# ax = b + c form (rearranged)
		return {
			"type": "ax = b + c",
			"coefficients": {"a": a, "c": c, "b": b - c},
			"solution": x,
			"left_side": "%d%s" % [a, variable_symbol],
			"right_side": "%d + %d" % [b - c, c],
			"full_equation": "%d%s = %d + %d" % [a, variable_symbol, b - c, c],
			"difficulty": 0.4
		}

func _generate_ax_minus_c_b() -> Dictionary:
	# Generate equation: ax - c = b
	# Solution: x = (b + c) / a
	
	var a: int = randi_range(MIN_COEFFICIENT, MAX_COEFFICIENT)
	var c: int = randi_range(MIN_CONSTANT, MAX_CONSTANT)
	var x: int = _get_variable_value()
	var b: int = a * x - c  # Ensure integer solution and positive result
	
	if b < 1:
		b = a * x + c  # Flip to addition if subtraction would be negative
		return _generate_ax_plus_c_b()
	
	return {
		"type": "ax - c = b",
		"coefficients": {"a": a, "c": c, "b": b},
		"solution": x,
		"left_side": "%d%s - %d" % [a, variable_symbol, c],
		"right_side": str(b),
		"full_equation": "%d%s - %d = %d" % [a, variable_symbol, c, b],
		"difficulty": 0.5
	}

func _generate_ax_plus_c_dx() -> Dictionary:
	# Generate equation: ax + c = dx
	# Solution: x = c / (d - a)
	
	var x: int = _get_variable_value()
	var a: int = randi_range(MIN_COEFFICIENT, MAX_COEFFICIENT)
	var d: int = randi_range(a + 1, a + MAX_COEFFICIENT)  # Ensure d > a
	var c: int = (d - a) * x  # Ensure integer solution
	
	return {
		"type": "ax + c = dx",
		"coefficients": {"a": a, "c": c, "d": d},
		"solution": x,
		"left_side": "%d%s + %d" % [a, variable_symbol, c],
		"right_side": "%d%s" % [d, variable_symbol],
		"full_equation": "%d%s + %d = %d%s" % [a, variable_symbol, c, d, variable_symbol],
		"difficulty": 0.7
	}

func _generate_full_linear() -> Dictionary:
	# Generate equation: ax + b = cx + d
	# Solution: x = (d - b) / (a - c)
	
	var x: int = _get_variable_value()
	var a: int = randi_range(MIN_COEFFICIENT, MAX_COEFFICIENT)
	var c: int = randi_range(MIN_COEFFICIENT, MAX_COEFFICIENT)
	
	# Ensure a != c to avoid division by zero
	while c == a:
		c = randi_range(MIN_COEFFICIENT, MAX_COEFFICIENT)
	
	var b: int = randi_range(MIN_CONSTANT, MAX_CONSTANT)
	var d: int = (a - c) * x + b  # Ensure integer solution
	
	return {
		"type": "ax + b = cx + d",
		"coefficients": {"a": a, "b": b, "c": c, "d": d},
		"solution": x,
		"left_side": "%d%s + %d" % [a, variable_symbol, b],
		"right_side": "%d%s + %d" % [c, variable_symbol, d],
		"full_equation": "%d%s + %d = %d%s + %d" % [a, variable_symbol, b, c, variable_symbol, d],
		"difficulty": 0.9
	}

# ============================================================================
# VARIABLE VALUE SELECTION
# ============================================================================

func _get_variable_value() -> int:
	# Select variable value based on difficulty
	var max_value: int = int(MIN_VARIABLE_VALUE + (MAX_VARIABLE_VALUE - MIN_VARIABLE_VALUE) * difficulty_level)
	max_value = clamp(max_value, MIN_VARIABLE_VALUE, MAX_VARIABLE_VALUE)
	return randi_range(MIN_VARIABLE_VALUE, max_value)

# ============================================================================
# DIFFICULTY-BASED GENERATION
# ============================================================================

func generate_for_difficulty() -> Dictionary:
	# Select equation type based on difficulty level
	var random_value: float = randf()
	var selected_type: EquationType
	
	if difficulty_level < 0.3:
		selected_type = EquationType.SIMPLE_AX_B
	elif difficulty_level < 0.5:
		selected_type = EquationType.AX_PLUS_C_B if random_value < 0.7 else EquationType.AX_MINUS_C_B
	elif difficulty_level < 0.7:
		selected_type = EquationType.AX_PLUS_C_B
	elif difficulty_level < 0.85:
		selected_type = EquationType.AX_PLUS_C_DX
	else:
		selected_type = EquationType.AX_PLUS_B_CX_PLUS_D
	
	return generate_equation(selected_type)

# ============================================================================
# WEIGHT DISTRIBUTION FOR SCALE
# ============================================================================

func get_weight_distribution(equation_data: Dictionary) -> Dictionary:
	# Convert equation to weight distribution for the balance scale
	# Returns which weights go on left/right platforms
	
	var distribution: Dictionary = {
		"left_known_weights": [],
		"left_variable_blocks": 0,
		"right_known_weights": [],
		"right_variable_blocks": 0
	}
	
	var coefficients: Dictionary = equation_data.get("coefficients", {})
	var eq_type: String = equation_data.get("type", "")
	
	# Parse equation type and distribute weights
	if "ax = b" in eq_type:
		distribution["left_variable_blocks"] = coefficients.get("a", 1)
		distribution["right_known_weights"] = _decompose_number(coefficients.get("b", 0))
	
	elif "ax + c = b" in eq_type or "ax + c = dx" in eq_type:
		distribution["left_variable_blocks"] = coefficients.get("a", 1)
		distribution["left_known_weights"] = [coefficients.get("c", 0)]
		distribution["right_known_weights"] = _decompose_number(coefficients.get("b", 0))
	
	elif "ax - c = b" in eq_type:
		distribution["left_variable_blocks"] = coefficients.get("a", 1)
		distribution["right_known_weights"] = _decompose_number(coefficients.get("b", 0) + coefficients.get("c", 0))
		# Note: Subtraction represented as "remove c from right after balancing"
	
	elif "ax + b = cx + d" in eq_type:
		distribution["left_variable_blocks"] = coefficients.get("a", 1)
		distribution["left_known_weights"] = [coefficients.get("b", 0)]
		distribution["right_variable_blocks"] = coefficients.get("c", 1)
		distribution["right_known_weights"] = _decompose_number(coefficients.get("d", 0))
	
	return distribution

func _decompose_number(number: int) -> Array:
	# Decompose number into individual weight blocks for physical placement
	# Uses greedy algorithm with common weight denominations
	var weights: Array = []
	var remaining: int = number
	
	var denominations: Array = [10, 5, 3, 2, 1]
	
	for denom in denominations:
		while remaining >= denom:
			weights.append(denom)
			remaining -= denom
	
	return weights

# ============================================================================
# VALIDATION
# ============================================================================

func validate_equation(equation_data: Dictionary) -> bool:
	# Verify that the equation has a valid integer solution
	
	var solution: int = equation_data.get("solution", -1)
	var coefficients: Dictionary = equation_data.get("coefficients", {})
	var eq_type: String = equation_data.get("type", "")
	
	if solution < MIN_VARIABLE_VALUE or solution > MAX_VARIABLE_VALUE:
		return false
	
	# Verify by plugging solution back into equation
	if "ax = b" in eq_type:
		return coefficients.get("a", 0) * solution == coefficients.get("b", 0)
	
	elif "ax + c = b" in eq_type:
		return coefficients.get("a", 0) * solution + coefficients.get("c", 0) == coefficients.get("b", 0)
	
	elif "ax - c = b" in eq_type:
		return coefficients.get("a", 0) * solution - coefficients.get("c", 0) == coefficients.get("b", 0)
	
	elif "ax + c = dx" in eq_type:
		var left: int = coefficients.get("a", 0) * solution + coefficients.get("c", 0)
		var right: int = coefficients.get("d", 0) * solution
		return left == right
	
	elif "ax + b = cx + d" in eq_type:
		var left: int = coefficients.get("a", 0) * solution + coefficients.get("b", 0)
		var right: int = coefficients.get("c", 0) * solution + coefficients.get("d", 0)
		return left == right
	
	return false

# ============================================================================
# HINT GENERATION
# ============================================================================

func generate_step_by_step_hints(equation_data: Dictionary) -> Array:
	# Generate step-by-step solution hints
	
	var hints: Array = []
	var coefficients: Dictionary = equation_data.get("coefficients", {})
	var eq_type: String = equation_data.get("type", "")
	var solution: int = equation_data.get("solution", 0)
	
	hints.append("The goal is to find the value of " + variable_symbol)
	
	if "ax = b" in eq_type:
		hints.append("Divide both sides by %d" % coefficients.get("a", 1))
		hints.append("%s = %d / %d = %d" % [variable_symbol, coefficients.get("b", 0), coefficients.get("a", 1), solution])
	
	elif "ax + c = b" in eq_type:
		hints.append("First, subtract %d from both sides" % coefficients.get("c", 0))
		hints.append("%d%s = %d - %d = %d" % [coefficients.get("a", 1), variable_symbol, coefficients.get("b", 0), coefficients.get("c", 0), coefficients.get("b", 0) - coefficients.get("c", 0)])
		hints.append("Then divide by %d" % coefficients.get("a", 1))
	
	elif "ax + c = dx" in eq_type:
		hints.append("Move all %s terms to one side" % variable_symbol)
		hints.append("Subtract %d%s from both sides" % [coefficients.get("a", 1), variable_symbol])
		hints.append("%d = %d%s" % [coefficients.get("c", 0), coefficients.get("d", 0) - coefficients.get("a", 1), variable_symbol])
	
	return hints

# ============================================================================
# UTILITY
# ============================================================================

static func format_equation(equation_data: Dictionary) -> String:
	return equation_data.get("full_equation", "Invalid equation")

static func get_solution(equation_data: Dictionary) -> int:
	return equation_data.get("solution", -1)
