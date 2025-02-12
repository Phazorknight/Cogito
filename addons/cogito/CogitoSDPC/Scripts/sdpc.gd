@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoPlayer.svg")
class_name CogitoSDPC
extends CharacterBody3D

## Emits when ESC/Menu input map action is pressed. Can be used to exit out other interfaces, etc.
signal menu_pressed(player_interaction_component: PlayerInteractionComponent)
signal toggle_inventory_interface()
signal player_state_loaded()
## Used to hide UI elements like the crosshair when another interface is active (like a container or readable)
signal toggled_interface(is_showing_ui:bool)
signal mouse_movement(relative_mouse_movement:Vector2)

@export_group("Cogito Components")
# Config file for saved options and controls
var config = ConfigFile.new()

### PLAYER ATTRIBUTES:
var player_attributes : Dictionary
var stamina_attribute : CogitoAttribute = null
var visibility_attribute : CogitoAttribute

### PLAYER CURRENCIES
var player_currencies: Dictionary


## Reference to Pause menu node
@export var pause_menu : NodePath
## Refereence to Player HUD node
@export var player_hud : NodePath
## PLAYER INVENTORY
@export var inventory_data: CogitoInventory

# Node caching
@onready var player_interaction_component: PlayerInteractionComponent = $PlayerInteractionComponent
@onready var body: Node3D = $Body
@onready var neck: Node3D = $Body/Neck
@onready var head: Node3D = $Body/Neck/Head
@onready var eyes: Node3D = $Body/Neck/Head/Eyes
@onready var camera: Camera3D = $Body/Neck/Head/Eyes/Camera
@onready var crouch_ray_cast: RayCast3D = $CrouchRayCast

# Climbing Raycasts
@onready var top_raycast: RayCast3D = $RaycastClimbDetector/TopRaycast
@onready var middle_raycast: RayCast3D = $RaycastClimbDetector/MiddleRaycast
@onready var bottom_raycast: RayCast3D = $RaycastClimbDetector/BottomRaycast
@onready var left_climbable_raycast: RayCast3D = $RaycastClimbDetector/ClimbableRaycasts/LeftClimbableRaycast
@onready var right_climbable_raycast: RayCast3D = $RaycastClimbDetector/ClimbableRaycasts/RightClimbableRaycast
@onready var projected_height_raycast: RayCast3D = $RaycastClimbDetector/SurfaceRaycasts/ProjectedHeightRaycast
@onready var surface_raycast: RayCast3D = $RaycastClimbDetector/SurfaceRaycasts/SurfaceRaycast


@export_group("Controls map names")
@export var MOVE_FORWARD: String = "forward"
@export var MOVE_BACK: String = "back"
@export var MOVE_LEFT: String = "left"
@export var MOVE_RIGHT: String = "right"
@export var JUMP: String = "jump"
@export var CROUCH: String = "crouch"
@export var SPRINT: String = "sprint"
@export var PAUSE: String = "menu"
@export var INVENTORY: String = "inventory"

@export_group("Customizable player stats")
@export var walk_back_speed: float = 1.5
@export var walk_speed: float = 2.5
@export var sprint_speed: float = 5.0
@export var crouch_speed: float = 1.5
@export var jump_height: float = 1.0
@export var acceleration: float = 10.0
@export var arm_length: float = 0.5
@export var regular_climb_speed: float = 6.0
@export var fast_climb_speed: float = 8.0
@export_range(0.0, 1.0) var view_bobbing_amount: float = 1.0
@export_range(1.0, 10.0) var camera_sensitivity: float = 2.0
@export_range(0.0, 0.5) var camera_start_deadzone: float = .2
@export_range(0.0, 0.5) var camera_end_deadzone: float = .1
@export var INVERT_Y_AXIS: bool

@export_group("Feature toggles")
@export var allow_jump: bool = true : set = set_jump_allowance
@export var allow_crouch: bool = true : set = set_crouch_allowance
@export var allow_sprint: bool = true : set = set_sprint_allowance
@export var allow_climb: bool = true : set = set_climb_allowance
@export var allow_slide: bool = true : set = set_slide_allowance

# Dynamic values used for calculation
var input_direction: Vector2
var ledge_position: Vector3 = Vector3.ZERO
var mouse_motion: Vector2
var default_view_bobbing_amount: float
var movement_strength: float

# Values that are set 'false' if corresponding controls aren't mapped
var can_move: bool = true
var can_jump: bool = true
var can_crouch: bool = true
var can_sprint: bool = true
var can_pause: bool = true
var can_open_inventory: bool = true

#region Player States (Values that are set by applying state)
# Climbing
var can_climb: bool
var can_climb_timer: Timer
var climb_speed: float = fast_climb_speed

