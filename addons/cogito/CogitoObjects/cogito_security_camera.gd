@tool
@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoObject.svg")
extends Node3D
class_name CogitoSecurityCamera

signal started_detecting
signal object_detected
signal send_detected_object(object: Node3D)
signal object_no_longer_detected
signal turned_off

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var lightmeter: CogitoAttribute
@onready var detected_light_level: float

@export var detection_ray_cast_3d: RayCast3D
@export var indicator_light: OmniLight3D
@export var detection_area: Area3D 
@export var start_state: DetectorState

@export_category("Detection Settings")
@export var only_detect_player: bool = true
## Threshold at which Player is detected
@export var detection_threshold: float = 4.0

enum DetectionMethod {
	TIME, ## Uses Time directly until detection is triggered
	LIGHTMETER ## Uses Time * Lightmeter until detection is triggered. Scaled by light_level_detection_multipler.
}

## How should the player be detected?
@export var detection_method: DetectionMethod = DetectionMethod.TIME
## Determines impact player light level has on detection for Lightmeter method
@export var light_level_detection_multipler: float = 0.01
## Names of non-player objects that should trigger detection
@export var non_player_detection_list: Array[String] = []
## Sound played on detection triggered
@export var alarm_sound: AudioStream

@export_group("Detection indicator settings")
@export var indicator_mesh: MeshInstance3D
@export var color_offline: Color = Color.DARK_GRAY
@export var color_searching: Color = Color.GREEN
@export var color_detecting: Color = Color.YELLOW
@export var color_detected: Color = Color.RED
@export var use_shader: bool = true : set = _set_use_shader
@export var indicator_shader: Shader : set = _set_indicator_shader

enum DetectorState {
	SEARCHING,
	DETECTING,
	DETECTED,
	OFFLINE
}

var current_state: DetectorState
var objects_in_detection_area: Array[Node3D]
var detected_objects: Array[Node3D]
var detection_time: float = 0
var shader_material: ShaderMaterial
var default_material: Material  # Armazena o material padrão do indicator_mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	detection_area.body_entered.connect(on_body_entered_detection)
	detection_area.body_exited.connect(on_body_left_detection)
	
	audio_stream_player_3d.stream = alarm_sound
	
	current_state = start_state
	_setup_indicator_mesh()
	_setup_shader_material()
	update_indicator_mesh()

func _setup_indicator_mesh():
	if indicator_mesh and is_instance_valid(indicator_mesh):
		default_material = indicator_mesh.get_active_material(0)
		if not default_material or default_material is ShaderMaterial:
			default_material = StandardMaterial3D.new()  # Cria um material padrão se necessário
			indicator_mesh.set_surface_override_material(0, default_material)
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Indicator mesh configured with default material")
	else:
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Warning: No valid indicator mesh assigned")

func _setup_shader_material():
	if use_shader and indicator_shader and indicator_mesh:
		shader_material = ShaderMaterial.new()
		shader_material.shader = indicator_shader
		indicator_mesh.material_override = shader_material
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "ShaderMaterial configured")
	else:
		shader_material = null
		if indicator_mesh:
			indicator_mesh.material_override = null  # Restaura o material padrão
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Shader not configured (use_shader: " + str(use_shader) + ")")
	update_indicator_mesh()

func _set_use_shader(value: bool):
	use_shader = value
	if Engine.is_editor_hint():
		_setup_shader_material()
	notify_property_list_changed()

func _set_indicator_shader(value: Shader):
	indicator_shader = value
	if Engine.is_editor_hint():
		_setup_shader_material()
	notify_property_list_changed()

func _physics_process(delta: float) -> void:
	match current_state:
		DetectorState.OFFLINE:
			return
		DetectorState.SEARCHING:
			searching()
		DetectorState.DETECTING:
			detecting(delta)
		DetectorState.DETECTED:
			return

func searching():
	if objects_in_detection_area.size() > 0:
		if find_visible_targets_within_detection_area().size() > 0:
			start_detecting()

func start_detecting():
	current_state = DetectorState.DETECTING
	started_detecting.emit()
	update_indicator_mesh()

func detecting(delta: float):
	detected_objects = find_visible_targets_within_detection_area()
	if detected_objects.size() <= 0:
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "DETECTING: No visible targets in detection area. Stopping detection.")
		stop_detecting()
	
	if detection_method == DetectionMethod.LIGHTMETER and lightmeter != null: 
		detected_light_level = lightmeter.value_current
		detection_time += delta * (detected_light_level * light_level_detection_multipler)
	else:
		detection_time += delta
		
	if detection_time >= detection_threshold:
		# === THIS IS WHERE THE FULL DETECTION HAPPENS ===
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Detected!")
		current_state = DetectorState.DETECTED
		start_alarm_light()
		if !audio_stream_player_3d.playing:
			audio_stream_player_3d.play()
			
		send_detected_object.emit(detected_objects[0])
		object_detected.emit()
		update_indicator_mesh()

func stop_detecting():
	CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Stopping detection.")
	detection_time = 0
	current_state = DetectorState.SEARCHING
	object_no_longer_detected.emit()
	
	if self.get_parent() is CogitoNPC:
		self.get_parent().attention_target = null
	
	update_indicator_mesh()

