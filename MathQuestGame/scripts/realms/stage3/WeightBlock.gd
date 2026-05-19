extends RigidBody3D
## WeightBlock - Interactive Algebra Weight System
## Represents physical weight blocks that can be dragged, dropped, and placed on scale platforms.
## Supports fixed mass values and variable X blocks for algebraic problem solving.
## Implements socket snapping, haptic feedback, and collision detection.

class_name WeightBlock

# ============================================================================
# SIGNALS
# ============================================================================

signal block_picked_up(block: WeightBlock)
signal block_placed(block: WeightBlock, platform: String)
signal block_socketed(block: WeightBlock, socket_name: String)

# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

const SNAP_DISTANCE: float = 0.3  # meters - distance for auto-snapping to sockets
const LERP_SPEED: float = 12.0  # interpolation speed for smooth movement
const ROTATION_SNAP_SPEED: float = 8.0  # rotation snap speed
const MIN_MASS: float = 0.5  # kg - minimum block mass
const MAX_MASS: float = 10.0  # kg - maximum block mass
const VARIABLE_MASS_COLOR: Color = Color(1.0, 0.4, 0.2, 1.0)  # Orange-red for X blocks
const FIXED_MASS_COLORS: Array[Color] = [
	Color(0.3, 0.7, 1.0, 1.0),  # Blue - 1kg
	Color(0.3, 1.0, 0.5, 1.0),  # Green - 2kg
	Color(1.0, 0.9, 0.3, 1.0),  # Yellow - 5kg
	Color(1.0, 0.5, 0.8, 1.0)   # Pink - 10kg
]

# Interaction states
enum BlockState {
	IDLE,           # Resting on surface
	DRAGGING,       # Being held by player
	SNAPPING,       # Auto-snapping to socket
	FALLING,        # In free fall
	SOCKETED        # Locked in socket
}

# ============================================================================
# PROPERTIES
# ============================================================================

# Block configuration
@export_group("Block Configuration")
@export var mass_value: float = 1.0
@export var is_variable_block: bool = false  # True if this represents X
@export var block_label: String = "1"  # Display label (e.g., "1", "2", "X")
@export var socket_compatible: bool = true

# Visual properties
@export_group("Visual Properties")
@export var base_color: Color = Color(0.3, 0.7, 1.0, 1.0)
@export var emissive_strength: float = 0.2
@export var show_mass_label: bool = true

# Physics properties
@export_group("Physics Properties")
@export var linear_damping_custom: float = 0.5
@export var angular_damping_custom: float = 0.8
@export var friction_coefficient: float = 0.7

# Runtime state
var current_state: BlockState = BlockState.IDLE
var is_being_dragged: bool = false
var target_socket: Node3D = null
var original_transform: Transform3D
var _drag_plane: Plane
var _last_platform: String = ""
var _mesh_instance: MeshInstance3D
var _label_3d: Label3D

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	_initialize_block()
	_setup_visuals()
	_setup_physics()

func _physics_process(delta: float) -> void:
	match current_state:
		BlockState.DRAGGING:
			_handle_dragging(delta)
		BlockState.SNAPPING:
			_handle_snapping(delta)
		BlockState.FALLING:
			_handle_falling(delta)

func _input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_start_drag()
		elif mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			_end_drag()

# ============================================================================
# INITIALIZATION
# ============================================================================

func _initialize_block() -> void:
	"""Initialize block properties and state."""
	original_transform = transform
	
	# Set mass based on configuration
	if is_variable_block:
		mass_value = 1.0  # Variable blocks have symbolic value
		block_label = "X"
	else:
		mass_value = clamp(mass_value, MIN_MASS, MAX_MASS)
		block_label = str(int(mass_value)) if mass_value == int(mass_value) else str(mass_value)
	
	print("[WeightBlock] Initialized: %.1f kg, variable=%s, label='%s'" % [mass_value, is_variable_block, block_label])