var is_grabbing: bool = false
# Horizontal Movement
var is_moving: bool = false
var is_sprinting: bool = false
var is_crouched: bool = false
# Vertical Movement
var is_sliding : bool = false
var is_affected_by_gravity: bool = true
var is_jumping: bool = false
var is_falling: bool = false
# Pausing
var is_showing_ui : bool
var is_paused : bool

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var state_machine : SDPCStateMachine = $SDPCStateMachine
#endregion


func _ready() -> void:
	#Some Setup steps
	CogitoSceneManager._current_player_node = self
	player_interaction_component.interaction_raycast = $Body/Neck/Head/Eyes/Camera/InteractionRaycast
	player_interaction_component.exclude_player(get_rid())

	randomize()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	### NEW PLAYER ATTRIBUTE SETUP:
	# Grabs all attached player attributes
	for attribute in find_children("","CogitoAttribute",false):
		player_attributes[attribute.attribute_name] = attribute
		CogitoGlobals.debug_log(true, "cogito_player.gd", "Cogito Attribute found: " + attribute.attribute_name)

	# If found, hookup health attribute signal to detect player death
	var health_attribute = player_attributes.get("health")
	# Save reference to stamina attribute for movements that require stamina checks (null if not found)
	stamina_attribute = player_attributes.get("stamina")
	# Save reference to visibilty attribute for that require visibility checks (null if not found)
	visibility_attribute = player_attributes.get("visibility")
	# Hookup sanity attribute to visibility attribute
	var sanity_attribute = player_attributes.get("sanity")
	if sanity_attribute and visibility_attribute:
		visibility_attribute.attribute_changed.connect(sanity_attribute.on_visibility_changed)
		visibility_attribute.check_current_visibility()


	### CURRENCY SETUP
	for currency in find_children("", "CogitoCurrency", false):
		player_currencies[currency.currency_name] = currency
		CogitoGlobals.debug_log(true, "cogito_player.gd", "Cogito Currency found: " + currency.currency_name)


	# Pause Menu setup
	if pause_menu:
		var pause_menu_node = get_node(pause_menu)
		pause_menu_node.resume.connect(_on_pause_menu_resume) # Hookup resume signal from Pause Menu
		pause_menu_node.close_pause_menu() # Making sure pause menu is closed on player scene load
	else:
		printerr("Player has no reference to pause menu.")

	#Sittable Signals setup
	CogitoSceneManager.connect("sit_requested", Callable(self, "_on_sit_requested"))
	CogitoSceneManager.connect("stand_requested", Callable(self, "_on_stand_requested"))
	CogitoSceneManager.connect("seat_move_requested", Callable(self, "_on_seat_move_requested"))

	# Initialize the state machine, passing a reference of the player to the states, that way they can move and react accordingly
	state_machine.init(self)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_motion = -event.relative * 0.001

	if can_pause and event.is_action_pressed(PAUSE):
		# Exit UI
		if is_showing_ui: #Behaviour when pressing ESC/menu while external UI is open (Readables, Keypad, etc)
			menu_pressed.emit(player_interaction_component)
			if get_node(player_hud).inventory_interface.is_inventory_open: #Behaviour when pressing ESC/menu while Inventory is open
				toggle_inventory_interface.emit()
		# If no UI, we want to pause instead
		else:
			_on_pause_movement()
			get_node(pause_menu).open_pause_menu()

	# Open/closes Inventory if Inventory button is pressed
	if can_open_inventory and event.is_action_pressed(INVENTORY):
		if !is_showing_ui: #Making sure now external UI is open.
			toggle_inventory_interface.emit()
		elif is_showing_ui and get_node(player_hud).inventory_interface.is_inventory_open: #Making sure Inventory is open, and if yes, close it.
			toggle_inventory_interface.emit()

	# If we are showing the UI, we don't want the SDPCStateMachine to process inputs
	if !is_showing_ui:
		state_machine.process_input(event)


func _physics_process(delta: float) -> void:
	if can_move:
		# This portion gives values to [input_direction] and [movement_strength]
		if Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK):
			input_direction = Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_FORWARD, MOVE_BACK)
		elif Input.get_connected_joypads().size() != 0:
			input_direction = Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
			var x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
			var y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
			movement_strength = Vector2(x, y).length()
		else:
			input_direction = Vector2.ZERO

	# Add the gravity.
	if not is_on_floor() and is_affected_by_gravity:
		velocity.y -= gravity * delta

	# Resetting climb ability when on ground
	#NOTE: Currently can_climb_timer is not being utilized within the codebase -V
	if is_on_floor() and !can_climb:
		if can_climb_timer != null:
			can_climb_timer.queue_free()
		can_climb = true

	state_machine.process_physics(delta)
	move_and_slide()


