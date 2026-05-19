extends RigidBody3D
## BalanceScale - Al-Khwarizmi's Algebra Learning System
## Physics-based scale simulation for teaching early algebra concepts.
## Tracks left/right platform masses, computes equilibrium with epsilon threshold,
## validates algebraic solutions, and emits signals for game progression.
## 
## MATH ENGINE ABSTRACTION:
## - Scale torque = (left_mass * left_distance) - (right_mass * right_distance)
## - Equilibrium when |torque| < epsilon_threshold (0.5kg equivalent)
## - Equation format: a + X = b, where X is unknown variable block
## - Solution validation: player places weights to balance both sides

class_name BalanceScale

# ============================================================================
# SIGNALS
# ============================================================================

signal scale_balanced(is_correct: bool, equation_solved: String)
signal weight_placed(side: String, mass: float, total_mass: float)
signal weight_removed(side: String, mass: float, total_mass: float)
signal tilt_changed(angle_degrees: float, direction: int)  # -1=left, 0=balanced, 1=right
signal equation_validated(success: bool, steps_taken: int)

# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

const EPSILON_THRESHOLD: float = 0.5  # kg - acceptable imbalance for "balanced" state
const MAX_TILT_ANGLE: float = 25.0  # degrees - maximum physical tilt before blocks slide
const DAMPING_FACTOR: float = 0.92  # velocity damping per physics tick
const ANGULAR_DAMPING: float = 0.85  # rotational damping for stability
const PLATFORM_DISTANCE: float = 2.0  # meters from pivot to each platform
const GRAVITY: float = 9.8  # m/s² (matches Godot default)
const MIN_MASS: float = 0.1  # kg - minimum detectable mass
const MAX_MASS_PER_SIDE: float = 50.0  # kg - maximum mass before scale breaks

# Balance states
enum BalanceState {
	UNBALANCED_LEFT,    # Left side heavier
	UNBALANCED_RIGHT,   # Right side heavier
	BALANCED,           # Within epsilon threshold
	TIPPED_LEFT,        # Exceeded max tilt left
	TIPPED_RIGHT        # Exceeded max tilt right
}

# ============================================================================
# PROPERTIES
# ============================================================================

# Platform references (assigned via scene tree or editor)
@export_group("Platform References")
@export var left_platform: Area3D
@export var right_platform: Area3D
@export var left_socket: Node3D
@export var right_socket: Node3D

# Physics properties
@export_group("Physics Configuration")
@export var arm_mass: float = 5.0
@export var pivot_stiffness: float = 15.0
@export var enable_auto_balance: bool = true  # Auto-center when balanced

# Game state
@export_group("Game State")
var current_equation: String = ""
var expected_solution: float = 0.0
var left_total_mass: float = 0.0
var right_total_mass: float = 0.0
var current_tilt_angle: float = 0.0
var balance_state: BalanceState = BalanceState.BALANCED
var steps_taken: int = 0
var is_solvable: bool = false
var _is_simulating: bool = false

# Internal tracking
var _left_blocks: Array[Dictionary] = []  # [{mass, is_variable, id}]
var _right_blocks: Array[Dictionary] = []
var _consecutive_balanced_ticks: int = 0
var _stable_balance_threshold: int = 5  # ticks needed to confirm balance
var _last_torque: float = 0.0
var _angular_velocity: float = 0.0

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	_initialize_scale()
	_connect_platform_signals()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not _is_simulating:
		return
	
	_update_physics_simulation(delta)
	_check_equilibrium()
	_apply_damping()

# ============================================================================
# INITIALIZATION
# ============================================================================

func _initialize_scale() -> void:
	"""Initialize scale physics properties and reset state."""
	mass = arm_mass
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.8
	physics_material_override.bounce = 0.1
	
	angular_damping = ANGULAR_DAMPING
	sleeping_allowed = false
	
	reset_scale_state()
	print("[BalanceScale] Initialized with epsilon=%.2f kg, max_tilt=%.1f°" % [EPSILON_THRESHOLD, MAX_TILT_ANGLE])

