class_name AimingSystem
extends Node3D

# Region: Detection Settings
@export_category("Detection")
@export var camera: Camera3D  ## Reference to the Camera3D (set via export)
@export var detection_range: float = 50.0  ## Maximum distance for detecting enemies
@export var enemy_groups: Array[String] = ["enemy"]  ## Array of group names for identifying enemy nodes
@export var layers_to_check: int = 1       ## Collision layers to check for raycast detection

# Region: Crosshair Settings
@export_category("Crosshair")
@export var crosshair: Control  ## Reference to the crosshair UI node (set via export)
@export var distance_label: Label  ## Label to show distance to enemy
@export var enable_distance_label: bool = true  ## Enable/disable the distance label
@export var distance_label_font: Font  ## Font for the distance label
@export var distance_label_font_size: int = 18  ## Font size for the distance label
@export var distance_label_color: Color = Color.YELLOW  ## Text color for the distance label
@export var crosshair_neutral_color: Color = Color.WHITE  ## Default crosshair color
@export var crosshair_enemy_color: Color = Color.RED     ## Crosshair color when aiming at an enemy

# Region: Visual Effects Settings
@export_category("Visual Effects")
@export var enable_visual_effects: bool = true           ## Enable/disable visual effects
@export var highlight_enabled: bool = true              ## Enable/disable enemy highlight effect
@export var use_shader: bool = true                     ## Enable/disable shader-based highlight
@export var highlight_shader: Shader                    ## Shader for highlight effect
@export var highlight_color: Color = Color.RED          ## Shader highlight color
@export var outline_thickness: float = 0.01             ## Shader outline thickness
@export var highlight_intensity: float = 1.0            ## Shader highlight intensity
@export var pulse_speed: float = 1.0                    ## Speed of the pulsing effect in the shader
@export var dissolve_amount: float = 0.0                ## Amount of dissolve effect in the shader (0.0 = fully visible, 1.0 = fully dissolved)
@export var highlight_emission_energy: float = 0.8      ## Intensity of the highlight emission (fallback)
@export var highlight_emission_multiplier: float = 0.4  ## Multiplier for emission color intensity (fallback)

# Region: Debug Settings
@export_category("Debug")
@export var debug_logging: bool = true ## Enable/disable debug logging

# Region: Internal Variables
@onready var crosshair_texture: TextureRect = null  # TextureRect child of the crosshair node
var raycast: RayCast3D = null  # RayCast3D node for detecting objects
var current_target: Node3D = null  # Currently targeted enemy node
var highlighted_meshes: Dictionary = {}  # Cache of meshes with active highlight effects
var enemy_meshes: Dictionary = {}  # Cache of mesh instances for each enemy

# Region: Signals
signal enemy_detected(target: Node3D, distance: float)
signal enemy_lost()
signal highlight_applied(target: Node3D)
signal highlight_removed(target: Node3D)

# Region: Initialization
func _ready():
	_setup_camera()      # Validate the exported camera
	_setup_crosshair()  # Validate the exported crosshair
	_setup_distance_label()  # Validate and configure the distance label
	_setup_raycast()    # Initialize the raycast
	_log("🎯 AimingSystem initialized - Range: " + str(detection_range) + " - Enemy Groups: " + str(enemy_groups))

# Validates the exported Camera3D
func _setup_camera():
	if not camera or not (camera is Camera3D) or not is_instance_valid(camera):
		_log("❌ No valid Camera3D assigned")
		set_physics_process(false)
		return
	_log("✅ Camera3D assigned: " + camera.name)

# Validates the exported crosshair and its TextureRect child
func _setup_crosshair():
	if crosshair and is_instance_valid(crosshair) and crosshair.get_child_count() > 0:
		crosshair_texture = crosshair.get_child(0) as TextureRect
		if crosshair_texture and is_instance_valid(crosshair_texture):
			crosshair_texture.modulate = crosshair_neutral_color
			_log("✅ Crosshair configured")
		else:
			_log("❌ Crosshair TextureRect invalid")
			set_physics_process(false)
	else:
		_log("❌ No valid Crosshair assigned")
		set_physics_process(false)

# Validates and configures the exported DistanceLabel
func _setup_distance_label():
	if distance_label and is_instance_valid(distance_label):
		distance_label.text = ""  # Initialize empty
		distance_label.visible = enable_distance_label  # Set visibility based on enable_distance_label
		if distance_label_font:
			distance_label.add_theme_font_override("font", distance_label_font)
		distance_label.add_theme_font_size_override("font_size", distance_label_font_size)
		distance_label.add_theme_color_override("font_color", distance_label_color)
		distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_log("✅ DistanceLabel configured with font size: " + str(distance_label_font_size) + ", color: " + str(distance_label_color))
	else:
		_log("⚠️ DistanceLabel not assigned or invalid")