func _process(delta: float) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and !is_paused:
		# Handling camera in '_process' so that camera movement is framerate independent
		_handle_camera_motion()

	if Input.get_connected_joypads().size() != 0 and !is_paused:
		_handle_joy_camera_motion()

	state_machine.process_frame(delta)


func check_climbable() -> bool:
	# Crouch? No Climb
	if crouch_ray_cast.is_colliding() or is_crouched:
		return false

	# No Wall? No Climb
	if not bottom_raycast.is_colliding() && not middle_raycast.is_colliding() && not top_raycast.is_colliding():
		return false

	var climb_point = surface_raycast.get_collision_point()
	var climb_height = climb_point.y - global_position.y

	# If either 'arm' is too short, No Climb
	left_climbable_raycast.global_position.y = climb_point.y + 0.1
	right_climbable_raycast.global_position.y = climb_point.y + 0.1
	if left_climbable_raycast.is_colliding() or right_climbable_raycast.is_colliding():
		return false

	# If Wall Too Tall
	projected_height_raycast.target_position = Vector3(0, climb_height - 0.1, 0)
	if projected_height_raycast.is_colliding():
		return false

	# Otherwise, the Edge is Climbable
	ledge_position = climb_point
	return true



func _handle_camera_motion() -> void:
	rotate_y(mouse_motion.x * camera_sensitivity)
	if INVERT_Y_AXIS:
		head.rotate_x(mouse_motion.y  * camera_sensitivity * -1)
	else:
		head.rotate_x(mouse_motion.y  * camera_sensitivity)

	head.rotation_degrees.x = clampf(head.rotation_degrees.x , -89.0, 89.0)
	mouse_motion = Vector2.ZERO


func _handle_joy_camera_motion() -> void:
	var x_axis = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)

	if abs(x_axis) < camera_start_deadzone:
		x_axis = 0
	if abs(x_axis) > 1 - camera_end_deadzone:
		if x_axis < 0:
			x_axis = camera_end_deadzone - 1
		else:
			x_axis = 1 - camera_end_deadzone

	var y_axis = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)

	if abs(y_axis) < camera_start_deadzone:
		y_axis = 0
	if abs(y_axis) > 1 - camera_end_deadzone:
		if y_axis < 0:
			y_axis = camera_end_deadzone - 1
		else:
			y_axis = 1 - camera_end_deadzone

	var resulting_vector = Vector2(x_axis, y_axis)
	var normalized_resulting_vector = resulting_vector.normalized()
	var action_strength = resulting_vector.length()
	print(camera_sensitivity)
	rotate_y(-deg_to_rad(camera_sensitivity * normalized_resulting_vector.x * action_strength))
	head.rotate_x(-deg_to_rad(camera_sensitivity * normalized_resulting_vector.y * action_strength))

	head.rotation_degrees.x = clampf(
		head.rotation_degrees.x , -89.0, 89.0
	)


# Methods to pause input (for Menu or Dialogues etc)
func _on_pause_movement():
	if is_paused: return
	state_machine.change_state(state_machine.pause_movement_state)

func _on_resume_movement():
	if !is_paused: return
	state_machine.revert_state()


func _on_pause_menu_resume(): # Signal from Pause Menu
	_reload_options()
	_on_resume_movement()


# reload options user may have changed while paused.
func _reload_options():
	var err = config.load(OptionsConstants.config_file_name)
	if err == 0:
		CogitoGlobals.debug_log(true, "sdpc.gd", "Options reloaded.")

		view_bobbing_amount = config.get_value(OptionsConstants.section_name, OptionsConstants.head_bobble_key, 1)
		camera_sensitivity = config.get_value(OptionsConstants.section_name, OptionsConstants.mouse_sens_key, 0.25)
		INVERT_Y_AXIS = config.get_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, true)
		#TOGGLE_CROUCH = config.get_value(OptionsConstants.section_name, OptionsConstants.toggle_crouching_key, true)
		#JOY_H_SENS = config.get_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, 2)
		#JOY_V_SENS = config.get_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, 2)


#region Setters
func set_flags(to_value: bool, flags: Array[bool]):
	for flag in flags:
		flag = to_value

func set_jump_allowance(value: bool):
	allow_jump = value
func set_crouch_allowance(value: bool):
	allow_crouch = value
func set_sprint_allowance(value: bool):
	allow_sprint = value
func set_climb_allowance(value: bool):
	allow_climb = value
func set_slide_allowance(value: bool):
	allow_slide = value
#endregion