func _setup_visuals() -> void:
	"""Configure visual appearance based on block type."""
	# Find or create mesh instance
	_mesh_instance = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if not _mesh_instance:
		_create_default_mesh()
	
	# Set color based on block type
	if is_variable_block:
		base_color = VARIABLE_MASS_COLOR
	else:
		var color_index: int = int(mass_value) % FIXED_MASS_COLORS.size()
		base_color = FIXED_MASS_COLORS[color_index]
	
	# Apply material
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.emission_enabled = true
	material.emission = base_color * emissive_strength
	material.roughness = 0.4
	metallic = 0.6
	
	if _mesh_instance:
		_mesh_instance.surface_set_material(0, material)
	
	# Create 3D label
	_create_mass_label()

func _create_default_mesh() -> void:
	"""Create a default cube mesh if none exists."""
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.4, 0.4, 0.4)
	
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = mesh
	_mesh_instance.name = "MeshInstance3D"
	add_child(_mesh_instance)

func _create_mass_label() -> void:
	"""Create a 3D label showing the mass value."""
	if not show_mass_label:
		return
	
	_label_3d = Label3D.new()
	_label_3d.text = block_label
	_label_3d.font_size = 24
	_label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_3d.fixed_aabb = AABB(Vector3(-0.5, -0.5, -0.5), Vector3(1.0, 1.0, 1.0))
	_label_3d.position = Vector3(0, 0.3, 0)
	_label_3d.modulate = Color.WHITE
	add_child(_label_3d)

func _setup_physics() -> void:
	"""Configure physics properties."""
	mass = mass_value
	linear_damping = linear_damping_custom
	angular_damping = angular_damping_custom
	
	var physics_mat: PhysicsMaterial = PhysicsMaterial.new()
	physics_mat.friction = friction_coefficient
	physics_mat.bounce = 0.2
	physics_material_override = physics_mat
	
	# Enable contact monitoring for platform detection
	contact_monitor = true
	max_contacts_reported = 4

# ============================================================================
# INTERACTION HANDLING
# ============================================================================

func _start_drag() -> void:
	"""Begin dragging the block."""
	if current_state == BlockState.SOCKETED:
		return  # Can't drag socketed blocks without unlocking
	
	is_being_dragged = true
	current_state = BlockState.DRAGGING
	
	# Create drag plane at block's current height
	_drag_plane = Plane(Vector3.UP, global_position.y)
	
	# Disable gravity temporarily
	gravity_scale = 0.0
	sleeping = false
	
	# Emit signal
	block_picked_up.emit(self)
	
	# Haptic feedback
	if NativeBridge:
		NativeBridge.trigger_haptic(NativeBridge.HAPTIC_PATTERN_LIGHT)
	
	print("[WeightBlock] Drag started: %s" % block_label)

func _end_drag() -> void:
	"""End dragging and release block."""
	is_being_dragged = false
	
	# Re-enable gravity
	gravity_scale = 1.0
	
	# Check for nearby sockets
	var nearby_socket: Node3D = _find_nearby_socket()
	if nearby_socket:
		target_socket = nearby_socket
		current_state = BlockState.SNAPPING
		print("[WeightBlock] Snapping to socket: %s" % target_socket.name)
	else:
		current_state = BlockState.FALLING
		print("[WeightBlock] Released, falling...")

func _handle_dragging(delta: float) -> void:
	"""Handle block movement while being dragged."""
	if not is_being_dragged:
		return
	
	# Raycast from camera to drag plane
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return
	
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * 100.0
	
	var intersection: Variant = _drag_plane.intersects_ray(from, to)
	if intersection:
		var target_pos: Vector3 = intersection as Vector3
		global_position = global_position.lerp(target_pos, LERP_SPEED * delta)
		
		# Rotate to face camera slightly
		var look_target: Vector3 = global_position + camera.global_transform.basis.z
		global_rotation.y = lerp_angle(global_rotation.y, atan2(look_target.x - global_position.x, look_target.z - global_position.z), ROTATION_SNAP_SPEED * delta)