func _connect_platform_signals() -> void:
	"""Connect collision signals from platform areas."""
	if left_platform:
		left_platform.body_entered.connect(_on_body_entered_left)
		left_platform.body_exited.connect(_on_body_exited_left)
	
	if right_platform:
		right_platform.body_entered.connect(_on_body_entered_right)
		right_platform.body_exited.connect(_on_body_exited_right)

# ============================================================================
# PHYSICS SIMULATION
# ============================================================================

func _update_physics_simulation(delta: float) -> void:
	"""
	Calculate torque and angular acceleration based on mass distribution.
	
	MATH ENGINE:
	torque = (left_mass * g * distance) - (right_mass * g * distance)
	angular_acceleration = torque / moment_of_inertia
	
	Simplified: torque proportional to mass difference since distance & g are constant
	"""
	var mass_difference: float = left_total_mass - right_total_mass
	
	# Calculate torque (simplified model)
	var torque: float = mass_difference * GRAVITY * PLATFORM_DISTANCE
	_last_torque = torque
	
	# Apply torque as angular impulse
	var angular_impulse: float = torque * delta * 0.1  # Scaling factor for gameplay feel
	_angular_velocity += angular_impulse
	
	# Apply gravity-based restoring force when tilted
	if abs(current_tilt_angle) > 0.1:
		var restoring_torque: float = -current_tilt_angle * pivot_stiffness * delta
		_angular_velocity += restoring_torque
	
	# Update tilt angle
	current_tilt_angle += _angular_velocity * delta * 60.0  # Normalize to 60 FPS
	
	# Clamp tilt angle
	current_tilt_angle = clamp(current_tilt_angle, -MAX_TILT_ANGLE, MAX_TILT_ANGLE)
	
	# Apply rotation to scale arm visual
	var scale_arm: Node3D = get_node_or_null("PivotPoint/ScaleArm")
	if scale_arm:
		scale_arm.rotation.z = deg_to_rad(current_tilt_angle)

func _check_equilibrium() -> void:
	"""
	Determine balance state using epsilon comparison.
	
	EQUILIBRIUM LOGIC:
	- |left_mass - right_mass| < EPSILON → BALANCED
	- left_mass > right_mass + EPSILON → UNBALANCED_LEFT
	- right_mass > left_mass + EPSILON → UNBALANCED_RIGHT
	- |tilt_angle| > MAX_TILT → TIPPED state
	"""
	var mass_diff: float = abs(left_total_mass - right_total_mass)
	
	# Check for tipped state first
	if current_tilt_angle <= -MAX_TILT_ANGLE + 0.5:
		balance_state = BalanceState.TIPPED_LEFT
		_consecutive_balanced_ticks = 0
	elif current_tilt_angle >= MAX_TILT_ANGLE - 0.5:
		balance_state = BalanceState.TIPPED_RIGHT
		_consecutive_balanced_ticks = 0
	# Check for balanced state within epsilon threshold
	elif mass_diff < EPSILON_THRESHOLD:
		if balance_state != BalanceState.BALANCED:
			_consecutive_balanced_ticks = 0
		
		_consecutive_balanced_ticks += 1
		
		if _consecutive_balanced_ticks >= _stable_balance_threshold:
			balance_state = BalanceState.BALANCED
			_on_scale_balanced()
	else:
		# Determine which side is heavier
		if left_total_mass > right_total_mass:
			balance_state = BalanceState.UNBALANCED_LEFT
		else:
			balance_state = BalanceState.UNBALANCED_RIGHT
		
		_consecutive_balanced_ticks = 0
	
	# Emit tilt update signal
	var tilt_direction: int = 0
	if current_tilt_angle < -1.0:
		tilt_direction = -1
	elif current_tilt_angle > 1.0:
		tilt_direction = 1
	
	tilt_changed.emit(current_tilt_angle, tilt_direction)