func switch_to_searching():
	detection_time = 0
	current_state = DetectorState.SEARCHING
	if audio_stream_player_3d.playing:
		audio_stream_player_3d.stop()
	stop_alarm_light()
	update_indicator_mesh()

func turn_off():
	if audio_stream_player_3d.playing:
		audio_stream_player_3d.stop()
	current_state = DetectorState.OFFLINE
	turned_off.emit()
	update_indicator_mesh()
	indicator_light.light_energy = 0

func find_visible_targets_within_detection_area() -> Array[Node3D]:
	var visible_targets: Array[Node3D]
	visible_targets.clear()
	for target in objects_in_detection_area:
		if object_visible_for_detector(target):
			visible_targets.append(target)
	
	return visible_targets

func object_visible_for_detector(target: Node3D) -> bool:
	detection_ray_cast_3d.set_target_position(to_local(target.global_position))
	CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Checking if detector can see " + target.name + " at position " + str(target.global_position))
	var detected_object = detection_ray_cast_3d.get_collider()

	if detected_object == target:
		return true
	else:
		return false

func on_body_entered_detection(body: Node3D):
	if only_detect_player and body.is_in_group("Player"):
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Player entered detection area: " + body.name)
		objects_in_detection_area.append(body)
	# For non-player objects, check they are in the non_player_detection_list, and not a player
	elif !only_detect_player and !body.is_in_group("Player"):
		if is_relevant_non_player(body):
			CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Relevant object entered detection area: " + body.name)
			objects_in_detection_area.append(body)
	if detection_method == DetectionMethod.LIGHTMETER:
		find_lightmeter(body)  # Check for Lightmeter on any entered body, if using Lightmeter detection method

func find_lightmeter(body):
	var found_lightmeter: CogitoLightmeter = null
	for attribute in body.find_children("", "CogitoLightmeter", false):
		if attribute is CogitoLightmeter:
			found_lightmeter = attribute
			break

	if found_lightmeter:
		lightmeter = found_lightmeter
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Lightmeter found on entity: " + body.name)
	else:
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "No lightmeter found on entity: " + body.name)

func is_relevant_non_player(body: Node3D) -> bool:
	## TODO: Better way of defining this than names array
	if body.name in non_player_detection_list:
		return true
	else:
		return false

func on_body_left_detection(body: Node3D):
	if only_detect_player and body.is_in_group("Player"):
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Player left detection area: " + body.name)
		objects_in_detection_area.erase(body)
	elif is_relevant_non_player(body):
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", body.name + " left detection area: ")
		objects_in_detection_area.erase(body)

func start_alarm_light():
	var light_tween = get_tree().create_tween()
	light_tween.tween_property(indicator_light, "light_energy", 6, 1).set_trans(Tween.TRANS_CUBIC)
	light_tween.tween_property(indicator_light, "light_energy", 0.1, 1).set_trans(Tween.TRANS_CUBIC)
	if current_state == DetectorState.DETECTED:
		await get_tree().create_timer(2).timeout
		start_alarm_light()
	else:
		stop_alarm_light()

func stop_alarm_light():
	indicator_light.light_energy = 0.1

func update_indicator_mesh():
	if not indicator_mesh or not is_instance_valid(indicator_mesh):
		CogitoGlobals.debug_log(true, "cogito_security_camera.gd", "Warning: Invalid indicator mesh")
		return
	
	var indicator_material = shader_material if use_shader and shader_material else default_material
	if not indicator_material:
		indicator_material = StandardMaterial3D.new()
		default_material = indicator_material
		indicator_mesh.set_surface_override_material(0, default_material)
	
	match current_state:
		DetectorState.OFFLINE:
			if use_shader and indicator_material is ShaderMaterial:
				indicator_material.set_shader_parameter("emission_color", color_offline)
			elif indicator_material is StandardMaterial3D:
				indicator_material.albedo_color = color_offline
			indicator_light.light_color = color_offline
		DetectorState.SEARCHING:
			if use_shader and indicator_material is ShaderMaterial:
				indicator_material.set_shader_parameter("emission_color", color_searching)
			elif indicator_material is StandardMaterial3D:
				indicator_material.albedo_color = color_searching
			indicator_light.light_color = color_searching
		DetectorState.DETECTING:
			if use_shader and indicator_material is ShaderMaterial:
				indicator_material.set_shader_parameter("emission_color", color_detecting)
			elif indicator_material is StandardMaterial3D:
				indicator_material.albedo_color = color_detecting
			indicator_light.light_color = color_detecting
		DetectorState.DETECTED:
			if use_shader and indicator_material is ShaderMaterial:
				indicator_material.set_shader_parameter("emission_color", color_detected)
			elif indicator_material is StandardMaterial3D:
				indicator_material.albedo_color = color_detected
			indicator_light.light_color = color_detected

func _get_property_list() -> Array:
	var properties = []
	properties.append({
		"name": "Detection indicator settings/use_shader",
		"type": TYPE_BOOL,
		"usage": PROPERTY_USAGE_DEFAULT
	})
	properties.append({
		"name": "Detection indicator settings/indicator_shader",
		"type": TYPE_OBJECT,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Shader",
		"usage": PROPERTY_USAGE_DEFAULT
	})
	return properties