# Configures the RayCast3D node
func _setup_raycast():
	raycast = get_node_or_null("RayCast3D")
	if not raycast:
		raycast = RayCast3D.new()
		raycast.name = "RayCast3D"
		add_child(raycast)
	
	raycast.enabled = true
	raycast.collide_with_areas = false
	raycast.collision_mask = layers_to_check
	raycast.target_position = Vector3(0, 0, -detection_range)
	_log("✅ RayCast3D configured")

# Region: Main Processing
func _physics_process(_delta):
	if not _is_system_ready():
		return

	raycast.global_transform = camera.global_transform

	if current_target and not _is_valid_enemy(current_target):
		_log("⚠️ Current target is invalid")
		_clear_target()
		return

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if _is_valid_enemy(collider) and collider != current_target:
			_set_new_target(collider)
		elif not _is_valid_enemy(collider) and current_target:
			_clear_target()
		elif current_target and _is_valid_enemy(collider):
			var distance = camera.global_position.distance_to(raycast.get_collision_point())
			if distance_label and enable_distance_label:
				distance_label.text = "%.1f m" % distance
	elif current_target:
		_clear_target()

# Region: Target Management
func _set_new_target(target: Node3D):
	_clear_target()
	current_target = target
	
	if not current_target.tree_exited.is_connected(_on_target_exited):
		current_target.tree_exited.connect(_on_target_exited, CONNECT_ONE_SHOT)
	
	_update_crosshair_color(true)
	
	var distance = camera.global_position.distance_to(raycast.get_collision_point())
	if distance_label and enable_distance_label:
		distance_label.text = "%.1f m" % distance
	
	enemy_detected.emit(target, distance)
	
	if enable_visual_effects and highlight_enabled:
		_apply_highlight_effect(target)
	
	_log("🎯 Enemy detected: " + target.name + " at " + "%.1f" % distance + "m")

func _clear_target():
	if current_target:
		if enable_visual_effects and highlight_enabled:
			_remove_highlight_effect(current_target)
		current_target = null
	
	_update_crosshair_color(false)
	if distance_label and enable_distance_label:
		distance_label.text = ""
	enemy_lost.emit()

func _on_target_exited():
	_log("⚠️ Target destroyed")
	_clear_target()

# Region: Highlight System
func _apply_highlight_effect(target: Node3D):
	if not _is_valid_enemy(target) or target in highlighted_meshes:
		return

	var mesh_instances = enemy_meshes.get(target, _find_mesh_instances(target))
	if not enemy_meshes.has(target):
		enemy_meshes[target] = mesh_instances

	var materials_applied = []
	for mesh in mesh_instances:
		if not is_instance_valid(mesh) or mesh.material_override:
			continue
		var highlight_mat
		if use_shader and highlight_shader:
			highlight_mat = ShaderMaterial.new()
			highlight_mat.shader = highlight_shader
			highlight_mat.set_shader_parameter("highlight_color", highlight_color)
			highlight_mat.set_shader_parameter("outline_thickness", outline_thickness)
			highlight_mat.set_shader_parameter("highlight_intensity", highlight_intensity)
			highlight_mat.set_shader_parameter("pulse_speed", pulse_speed)  # New parameter
			highlight_mat.set_shader_parameter("dissolve_amount", dissolve_amount)  # New parameter
		else:
			highlight_mat = StandardMaterial3D.new()
			highlight_mat.emission_enabled = true
			highlight_mat.emission = crosshair_enemy_color * highlight_emission_multiplier
			highlight_mat.emission_energy = highlight_emission_energy
		mesh.material_override = highlight_mat
		materials_applied.append({"mesh": mesh, "material": highlight_mat})
	
	if materials_applied:
		highlighted_meshes[target] = materials_applied
		highlight_applied.emit(target)
		_log("✨ Highlight applied to: " + target.name)

func _remove_highlight_effect(target: Node3D):
	if not target or not highlighted_meshes.has(target):
		return
	
	for applied in highlighted_meshes[target]:
		var mesh = applied["mesh"]
		if is_instance_valid(mesh):
			mesh.material_override = null
	
	highlighted_meshes.erase(target)
	enemy_meshes.erase(target)
	highlight_removed.emit(target)
	_log("🧹 Highlight removed from: " + (target.name if is_instance_valid(target) else "Unknown"))

# Region: Utilities
func _is_valid_enemy(node) -> bool:
	if not node or not is_instance_valid(node) or not node.is_inside_tree():
		return false
	for group in enemy_groups:
		if node.is_in_group(group):
			return true
	return false

func _is_system_ready() -> bool:
	return is_instance_valid(raycast) and is_instance_valid(camera) and is_instance_valid(crosshair)

func _update_crosshair_color(is_enemy: bool):
	if crosshair_texture:
		crosshair_texture.modulate = crosshair_enemy_color if is_enemy else crosshair_neutral_color
		_log("🔴 Crosshair set to red: enemy detected" if is_enemy else "⚪ Crosshair restored to white")

func _find_mesh_instances(node: Node3D) -> Array:
	var meshes = []
	if node and is_instance_valid(node) and node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		if child is Node3D:
			meshes.append_array(_find_mesh_instances(child))
	return meshes

