class_name AimingSystemGroup
extends Node3D

# Region: Detection Settings
@export_category("Detection")
@export var camera: Camera3D  ## Reference to the Camera3D
@export var detection_range: float = 50.0  ## Maximum distance for detecting objects
@export var layers_to_check: int = 1  ## Collision layers for raycast detection

# Region: Group Settings
@export_category("Group Settings")
## Dictionary mapping group names to their settings (e.g., crosshair color)
@export var group_settings: Dictionary = {
	"enemy": {"crosshair_color": Color.RED, "highlight": true},
	"interactable": {"crosshair_color": Color.GREEN, "highlight": false}
}

# Region: Crosshair Settings
@export_category("Crosshair")
@export var crosshair: Control  ## Reference to the crosshair UI node
@export var distance_label: Label  ## Label to show distance to target
@export var enable_distance_label: bool = true  ## Enable/disable distance label
@export var distance_label_font: Font  ## Font for the distance label
@export var distance_label_font_size: int = 18  ## Font size for the distance label
@export var distance_label_color: Color = Color.YELLOW  ## Text color for the distance label
@export var crosshair_neutral_color: Color = Color.WHITE  ## Default crosshair color

# Region: Visual Effects Settings
@export_category("Visual Effects")
@export var enable_visual_effects: bool = true  ## Enable/disable visual effects
@export var highlight_emission_energy: float = 0.8  ## Intensity multiplier for outline
@export var highlight_emission_multiplier: float = 0.4  ## Multiplier for outline color
@export var outline_scale: float = 0.02  ## Base thickness of the outline effect
@export var outline_shader: Shader  ## Shader for the outline effect

# Region: Debug Settings
@export_category("Debug")
@export var debug_logging: bool = true  ## Enable/disable debug logging

# Region: Internal Variables
@onready var crosshair_texture: TextureRect = null  # TextureRect child of crosshair
var raycast: RayCast3D = null  # RayCast3D node for detecting objects
var current_target: Node3D = null  # Currently targeted node
var current_target_group: String = ""  # Current target's primary group
var highlighted_meshes: Dictionary = {}  # Cache of meshes with outline effects
var enemy_meshes: Dictionary = {}  # Cache of mesh instances for each target

# Region: Signals
signal target_detected(target: Node3D, group: String, distance: float)
signal target_lost()
signal highlight_applied(target: Node3D)
signal highlight_removed(target: Node3D)

# Region: Initialization
func _ready():
	_setup_camera()
	_setup_crosshair()
	_setup_distance_label()
	_setup_raycast()
	_setup_shader()
	_log("🎯 AimingSystem initialized - Range: " + str(detection_range) + " - Groups: " + str(group_settings.keys()))

func _setup_camera():
	if not camera or not is_instance_valid(camera):
		_log("❌ No valid Camera3D assigned")
		set_physics_process(false)
		return
	_log("✅ Camera3D assigned: " + camera.name)

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

func _setup_distance_label():
	if distance_label and is_instance_valid(distance_label):
		distance_label.text = ""
		distance_label.visible = enable_distance_label
		if distance_label_font:
			distance_label.add_theme_font_override("font", distance_label_font)
		distance_label.add_theme_font_size_override("font_size", distance_label_font_size)
		distance_label.add_theme_color_override("font_color", distance_label_color)
		distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_log("✅ DistanceLabel configured")
	else:
		_log("⚠️ DistanceLabel not assigned or invalid")

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

func _setup_shader():
	if not outline_shader or not is_instance_valid(outline_shader):
		_log("⚠️ No valid outline shader assigned")
	else:
		_log("✅ Outline shader assigned")

# Region: Main Processing
func _physics_process(_delta):
	if not _is_system_ready():
		return

	raycast.global_transform = camera.global_transform

	if current_target and not _is_valid_target(current_target):
		_log("⚠️ Current target is invalid")
		_clear_target()
		return

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		var detected_group = _get_target_group(collider)
		if detected_group and collider != current_target:
			_set_new_target(collider, detected_group)
		elif not detected_group and current_target:
			_clear_target()
		elif current_target and detected_group:
			var distance = camera.global_position.distance_to(raycast.get_collision_point())
			if distance_label and enable_distance_label:
				distance_label.text = "%.1f m" % distance
	elif current_target:
		_clear_target()

