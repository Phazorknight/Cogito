class_name AimingSystem
extends Node3D

# Region: Detection Settings
# Configurable properties for enemy detection
@export_category("Detection")
@export var detection_range: float = 50.0  ## Maximum distance for detecting enemies
@export var enemy_group: String = "enemy"  ## Group name for identifying enemy nodes
@export var layers_to_check: int = 1       ## Collision layers to check for raycast detection

# Region: Crosshair Settings
# Properties for configuring the crosshair UI
@export_category("Crosshair")
@export var hud_crosshair_path: NodePath   ## Path to the crosshair UI node
@export var crosshair_neutral_color: Color = Color.WHITE  ## Default crosshair color
@export var crosshair_enemy_color: Color = Color.RED     ## Crosshair color when aiming at an enemy

# Region: Visual Effects Settings
# Settings for visual feedback like highlighting enemies
@export_category("Visual Effects")
@export var enable_visual_effects: bool = true           ## Enable/disable visual effects
@export var highlight_enabled: bool = true              ## Enable/disable enemy highlight effect
@export var highlight_emission_energy: float = 0.8      ## Intensity of the highlight emission
@export var highlight_emission_multiplier: float = 0.4  ## Multiplier for emission color intensity

# Region: Debug Settings
# Debug-related configurations
@export_category("Debug")
@export var debug_logging: bool = true ## Enable/disable debug logging

# Region: Internal Variables
# Nodes and variables used internally by the system
@onready var camera: Camera3D = get_parent() as Camera3D  # Reference to the parent Camera3D
@onready var crosshair: Control = get_node_or_null(hud_crosshair_path)  # Reference to the crosshair UI
@onready var crosshair_texture: TextureRect = null  # TextureRect child of the crosshair node

var raycast: RayCast3D = null  # RayCast3D node for detecting objects in the camera's direction
var current_target: Node3D = null  # Currently targeted enemy node
var highlighted_meshes: Dictionary = {}  # Cache of meshes with active highlight effects
var enemy_meshes: Dictionary = {}  # Cache of mesh instances for each enemy

# Region: Signals
# Signals emitted to notify other systems of aiming events
signal enemy_detected(target: Node3D, distance: float)  # Emitted when an enemy is detected
signal enemy_lost()  # Emitted when the current target is no longer valid
signal highlight_applied(target: Node3D)  # Emitted when a highlight effect is applied
signal highlight_removed(target: Node3D)  # Emitted when a highlight effect is removed

# Region: Initialization
# Called when the node enters the scene tree
func _ready():
	_setup_camera()      # Initialize the camera reference
	_setup_raycast()    # Initialize the raycast for detection
	_setup_crosshair()  # Initialize the crosshair UI
	_log("AimingSystem initialized - Range: " + str(detection_range))  # Log initialization

# Sets up the camera reference and validates it
func _setup_camera():
	# Check if the parent node is a valid Camera3D
	if not camera or not (camera is Camera3D):
		_log("Parent is not a valid Camera3D")
		set_physics_process(false)  # Disable physics processing if camera is invalid
		return

# Configures the RayCast3D node for detecting objects
func _setup_raycast():
	raycast = get_node_or_null("RayCast3D")  # Try to get an existing RayCast3D node
	if not raycast:
		raycast = RayCast3D.new()  # Create a new RayCast3D if none exists
		raycast.name = "RayCast3D"
		add_child(raycast)  # Add it as a child of this node
	
	# Configure raycast properties
	raycast.enabled = true
	raycast.collide_with_areas = false  # Ignore area collisions
	raycast.collision_mask = layers_to_check  # Set collision layers to check
	raycast.target_position = Vector3(0, 0, -detection_range)  # Set raycast length
	_log("RayCast3D configured")