func _apply_damping() -> void:
	"""Apply velocity damping to prevent oscillation."""
	_angular_velocity *= DAMPING_FACTOR
	
	# Stop completely if near equilibrium and velocity is minimal
	if balance_state == BalanceState.BALANCED and abs(_angular_velocity) < 0.01:
		_angular_velocity = 0.0
		current_tilt_angle = 0.0

# ============================================================================
# MASS TRACKING
# ============================================================================

func _on_body_entered_left(body: Node3D) -> void:
	_handle_weight_added(body, "left")

func _on_body_exited_left(body: Node3D) -> void:
	_handle_weight_removed(body, "left")

func _on_body_entered_right(body: Node3D) -> void:
	_handle_weight_added(body, "right")

func _on_body_exited_right(body: Node3D) -> void:
	_handle_weight_removed(body, "right")

func _handle_weight_added(body: Node3D, side: String) -> void:
	"""Process weight block added to platform."""
	if not body.has_method("get_mass_value"):
		return
	
	var block_mass: float = body.get_mass_value()
	var is_variable: bool = body.get("is_variable_block", false)
	var block_id: String = str(body.get_instance_id())
	
	# Add to tracking array
	var block_data: Dictionary = {
		"mass": block_mass,
		"is_variable": is_variable,
		"id": block_id,
		"body": body
	}
	
	if side == "left":
		_left_blocks.append(block_data)
		left_total_mass += block_mass
	else:
		_right_blocks.append(block_data)
		right_total_mass += block_mass
	
	# Emit signal
	var new_total: float = left_total_mass if side == "left" else right_total_mass
	weight_placed.emit(side, block_mass, new_total)
	steps_taken += 1
	
	print("[BalanceScale] Weight added to %s: %.2f kg (total: %.2f kg)" % [side, block_mass, new_total])

func _handle_weight_removed(body: Node3D, side: String) -> void:
	"""Process weight block removed from platform."""
	var block_id: String = str(body.get_instance_id())
	var target_array: Array[Dictionary] = _left_blocks if side == "left" else _right_blocks
	
	# Find and remove block data
	for i in range(target_array.size() - 1, -1, -1):
		if target_array[i]["id"] == block_id:
			var removed_mass: float = target_array[i]["mass"]
			target_array.remove_at(i)
			
			if side == "left":
				left_total_mass -= removed_mass
			else:
				right_total_mass -= removed_mass
			
			# Emit signal
			var new_total: float = left_total_mass if side == "left" else right_total_mass
			weight_removed.emit(side, removed_mass, new_total)
			steps_taken += 1
			
			print("[BalanceScale] Weight removed from %s: %.2f kg (total: %.2f kg)" % [side, removed_mass, new_total])
			break

# ============================================================================
# EQUATION MANAGEMENT
# ============================================================================

func setup_equation(equation: String, solution: float) -> void:
	"""
	Configure the algebraic equation for this puzzle session.
	
	PARAMETERS:
	- equation: String representation (e.g., "3 + X = 8")
	- solution: Expected value of X
	"""
	current_equation = equation
	expected_solution = solution
	is_solvable = true
	reset_scale_state()
	
	print("[BalanceScale] Equation set: %s, solution X=%.2f" % [equation, solution])

func validate_solution() -> bool:
	"""
	Check if current configuration solves the equation.
	
	VALIDATION LOGIC:
	For equation a + X = b:
	- Left side should have: a (fixed) + X (variable blocks)
	- Right side should have: b (fixed)
	- Balance confirms: a + X = b → X = b - a
	
	Returns true if scale is balanced AND equation is correctly solved.
	"""
	if balance_state != BalanceState.BALANCED:
		return false
	
	# Parse and validate equation
	var parts: PackedStringArray = current_equation.split("=")
	if parts.size() != 2:
		return false
	
	var left_expr: String = parts[0].strip_edges()
	var right_expr: String = parts[1].strip_edges()
	
	# Extract expected values (simplified parser)
	var right_value: float = _parse_expression(right_expr)
	var left_fixed: float = _extract_fixed_value(left_expr)
	
	# Calculate actual X value from placed blocks
	var actual_x: float = left_total_mass - left_fixed
	
	# Verify solution
	var is_correct: bool = abs(actual_x - expected_solution) < EPSILON_THRESHOLD
	
	if is_correct:
		equation_validated.emit(true, steps_taken)
		print("[BalanceScale] ✓ Equation solved correctly! X = %.2f" % actual_x)
	else:
		print("[BalanceScale] ✗ Incorrect solution. Expected X=%.2f, got X=%.2f" % [expected_solution, actual_x])
	
	return is_correct