func _handle_snapping(delta: float) -> void:
	"""Handle automatic snapping to socket."""
	if not target_socket:
		current_state = BlockState.FALLING
		return
	
	var socket_pos: Vector3 = target_socket.global_position
	var distance: float = global_position.distance_to(socket_pos)
	
	if distance < 0.05:
		# Snap complete
		global_position = socket_pos
		global_rotation = target_socket.global_rotation
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		current_state = BlockState.SOCKETED
		
		# Determine platform side
		var platform_name: String = _determine_platform_side(target_socket)
		block_placed.emit(self, platform_name)
		block_socketed.emit(self, target_socket.name)
		
		print("[WeightBlock] Socketed to %s on %s" % [target_socket.name, platform_name])
	else:
		# Move toward socket
		global_position = global_position.lerp(socket_pos, LERP_SPEED * 2.0 * delta)
		global_rotation = global_rotation.slerp(target_socket.global_rotation, ROTATION_SNAP_SPEED * delta)

func _handle_falling(delta: float) -> void:
	"""Handle block falling under gravity."""
	if is_on_floor():
		current_state = BlockState.IDLE
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		
		# Determine which platform we landed on
		var platform: String = _determine_landing_platform()
		if not platform.is_empty():
			block_placed.emit(self, platform)
			_last_platform = platform
		
		print("[WeightBlock] Landed on %s" % platform)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func _find_nearby_socket() -> Node3D:
	"""Find the nearest compatible socket within snap distance."""
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.collision_mask = 1 | 4  # World geometry and sockets
	query.max_collisions = 10
	
	var sphere_shape: SphereShape3D = SphereShape3D.new()
	sphere_shape.radius = SNAP_DISTANCE
	query.shape = sphere_shape
	query.transform = global_transform
	
	var results: Array[Dictionary] = space_state.intersect_shape(query)
	
	for result in results:
		var collider: Node = result.get("collider")
		if collider and collider.has_meta("is_socket") and collider.get_meta("is_socket"):
			if collider.get("socket_compatible", true):
				return collider as Node3D
	
	return null

func _determine_platform_side(socket: Node3D) -> String:
	"""Determine which platform side a socket belongs to."""
	var parent: Node = socket.get_parent()
	while parent:
		if parent.name.contains("Left"):
			return "left"
		elif parent.name.contains("Right"):
			return "right"
		parent = parent.get_parent()
	
	return "unknown"

func _determine_landing_platform() -> String:
	"""Determine which platform the block landed on."""
	for i in range(get_contact_count()):
		var collider: Node = get_contact_collider(i)
		if collider:
			var collider_name: String = collider.name.to_lower()
			if "left" in collider_name or "platform_left" in collider_name:
				return "left"
			elif "right" in collider_name or "platform_right" in collider_name:
				return "right"
	
	return ""

func get_mass_value() -> float:
	"""Return the mass value of this block (for BalanceScale integration)."""
	return mass_value

func set_variable(is_variable: bool) -> void:
	"""Toggle variable block status."""
	is_variable_block = is_variable
	_setup_visuals()

func unlock_from_socket() -> void:
	"""Allow block to be picked up from socketed state."""
	if current_state == BlockState.SOCKETED:
		current_state = BlockState.IDLE

# ============================================================================
# DEBUG & UTILITIES
# ============================================================================

func get_block_info() -> Dictionary:
	"""Return detailed block information."""
	return {
		"mass": mass_value,
		"is_variable": is_variable_block,
		"label": block_label,
		"state": BlockState.keys()[current_state],
		"position": global_position,
		"velocity": linear_velocity,
		"is_dragging": is_being_dragged,
		"last_platform": _last_platform
	}

func debug_print_info() -> void:
	"""Print block info to console."""
	var info: Dictionary = get_block_info()
	print("=== WEIGHT BLOCK INFO ===")
	for key in info:
		print("  %s: %s" % [key, info[key]])
	print("=========================")