# Sets up the crosshair UI
func _setup_crosshair():
	# Validate and configure the crosshair node
	if crosshair and is_instance_valid(crosshair) and crosshair.get_child_count() > 0:
		crosshair_texture = crosshair.get_child(0) as TextureRect  # Get the TextureRect child
		if crosshair_texture and is_instance_valid(crosshair_texture):
			crosshair_texture.modulate = crosshair_neutral_color  # Set default color
			_log("Crosshair configured")
		else:
			_log("Could not obtain TextureRect from crosshair")
	else:
		_log("Crosshair not found at: " + str(hud_crosshair_path))
		set_physics_process(false)  # Disable physics processing if crosshair is invalid
		return

# Region: Main Processing
# Called every physics frame to update the aiming system
func _physics_process(_delta):
	if not _is_system_ready():  # Check if the system is ready to process
		return

	raycast.global_transform = camera.global_transform  # Align raycast with camera

	# Check if the current target is no longer valid
	if current_target and not _is_valid_enemy(current_target):
		_log("Current target is invalid (destroyed or removed)")
		_clear_target()  # Clear the current target

	# Check for raycast collisions
	if raycast.is_colliding():
		var collider = raycast.get_collider()  # Get the collided object
		if _is_valid_enemy(collider) and collider != current_target:
			_set_new_target(collider)  # Set a new target if a valid enemy is detected
		elif not _is_valid_enemy(collider) and current_target:
			_clear_target()  # Clear target if no valid enemy is detected
	elif current_target:
		_clear_target()  # Clear target if raycast is not colliding

# Region: Target Management
# Sets a new target and updates related systems
func _set_new_target(target: Node3D):
	_clear_target()  # Clear any existing target
	current_target = target  # Set the new target
	
	# Connect to the target's tree_exited signal to handle its removal
	if not current_target.tree_exited.is_connected(_on_target_exited):
		current_target.tree_exited.connect(_on_target_exited, CONNECT_ONE_SHOT)
	
	_update_crosshair_color(true)  # Update crosshair to enemy color
	
	# Calculate distance to the target
	var distance = camera.global_position.distance_to(raycast.get_collision_point())
	enemy_detected.emit(target, distance)  # Emit signal with target and distance
	
	# Apply highlight effect if enabled
	if enable_visual_effects and highlight_enabled:
		_apply_highlight_effect(target)
	
	_log("Enemy detected: " + target.name + " at " + "%.1f" % distance + "m")

# Clears the current target and resets related systems
func _clear_target():
	if current_target:
		if enable_visual_effects and highlight_enabled:
			_remove_highlight_effect(current_target)  # Remove highlight effect
		current_target = null  # Clear the target reference
	
	_update_crosshair_color(false)  # Reset crosshair to neutral color
	enemy_lost.emit()  # Emit signal for target loss

# Handles the event when the target is removed from the scene
func _on_target_exited():
	_log("Target destroyed")
	_clear_target()  # Clear the target

# Region: Highlight System
# Applies a highlight effect to the target
func _apply_highlight_effect(target: Node3D):
	if not _is_valid_enemy(target) or target in highlighted_meshes:
		return  # Skip if target is invalid or already highlighted

	# Get mesh instances for the target
	var mesh_instances = enemy_meshes.get(target, _find_mesh_instances(target))
	if not enemy_meshes.has(target):
		enemy_meshes[target] = mesh_instances  # Cache mesh instances

	var materials_applied = []
	
	# Apply highlight material to each valid mesh
	for mesh in mesh_instances:
		if not is_instance_valid(mesh) or mesh.material_override:
			continue
		
		# Create a highlight material with emission
		var highlight_mat = StandardMaterial3D.new()
		highlight_mat.emission_enabled = true
		highlight_mat.emission = crosshair_enemy_color * highlight_emission_multiplier
		highlight_mat.emission_energy = highlight_emission_energy
		mesh.material_override = highlight_mat
		
		materials_applied.append({"mesh": mesh, "material": highlight_mat})
	
	if materials_applied:
		highlighted_meshes[target] = materials_applied  # Cache applied materials
		highlight_applied.emit(target)  # Emit signal for highlight application
		_log(" Highlight applied to: " + target.name)