func _parse_expression(expr: String) -> float:
	"""Parse numeric expression (simplified - handles integers and floats)."""
	expr = expr.strip_edges()
	
	# Remove 'X' if present
	expr = expr.replace("X", "").replace("x", "")
	expr = expr.replace("+", "").replace("-", "").strip_edges()
	
	if expr.is_empty():
		return 0.0
	
	return float(expr) if "." in expr else float(expr)

func _extract_fixed_value(expr: String) -> float:
	"""Extract fixed numeric value from expression (excluding X terms)."""
	var parts: PackedStringArray = expr.split("+")
	var total: float = 0.0
	
	for part in parts:
		part = part.strip_edges()
		if "X" not in part and "x" not in part and not part.is_empty():
			total += float(part) if "." in part else float(part)
	
	return total

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

func reset_scale_state() -> void:
	"""Reset scale to initial balanced state."""
	left_total_mass = 0.0
	right_total_mass = 0.0
	current_tilt_angle = 0.0
	_angular_velocity = 0.0
	balance_state = BalanceState.BALANCED
	_consecutive_balanced_ticks = 0
	steps_taken = 0
	_left_blocks.clear()
	_right_blocks.clear()
	
	# Reset visual rotation
	var scale_arm: Node3D = get_node_or_null("PivotPoint/ScaleArm")
	if scale_arm:
		scale_arm.rotation_z = 0.0
	
	print("[BalanceScale] State reset")

func start_simulation() -> void:
	"""Begin physics simulation."""
	_is_simulating = true
	set_physics_process(true)
	print("[BalanceScale] Simulation started")

func stop_simulation() -> void:
	"""Pause physics simulation."""
	_is_simulating = false
	set_physics_process(false)
	print("[BalanceScale] Simulation stopped")

# ============================================================================
# EVENT HANDLERS
# ============================================================================

func _on_scale_balanced() -> void:
	"""Called when scale achieves stable balance."""
	print("[BalanceScale] ✓ Scale balanced! L=%.2f kg, R=%.2f kg" % [left_total_mass, right_total_mass])
	
	# Validate if this solves the equation
	var is_correct: bool = validate_solution()
	scale_balanced.emit(is_correct, current_equation)
	
	# Trigger haptic feedback via NativeBridge
	if NativeBridge:
		if is_correct:
			NativeBridge.trigger_haptic(NativeBridge.HAPTIC_PATTERN_SUCCESS)
		else:
			NativeBridge.trigger_haptic(NativeBridge.HAPTIC_PATTERN_MEDIUM)

# ============================================================================
# DEBUG & UTILITIES
# ============================================================================

func get_balance_report() -> Dictionary:
	"""Return detailed balance state for debugging."""
	return {
		"left_mass": left_total_mass,
		"right_mass": right_total_mass,
		"mass_difference": left_total_mass - right_total_mass,
		"tilt_angle": current_tilt_angle,
		"balance_state": BalanceState.keys()[balance_state],
		"is_balanced": balance_state == BalanceState.BALANCED,
		"equation": current_equation,
		"steps_taken": steps_taken,
		"left_blocks": _left_blocks.size(),
		"right_blocks": _right_blocks.size()
	}

func debug_print_state() -> void:
	"""Print current state to console for debugging."""
	var report: Dictionary = get_balance_report()
	print("=== BALANCE SCALE STATE ===")
	for key in report:
		print("  %s: %s" % [key, report[key]])
	print("===========================")