# Region: Target Management
func _set_new_target(target: Node3D, group: String):
	_clear_target()
	current_target = target
	current_target_group = group

	if not current_target.tree_exited.is_connected(_on_target_exited):
		current_target.tree_exited.connect(_on_target_exited, CONNECT_ONE_SHOT)

	_update_crosshair_color(group)
	var distance = camera.global_position.distance_to(raycast.get_collision_point())
	if distance_label and enable_distance_label:
		distance_label.text = "%.1f m" % distance

	target_detected.emit(target, group, distance)

	if enable_visual_effects and group_settings.get(group, {}).get("highlight", false) and outline_shader:
		_apply_highlight_effect(target)

	_log("🎯 Target detected: " + target.name + " (Group: " + group + ") at " + "%.1f" % distance + "m")

func _clear_target():
	if current_target:
		if enable_visual_effects and group_settings.get(current_target_group, {}).get("highlight", false):
			_remove_highlight_effect(current_target)
		current_target = null
		current_target_group = ""

	_update_crosshair_color("")
	if distance_label and enable_distance_label:
		distance_label.text = ""
	target_lost.emit()

func _on_target_exited():
	_log("⚠️ Target destroyed")
	_clear_target()

# Region: Highlight System
func _apply_highlight_effect(target: Node3D):
	if not _is_valid_target(target) or target in highlighted_meshes:
		return

	var mesh_instances = enemy_meshes.get(target, _find_mesh_instances(target))
	if not enemy_meshes.has(target):
		enemy_meshes[target] = mesh_instances

	var materials_applied = []
	for mesh in mesh_instances:
		if not is_instance_valid(mesh):
			continue

		var outline_mesh = MeshInstance3D.new()
		outline_mesh.mesh = mesh.mesh
		outline_mesh.transform = mesh.transform
		outline_mesh.name = mesh.name + "_Outline"

		var outline_material = ShaderMaterial.new()
		outline_material.shader = outline_shader
		var group_color = group_settings.get(current_target_group, {}).get("crosshair_color", Color.WHITE)
		outline_material.set_shader_parameter("outline_color", group_color * highlight_emission_multiplier)
		outline_material.set_shader_parameter("outline_scale", outline_scale * highlight_emission_energy)

		outline_mesh.material_override = outline_material
		mesh.get_parent().add_child(outline_mesh)
		materials_applied.append({"mesh": mesh, "outline_mesh": outline_mesh})

	if materials_applied:
		highlighted_meshes[target] = materials_applied
		highlight_applied.emit(target)
		_log("✨ Outline highlight applied to: " + target.name)

func _remove_highlight_effect(target: Node3D):
	if not target or not highlighted_meshes.has(target):
		return

	for applied in highlighted_meshes[target]:
		var outline_mesh = applied["outline_mesh"]
		if is_instance_valid(outline_mesh):
			outline_mesh.queue_free()

	highlighted_meshes.erase(target)
	enemy_meshes.erase(target)
	highlight_removed.emit(target)
	_log("🧹 Outline highlight removed from: " + (target.name if is_instance_valid(target) else "Unknown"))

# Region: Utilities
func _is_valid_target(node) -> bool:
	if not node or not is_instance_valid(node) or not node.is_inside_tree():
		return false
	return _get_target_group(node) != ""

func _get_target_group(node) -> String:
	if not node or not is_instance_valid(node):
		return ""
	for group in node.get_groups():
		if group_settings.has(group):
			return group
	return ""

func _is_system_ready() -> bool:
	return is_instance_valid(raycast) and is_instance_valid(camera) and is_instance_valid(crosshair)

func _update_crosshair_color(group: String):
	if crosshair_texture:
		var color = group_settings.get(group, {}).get("crosshair_color", crosshair_neutral_color)
		crosshair_texture.modulate = color
		_log("🔴 Crosshair set to group color: " + group if group else "⚪ Crosshair restored to neutral")

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

func get_current_target_group() -> String:
	return current_target_group

func is_aiming_at_target() -> bool:
	return current_target != null and _is_valid_target(current_target)

func set_aiming_mode(aiming: bool):
	if crosshair:
		crosshair.visible = aiming
		if aiming and not current_target and crosshair_texture:
			crosshair_texture.modulate = crosshair_neutral_color
			_log("⚪ Crosshair set to neutral when enabling aiming mode")

func clear_all_highlights():
	for target in highlighted_meshes.keys().duplicate():
		_remove_highlight_effect(target)
	_log("🧹 All highlights removed")

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
		_log("🖌️ DistanceLabel style updated")

func add_group_setting(group_name: String, crosshair_color: Color, highlight: bool):
	group_settings[group_name] = {"crosshair_color": crosshair_color, "highlight": highlight}
	_log("➕ Added group setting: " + group_name)

func remove_group_setting(group_name: String):
	if group_settings.erase(group_name):
		_log("➖ Removed group setting: " + group_name)