func _log(message: String):
	if debug_logging:
		print(message)

# Region: Public API
func get_current_target() -> Node3D:
	return current_target

func is_aiming_at_enemy() -> bool:
	return current_target != null and _is_valid_enemy(current_target)

func set_aiming_mode(aiming: bool):
	if crosshair:
		crosshair.visible = aiming
		if aiming and not current_target and crosshair_texture:
			crosshair_texture.modulate = crosshair_neutral_color
			_log("⚪ Crosshair set to neutral when enabling aiming mode")

func update_crosshair_colors(neutral: Color, enemy: Color):
	crosshair_neutral_color = neutral
	crosshair_enemy_color = enemy
	if crosshair_texture:
		crosshair_texture.modulate = crosshair_neutral_color if not current_target else crosshair_enemy_color
		_log("⚪/🔴 Crosshair colors updated")

func clear_all_highlights():
	for target in highlighted_meshes.keys().duplicate():
		_remove_highlight_effect(target)
	_log("🧹 All highlights removed")

func toggle_highlights(enabled: bool):
	highlight_enabled = enabled
	if not enabled:
		clear_all_highlights()
	_log("✨ Highlights " + ("enabled" if enabled else "disabled"))

func set_highlight_intensity(energy: float, multiplier: float):
	highlight_emission_energy = energy
	highlight_emission_multiplier = multiplier
	_log("🔆 Highlight intensity updated: Energy=" + str(energy) + ", Multiplier=" + str(multiplier))

func set_shader_parameters(color: Color, thickness: float, intensity: float, pulse: float = pulse_speed, dissolve: float = dissolve_amount):
	highlight_color = color
	outline_thickness = thickness
	highlight_intensity = intensity
	pulse_speed = pulse  # Update pulse_speed
	dissolve_amount = dissolve  # Update dissolve_amount
	for target in highlighted_meshes:
		for applied in highlighted_meshes[target]:
			var mat = applied["material"]
			if mat is ShaderMaterial:
				mat.set_shader_parameter("highlight_color", highlight_color)
				mat.set_shader_parameter("outline_thickness", outline_thickness)
				mat.set_shader_parameter("highlight_intensity", highlight_intensity)
				mat.set_shader_parameter("pulse_speed", pulse_speed)
				mat.set_shader_parameter("dissolve_amount", dissolve_amount)
	_log("🖌️ Shader parameters updated: Color=" + str(color) + ", Thickness=" + str(thickness) + ", Intensity=" + str(intensity) + ", PulseSpeed=" + str(pulse_speed) + ", DissolveAmount=" + str(dissolve_amount))

func set_pulse_speed(speed: float):
	pulse_speed = speed
	for target in highlighted_meshes:
		for applied in highlighted_meshes[target]:
			var mat = applied["material"]
			if mat is ShaderMaterial:
				mat.set_shader_parameter("pulse_speed", pulse_speed)
	_log("🔄 Pulse speed updated: " + str(pulse_speed))

func set_dissolve_amount(amount: float):
	dissolve_amount = clamp(amount, 0.0, 1.0) # Ensure dissolve_amount is between 0 and 1
	for target in highlighted_meshes:
		for applied in highlighted_meshes[target]:
			var mat = applied["material"]
			if mat is ShaderMaterial:
				mat.set_shader_parameter("dissolve_amount", dissolve_amount)
	_log("🧪 Dissolve amount updated: " + str(dissolve_amount))

func is_system_ready() -> bool:
	return _is_system_ready()

func get_enemy_groups() -> Array[String]:
	return enemy_groups.duplicate()

func add_enemy_group(group_name: String):
	if not enemy_groups.has(group_name):
		enemy_groups.append(group_name)
		_log("➕ Added enemy group: " + group_name)

func remove_enemy_group(group_name: String):
	if enemy_groups.has(group_name):
		enemy_groups.erase(group_name)
		_log("➖ Removed enemy group: " + group_name)

func set_enemy_groups(groups: Array[String]):
	enemy_groups = groups.duplicate()
	_log("🔄 Enemy groups updated: " + str(enemy_groups))

func toggle_distance_label(enabled: bool):
	enable_distance_label = enabled
	if distance_label:
		distance_label.visible = enabled
		if not enabled:
			distance_label.text = ""
		_log("📏 DistanceLabel " + ("enabled" if enabled else "disabled"))

func update_distance_label_style(font: Font, font_size: int, color: Color):
	distance_label_font = font
	distance_label_font_size = font_size
	distance_label_color = color
	if distance_label and is_instance_valid(distance_label):
		if distance_label_font:
			distance_label.add_theme_font_override("font", distance_label_font)
		distance_label.add_theme_font_size_override("font_size", distance_label_font_size)
		distance_label.add_theme_color_override("font_color", distance_label_color)
		_log("🖌️ DistanceLabel style updated: font_size=" + str(font_size) + ", color=" + str(color))

func _exit_tree():
	_clear_target()
	clear_all_highlights()
	if is_instance_valid(raycast):
		raycast.queue_free()
