class_name WeightBlock
extends RigidBody3D
## WeightBlock - Interactive weight entity for the Balance Scale puzzle.
## Represents physical weight blocks (both numeric and variable X blocks).
## Handles drag-and-drop interaction, mass visualization, and socket snapping.

# ============================================================================
# SIGNALS
# ============================================================================

signal block_picked_up(block_id: String)
signal block_placed(block_id: String, platform: int)
signal block_dropped(block_id: String)

# ============================================================================
# CONSTANTS
# ============================================================================

const PICKUP_FORCE: float = 15.0
const SNAP_DISTANCE: float = 2.5
const SOCKET_SNAP_THRESHOLD: float = 0.8

# ============================================================================
# EXPORTED PROPERTIES
# ============================================================================

@export_group("Weight Properties")
@export var block_mass: float = 1.0  # Physical mass in kg
@export var is_variable_block: bool = false  # Is this an X block?
@export var block_value: int = 1  # Numeric value displayed on block
@export var block_color: Color = Color.WHITE  # Visual color

@export_group("Interaction")
@export var can_be_picked: bool = true
@export var snap_to_sockets: bool = true
@export var pickup_height: float = 1.5  # Height when held

@export_group("Visual References")
@export var mesh_instance: MeshInstance3D
@export var label_3d: Label3D
@export var glow_emission: float = 0.5

# ============================================================================
# STATE VARIABLES
# ============================================================================

var block_id: String = ""
var is_being_held: bool = false
var is_snapped: bool = false
var current_socket: Node3D = null
var original_position: Vector3 = Vector3.ZERO
var original_collision_layer: int = 0

var _camera: Camera3D
var _raycast: RayCast3D
var _collision_shape: CollisionShape3D
var _original_mass: float
var _lerp_velocity: Vector3 = Vector3.ZERO

# ============================================================================
# LIFECYCLE METHODS
# ============================================================================

func _ready() -> void:
	_generate_block_id()
	_setup_visuals()
	_setup_physics()
	_store_original_state()

func _physics_process(delta: float) -> void:
	if is_being_held:
		_update_held_position(delta)
	elif is_snapped and current_socket:
		_snap_to_socket()

func _input(event: InputEvent) -> void:
	if not can_be_picked or is_snapped:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_pickup()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and is_being_held:
			_release_block()

# ============================================================================
# INITIALIZATION
# ============================================================================

func _generate_block_id() -> void:
	block_id = "weight_%s_%s" % [block_value if not is_variable_block else "X", randi() % 10000]

func _setup_visuals() -> void:
	if mesh_instance:
		# Apply block color with emission for "glowing" effect
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = block_color
		material.emission_enabled = true
		material.emission = block_color * glow_emission
		mesh_instance.set_surface_override_material(0, material)
	
	if label_3d:
		if is_variable_block:
			label_3d.text = "X"
		else:
			label_3d.text = str(block_value)
		label_3d.modulate = block_color.darkened(0.5)

func _setup_physics() -> void:
	mass = block_mass
	_original_mass = block_mass
	
	# Configure collision layers
	collision_layer = 1 << 4  # Layer 5: Weight Blocks
	collision_mask = 1 | 1 << 3  # World Geometry + Scale Platforms
	
	# Disable initial physics simulation if not being held
	sleeping = true
	can_sleep = true

func _store_original_state() -> void:
	original_position = global_position
	original_collision_layer = collision_layer

# ============================================================================
# PICKUP & RELEASE MECHANICS
# ============================================================================

func _try_pickup() -> void:
	# Check if mouse is hovering over this block
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	
	var mouse_position: Vector2 = viewport.get_mouse_position()
	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return
	
	# Raycast from camera through mouse position
	var from: Vector3 = camera.project_ray_origin(mouse_position)
	var to: Vector3 = from + camera.project_ray_normal(mouse_position) * 50.0
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.exclude = [self]
	
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return
	
	var hit_object: Node3D = result.collider as Node3D
	if hit_object != self and not is_ancestor_of(hit_object):
		return
	
	# Pick up the block
	_pickup_block(camera)

func _pickup_block(camera: Camera3D) -> void:
	is_being_held = true
	_camera = camera
	sleeping = false
	
	# Temporarily disable collision while holding
	collision_layer = 0
	
	# Store velocity for smooth release
	_lerp_velocity = linear_velocity
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	block_picked_up.emit(block_id)
	
	# Haptic feedback
	if NativeBridge:
		NativeBridge.trigger_haptic(NativeBridge.HAPTIC_PATTERN_LIGHT)

