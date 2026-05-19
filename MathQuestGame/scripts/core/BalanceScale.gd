extends Node3D
class_name BalanceScale

## Stage 3: Al-Khwarizmi's Balance Scale - Vertical Slice Implementation
## Handles physics-based scale simulation, mass tracking, and equilibrium detection

signal scale_balanced(is_correct: bool)
signal weight_placed(platform: String, mass: float)
signal weight_removed(platform: String, mass: float)
signal tilt_changed(angle: float)

# ============================================================================
# CONFIGURATION CONSTANTS
# ============================================================================

## Maximum tilt angle in degrees before weights slide off
const MAX_TILT_ANGLE: float = 25.0

## Equilibrium threshold in kg (how close masses must be to be considered balanced)
const EQUILIBRIUM_THRESHOLD: float = 0.5

## Damping factor for scale oscillation (higher = faster stabilization)
const DAMPING_FACTOR: float = 0.95

## Physics tick rate for smooth simulation
const PHYSICS_TICKS_PER_SECOND: int = 120

# ============================================================================
# NODE REFERENCES (Assigned via scene tree or @onready)
# ============================================================================

@export_group("Scale Components")
@export var left_platform: Area3D
@export var right_platform: Area3D
@export var scale_arm: RigidBody3D
@export var pivot_point: Node3D

@export_group("Socket Positions")
@export var left_socket: Node3D
@export var right_socket: Node3D

@export_group("Audio")
@export var balance_sound: AudioStream
@export var tilt_sound: AudioStream

# ============================================================================
# STATE VARIABLES (Strictly Typed)
# ============================================================================

## Current mass on left platform in kilograms
var _left_mass: float = 0.0

## Current mass on right platform in kilograms
var _right_mass: float = 0.0

## Dictionary tracking individual weights on left platform {weight_id: mass}
var _left_weights: Dictionary = {}

## Dictionary tracking individual weights on right platform {weight_id: mass}
var _right_weights: Dictionary = {}

## Current tilt angle of the scale arm in radians
var _current_tilt: float = 0.0

## Target tilt angle based on mass difference
var _target_tilt: float = 0.0

## Whether the scale is currently in equilibrium
var _is_balanced: bool = false

## Whether we're waiting for validation (all weights placed)
var _awaiting_validation: bool = false

## Reference to the equation generator for solution checking
var _equation_generator: Node = null

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
_initialize_nodes()
_connect_signals()
_reset_scale_state()
print("[BalanceScale] Initialized - Ready for gameplay")


func _initialize_nodes() -> void:
"""Auto-find nodes if not explicitly assigned"""
if not left_platform:
left_platform = get_node_or_null("LeftPlatform") as Area3D
if not right_platform:
right_platform = get_node_or_null("RightPlatform") as Area3D
if not scale_arm:
scale_arm = get_node_or_null("PivotPoint/ScaleArm") as RigidBody3D
if not pivot_point:
pivot_point = get_node_or_null("PivotPoint")
if not left_socket:
left_socket = get_node_or_null("PivotPoint/ScaleArm/LeftPlatformSocket") as Node3D
if not right_socket:
right_socket = get_node_or_null("PivotPoint/ScaleArm/RightPlatformSocket") as Node3D

# Find equation generator in parent scene
_equation_generator = get_tree().get_current_scene().get_node_or_null("EquationGenerator")


func _connect_signals() -> void:
"""Connect collision signals for weight detection"""
if left_platform:
left_platform.body_entered.connect(_on_left_platform_body_entered)
left_platform.body_exited.connect(_on_left_platform_body_exited)

if right_platform:
right_platform.body_entered.connect(_on_right_platform_body_entered)
right_platform.body_exited.connect(_on_right_platform_body_exited)


func _reset_scale_state() -> void:
"""Reset all state variables to initial values"""
_left_mass = 0.0
_right_mass = 0.0
_left_weights.clear()
_right_weights.clear()
_current_tilt = 0.0
_target_tilt = 0.0
_is_balanced = false
_awaiting_validation = false

if scale_arm:
scale_arm.rotation.z = 0.0
scale_arm.angular_velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
"""Physics update loop - calculate tilt and check equilibrium"""
_update_tilt_physics(delta)
_check_equilibrium()


# ============================================================================
# PHYSICS ENGINE - MATH ABSTRACTION
# ============================================================================

func _update_tilt_physics(delta: float) -> void:
"""
Calculate scale tilt based on mass differential using torque physics.

Torque Formula: τ = r × F where F = m × g
Since both arms have equal length (r), torque ratio simplifies to mass ratio.

Tilt calculation uses a proportional controller with damping:
- Target tilt is proportional to mass difference
- Current tilt approaches target with exponential smoothing
- Damping prevents excessive oscillation
"""
if not scale_arm:
return

# Calculate mass difference (positive = right heavier, negative = left heavier)
var mass_difference: float = _right_mass - _left_mass
var total_mass: float = _left_mass + _right_mass