# Removes the highlight effect from the target
func _remove_highlight_effect(target: Node3D):
	if not target or not highlighted_meshes.has(target):
		return  # Skip if target is invalid or not highlighted
	
	# Remove highlight material from each mesh
	for applied in highlighted_meshes[target]:
		var mesh = applied["mesh"]
		if is_instance_valid(mesh):
			mesh.material_override = null  # Reset material
	
	highlighted_meshes.erase(target)  # Remove from highlight cache
	enemy_meshes.erase(target)  # Remove from mesh cache
	highlight_removed.emit(target)  # Emit signal for highlight removal
	_log("Highlight removed from: " + (target.name if is_instance_valid(target) else "Unknown"))

# Region: Utilities
# Checks if a node is a valid enemy
func _is_valid_enemy(node) -> bool:
	return node and is_instance_valid(node) and node.is_inside_tree() and node.is_in_group(enemy_group)

# Checks if the system is ready to operate
func _is_system_ready() -> bool:
	return is_instance_valid(raycast) and is_instance_valid(camera)

# Updates the crosshair color based on target status
func _update_crosshair_color(is_enemy: bool):
	if crosshair_texture:
		crosshair_texture.modulate = crosshair_enemy_color if is_enemy else crosshair_neutral_color
		_log("Crosshair set to red: enemy detected" if is_enemy else "⚪ Crosshair restored to white")

# Finds all MeshInstance3D nodes in a node's hierarchy
func _find_mesh_instances(node: Node3D) -> Array:
	var meshes = []
	if node and is_instance_valid(node) and node is MeshInstance3D:
		meshes.append(node)  # Add the node if it's a MeshInstance3D
	for child in node.get_children():
		if child is Node3D:
			meshes.append_array(_find_mesh_instances(child))  # Recursively find meshes in children
	return meshes

# Logs a message if debug logging is enabled
func _log(message: String):
	if debug_logging:
		print(message)

# Region: Public API
# Returns the current target
func get_current_target() -> Node3D:
	return current_target

# Checks if the system is aiming at a valid enemy
func is_aiming_at_enemy() -> bool:
	return current_target != null and _is_valid_enemy(current_target)

# Toggles the visibility of the crosshair
func set_aiming_mode(aiming: bool):
	if crosshair:
		crosshair.visible = aiming
		if aiming and not current_target and crosshair_texture:
			crosshair_texture.modulate = crosshair_neutral_color  # Reset to neutral color
			_log(" Crosshair set to neutral when enabling aiming mode")

# Updates the crosshair colors
func update_crosshair_colors(neutral: Color, enemy: Color):
	crosshair_neutral_color = neutral
	crosshair_enemy_color = enemy
	if crosshair_texture:
		crosshair_texture.modulate = crosshair_neutral_color if not current_target else crosshair_enemy_color
		_log(" Crosshair colors updated")

# Clears all highlight effects
func clear_all_highlights():
	for target in highlighted_meshes.keys().duplicate():
		_remove_highlight_effect(target)
	_log("All highlights removed")

# Toggles the highlight effect
func toggle_highlights(enabled: bool):
	highlight_enabled = enabled
	if not enabled:
		clear_all_highlights()  # Clear highlights if disabled
	_log(" Highlights " + ("enabled" if enabled else "disabled"))

# Updates the highlight effect intensity
func set_highlight_intensity(energy: float, multiplier: float):
	highlight_emission_energy = energy
	highlight_emission_multiplier = multiplier
	_log(" Highlight intensity updated: Energy=" + str(energy) + ", Multiplier=" + str(multiplier))

# Public method to check if the system is ready
func is_system_ready() -> bool:
	return _is_system_ready()

# Called when the node exits the scene tree
func _exit_tree():
	_clear_target()  # Clear the current target
	clear_all_highlights()  # Remove all highlights
	if is_instance_valid(raycast):
		raycast.queue_free()  # Free the raycast node