func _release_block() -> void:
	if not is_being_held:
		return
	
	is_being_held = false
	_camera = null
	
	# Restore collision
	collision_layer = original_collision_layer
	
	# Check for socket snap
	var snapped: bool = _try_snap_to_socket()
	
	if not snapped:
		# Apply release velocity
		linear_velocity = _lerp_velocity
		angular_velocity = Vector3.ZERO(randf(), randf(), randf()) * 2.0
		
		block_dropped.emit(block_id)
	else:
		block_placed.emit(block_id, current_socket.get_meta("platform", -1))

# ============================================================================
# HELD POSITION UPDATE
# ============================================================================

func _update_held_position(delta: float) -> void:
	if _camera == null:
		return
	
	var viewport: Viewport = get_viewport()
	var mouse_position: Vector2 = viewport.get_mouse_position()
	
	var from: Vector3 = _camera.project_ray_origin(mouse_position)
	var direction: Vector3 = _camera.project_ray_normal(mouse_position)
	var target_position: Vector3 = from + direction * pickup_height
	
	# Smooth lerp to target position
	_lerp_velocity = (target_position - global_position) * 10.0
	global_position = global_position.lerp(target_position, delta * 15.0)
	
	# Keep block oriented towards camera
	look_at(_camera.global_position, Vector3.UP)

# ============================================================================
# SOCKET SNAPPING
# ============================================================================

func _try_snap_to_socket() -> bool:
	if not snap_to_sockets:
		return false
	
	# Find nearby sockets
	var sockets: Array = _get_nearby_sockets()
	
	for socket in sockets:
		var distance: float = global_position.distance_to(socket.global_position)
		if distance <= SOCKET_SNAP_THRESHOLD:
			_snap_to_socket_target(socket)
			return true
	
	return false

func _get_nearby_sockets() -> Array:
	var sockets: Array = []
	var tree: SceneTree = get_tree()
	
	# Search for socket nodes in the scene
	for node in tree.get_nodes_in_group("scale_sockets"):
		if node is Node3D:
			var distance: float = global_position.distance_to(node.global_position)
			if distance <= SNAP_DISTANCE:
				sockets.append(node)
	
	return sockets

func _snap_to_socket_target(socket: Node3D) -> void:
	current_socket = socket
	is_snapped = true
	is_being_held = false
	
	# Snap position exactly
	global_position = socket.global_position
	
	# Disable physics when snapped
	sleeping = true
	collision_layer = 0
	
	socket.set_meta("occupied", true)
	socket.set_meta("current_block", self)

func _snap_to_socket() -> void:
	if current_socket:
		global_position = current_socket.global_position

# ============================================================================
# UNSNAP & RESET
# ============================================================================

func unsnap() -> void:
	if not is_snapped or current_socket == null:
		return
	
	current_socket.set_meta("occupied", false)
	current_socket.set_meta("current_block", null)
	current_socket = null
	is_snapped = false
	
	# Re-enable physics
	sleeping = false
	collision_layer = original_collision_layer

func reset_block() -> void:
	unsnap()
	is_being_held = false
	global_position = original_position
	rotation_degrees = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true

# ============================================================================
# VISUAL UPDATES
# ============================================================================

func update_glow(intensity: float) -> void:
	glow_emission = intensity
	if mesh_instance:
		var material: StandardMaterial3D = mesh_instance.get_surface_override_material(0)
		if material:
			material.emission = block_color * intensity

func set_highlighted(highlighted: bool) -> void:
	if highlighted:
		update_glow(glow_emission * 2.0)
	else:
		update_glow(glow_emission)

# ============================================================================
# GETTERS
# ============================================================================

func get_mass() -> float:
	return block_mass

func get_value() -> int:
	return block_value if not is_variable_block else 0

func is_variable() -> bool:
	return is_variable_block

func get_display_text() -> String:
	return "X" if is_variable_block else str(block_value)

# ============================================================================
# CALLBACK HANDLERS
# ============================================================================

func _on_socket_detected(area: Area3D) -> void:
	if is_being_held and snap_to_sockets:
		if area.is_in_group("scale_sockets"):
			_try_snap_to_socket()

# ============================================================================
# DEBUG
# ============================================================================

func print_debug_info() -> void:
	print(f"[WeightBlock {block_id}]")
	print(f"  Mass: {block_mass} kg")
	print(f"  Value: {block_value}")
	print(f"  Is Variable: {is_variable_block}")
	print(f"  Position: {global_position}")
	print(f"  Is Held: {is_being_held}")
	print(f"  Is Snapped: {is_snapped}")
	print(f"  Current Socket: {current_socket.name if current_socket else 'None'}")