# Prevent division by zero
if total_mass < 0.01:
_target_tilt = 0.0
else:
# Normalize tilt to max angle based on mass ratio
# Using sigmoid-like function for natural feel
var normalized_diff: float = mass_difference / (total_mass * 0.5 + 1.0)
_target_tilt = normalized_diff * deg_to_rad(MAX_TILT_ANGLE)

# Smooth interpolation to target tilt (exponential moving average)
var smoothing_factor: float = 1.0 - pow(DAMPING_FACTOR, delta * PHYSICS_TICKS_PER_SECOND)
_current_tilt = lerp(_current_tilt, _target_tilt, smoothing_factor)

# Apply rotation to scale arm
scale_arm.rotation.z = _current_tilt

# Emit tilt signal for UI/audio feedback
if abs(_current_tilt) > 0.01:
tilt_changed.emit(rad_to_deg(_current_tilt))


func _check_equilibrium() -> void:
"""
Determine if scale is balanced within acceptable threshold.

Equilibrium conditions:
1. Mass difference must be within threshold (|left - right| < ε)
2. Angular velocity must be near zero (scale has stopped moving)
3. Tilt angle must be near horizontal (|tilt| < small_angle)

This prevents false positives from dynamic balancing during movement.
"""
if not scale_arm:
return

var mass_diff: float = abs(_left_mass - _right_mass)
var angular_vel: float = abs(scale_arm.angular_velocity.z)
var tilt_from_horizontal: float = abs(_current_tilt)

# Check all equilibrium conditions
var mass_balanced: bool = mass_diff < EQUILIBRIUM_THRESHOLD
var motion_stopped: bool = angular_vel < 0.01
var level_horizontal: bool = tilt_from_horizontal < deg_to_rad(2.0)

var newly_balanced: bool = mass_balanced and motion_stopped and level_horizontal

if newly_balanced and not _is_balanced:
_is_balanced = true
_on_scale_achieved_balance()
elif not newly_balanced and _is_balanced:
_is_balanced = false


func _on_scale_achieved_balance() -> void:
"""Called when scale reaches equilibrium - validate solution"""
print("[BalanceScale] Scale balanced! Left: %.2f kg, Right: %.2f kg" % [_left_mass, _right_mass])

# Check if this is a valid algebraic solution
var is_correct_solution: bool = _validate_algebraic_solution()

# Emit result signal
scale_balanced.emit(is_correct_solution)

# Play feedback sound
if balance_sound:
var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
player.stream = balance_sound
add_child(player)
player.play()


# ============================================================================
# MASS TRACKING - WEIGHT MANAGEMENT
# ============================================================================

func add_weight_to_platform(weight_id: String, mass: float, is_left: bool) -> void:
"""
Add a weight block to the specified platform.

Args:
weight_id: Unique identifier for the weight block
mass: Mass value in kilograms
is_left: True for left platform, False for right
"""
if is_left:
if weight_id in _left_weights:
push_warning("Weight %s already on left platform" % weight_id)
return
_left_weights[weight_id] = mass
_left_mass += mass
weight_placed.emit("left", mass)
else:
if weight_id in _right_weights:
push_warning("Weight %s already on right platform" % weight_id)
return
_right_weights[weight_id] = mass
_right_mass += mass
weight_placed.emit("right", mass)

print("[BalanceScale] Weight added - Left: %.2f kg, Right: %.2f kg" % [_left_mass, _right_mass])


func remove_weight_from_platform(weight_id: String, is_left: bool) -> void:
"""
Remove a weight block from the specified platform.

Args:
weight_id: Unique identifier for the weight block
is_left: True for left platform, False for right
"""
var removed_mass: float = 0.0

if is_left:
if weight_id in _left_weights:
removed_mass = _left_weights[weight_id]
_left_weights.erase(weight_id)
_left_mass -= removed_mass
weight_removed.emit("left", removed_mass)
else:
if weight_id in _right_weights:
removed_mass = _right_weights[weight_id]
_right_weights.erase(weight_id)
_right_mass -= removed_mass
weight_removed.emit("right", removed_mass)

print("[BalanceScale] Weight removed - Left: %.2f kg, Right: %.2f kg" % [_left_mass, _right_mass])


func get_total_mass(is_left: bool) -> float:
"""Return total mass on specified platform"""
return _left_mass if is_left else _right_mass


func get_weight_count(is_left: bool) -> int:
"""Return number of weights on specified platform"""
return _left_weights.size() if is_left else _right_weights.size()


func clear_all_weights() -> void:
"""Remove all weights from both platforms"""
_left_weights.clear()
_right_weights.clear()
_left_mass = 0.0
_right_mass = 0.0
_reset_scale_state()
print("[BalanceScale] All weights cleared")


# ============================================================================
# ALGEBRAIC VALIDATION - EQUATION CHECKING
# ============================================================================

func _validate_algebraic_solution() -> bool:
"""
Validate that the current weight configuration solves the given equation.

The equation generator provides:
- The target equation (e.g., "3 + X = 8")
- Which side contains the variable X
- Expected mass values for verification

Validation logic:
1. Get current equation from EquationGenerator
2. Determine which platform holds X (variable block)
3. Calculate if masses satisfy the equation
4. Return true if solution is correct
"""
if not _equation_generator:
push_warning("No equation generator found - accepting any balance")
return true

# Call equation generator's validation method
if _equation_generator.has_method("validate_solution"):
var equation_data: Dictionary = _equation_generator.get_current_equation()

# Extract equation components
var x_side: String = equation_data.get("x_side", "left")
var constant_value: float = equation_data.get("constant", 0.0)
var result_value: float = equation_data.get("result", 0.0)

# Calculate expected X value from equation
var expected_x: float = 0.0

# Handle different equation types
var equation_type: String = equation_data.get("type", "addition")

match equation_type:
"addition":
# Form: constant + X = result OR X + constant = result
expected_x = result_value - constant_value
"subtraction":
# Form: constant - X = result OR X - constant = result
expected_x = constant_value - result_value
"multiplication":
# Form: constant * X = result
if constant_value != 0:
expected_x = result_value / constant_value
"division":
# Form: constant / X = result
if result_value != 0:
expected_x = constant_value / result_value

# Get actual mass of X block from appropriate platform
var x_platform_is_left: bool = (x_side == "left")
var x_mass: float = get_variable_mass(x_platform_is_left)

# Check if X mass matches expected value (with tolerance)
var tolerance: float = 0.3  # Allow small floating point differences
var is_correct: bool = abs(x_mass - expected_x) < tolerance

print("[BalanceScale] Validation - Expected X: %.2f, Actual: %.2f, Correct: %s" % 
  [expected_x, x_mass, "YES" if is_correct else "NO"])

return is_correct

return true


func get_variable_mass(from_left_platform: bool) -> float:
"""
Get the mass of the variable X block from specified platform.

Iterates through weights and returns mass of block marked as variable.
"""
var weights_dict: Dictionary = _left_weights if from_left_platform else _right_weights

for weight_id in weights_dict.keys():
# Variable blocks have special ID pattern (e.g., "weight_X_001")
if "X" in weight_id or "variable" in weight_id.to_lower():
return weights_dict[weight_id]

return 0.0


# ============================================================================
# SIGNAL HANDLERS - COLLISION DETECTION
# ============================================================================

func _on_left_platform_body_entered(body: Node3D) -> void:
"""Handle weight block entering left platform"""
if body.is_in_group("weight_blocks"):
var weight_block = body as Node
if weight_block.has_method("get_mass"):
var mass: float = weight_block.get_mass()
var weight_id: String = weight_block.name
add_weight_to_platform(weight_id, mass, true)


func _on_left_platform_body_exited(body: Node3D) -> void:
"""Handle weight block leaving left platform"""
if body.is_in_group("weight_blocks"):
remove_weight_from_platform(body.name, true)


func _on_right_platform_body_entered(body: Node3D) -> void:
"""Handle weight block entering right platform"""
if body.is_in_group("weight_blocks"):
var weight_block = body as Node
if weight_block.has_method("get_mass"):
var mass: float = weight_block.get_mass()
var weight_id: String = weight_block.name
add_weight_to_platform(weight_id, mass, false)


func _on_right_platform_body_exited(body: Node3D) -> void:
"""Handle weight block leaving right platform"""
if body.is_in_group("weight_blocks"):
remove_weight_from_platform(body.name, false)


# ============================================================================
# DEBUG & UTILITY METHODS
# ============================================================================

func get_balance_state() -> Dictionary:
"""Return complete state dictionary for debugging/saving"""
return {
"left_mass": _left_mass,
"right_mass": _right_mass,
"left_weights": _left_weights.duplicate(),
"right_weights": _right_weights.duplicate(),
"current_tilt_rad": _current_tilt,
"current_tilt_deg": rad_to_deg(_current_tilt),
"is_balanced": _is_balanced,
"target_tilt_rad": _target_tilt
}


func _print_debug_info() -> void:
"""Print detailed debug information to console"""
print("=== BALANCE SCALE DEBUG ===")
print("Left Mass: %.3f kg (%d weights)" % [_left_mass, _left_weights.size()])
print("Right Mass: %.3f kg (%d weights)" % [_right_mass, _right_weights.size()])
print("Mass Diff: %.3f kg" % abs(_left_mass - _right_mass])
print("Tilt: %.2f° (target: %.2f°)" % [rad_to_deg(_current_tilt), rad_to_deg(_target_tilt)])
print("Balanced: %s" % ("YES" if _is_balanced else "NO")]
print("===========================")
