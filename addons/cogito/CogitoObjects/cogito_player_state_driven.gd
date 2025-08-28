@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoPlayer.svg")
## The player class controls movement from input from the mouse, keyboard, and gamepad, as well as behavior parameters like stair and ladder handling.
class_name CogitoPlayerStateDriven
extends CogitoPlayer

## Emits when ESC/Menu input map action is pressed. Can be used to exit out other interfaces, etc.
signal menu_pressed(player_interaction_component: PlayerInteractionComponent)
signal toggle_inventory_interface()
signal player_state_loaded()
## Used to hide UI elements like the crosshair when another interface is active (like a container or readable)
signal toggled_interface(is_showing_ui:bool) 

signal mouse_movement(relative_mouse_movement:Vector2)


#region Variables
## Reference to Pause menu node
@export var pause_menu : NodePath
## Refereence to Player HUD node
@export var player_hud : NodePath
# Used for handling input when UI is open/displayed
var is_showing_ui : bool
## Toggle printing debug messages or not. Works with the CogitoSceneManager
@export var is_logging : bool

## Item Drop Shapecast
@export var item_drop_shapecast : ShapeCast3D

## Ledge Climbing Shapecast
@export var ledge_climbing_shapecast : ShapeCast3D

## Damage the player takes if falling from great height. Leave at 0 if you don't want to use this.
@export var fall_damage : int
## Fall velocity at which fall damage is triggered. This is negative y-Axis. -5 is a good starting point but might be a bit too sensitive.
@export var fall_damage_threshold : float = -6

## Inventory resource that stores the player inventory.
@export var inventory_data : CogitoInventory

## Player can't open the pause menu in these states.
@export_node_path("StateChartState") var no_pause_menu_states: Array[NodePath]
## Player can't interact in these states.
@export_node_path("StateChartState") var no_interaction_states: Array[NodePath]

@export_group("Audio")
## AudioStream that gets played when the player jumps.
@export var jump_sound : AudioStream
## AudioStream that gets played when the player slides (sprint + crouch).
@export var slide_sound : AudioStream
@export var swim_movement_sound : AudioStream
@export var swim_under_water_sound : AudioStream
@export_subgroup ("Footstep Audio")
@export var walk_volume_db : float = -38.0
@export var sprint_volume_db : float = -30.0
@export var crouch_volume_db : float = -60.0
## the time between footstep sounds when walking
@export var walk_footstep_interval : float = 0.6
## the time between footstep sounds when sprinting
@export var sprint_footstep_interval : float = 0.3
## the speed at which the player must be moving before the footsteps change from walk to sprint.
@export var footstep_interval_change_velocity : float = 5.2

@export_subgroup ("Landing Audio")
## Threshold for triggering landing sound
@export var landing_threshold = -2.0  
## Defines Maximum velocity (in negative) for the hardest landing sound
@export var max_landing_velocity = -8
## Defines Minimum velocity (in negative) for the softest landing sound
@export var min_landing_velocity = -2
## Max volume in dB for the landing sound
@export var max_volume_db = 0
## Min volume in dB for the landing sound
@export var min_volume_db = -40
## Highest pitch for lightest landing sound
@export var max_pitch = 0.8
## Lowest pitch for hardest landing sound
@export var min_pitch = 0.7
#Setup Dynamic Pitch & Volume for Landing Audio, used to store velocity based results
var LandingPitch: float = 1.0
var LandingVolume: float = 0.8

@export_group("Movement Properties")
@export var MIN_SPEED : float= 0.5
@export var MAX_SPEED : float= 12.0
@export var JUMP_VELOCITY : float= 4.5
@export var CROUCH_JUMP_VELOCITY : float = 3.0
@export var WALKING_SPEED : float = 5.0
@export var SPRINTING_SPEED : float = 8.0
@export var CROUCHING_SPEED : float = 3.0
@export var CROUCHING_DEPTH : float = -0.9
@export var CAN_CROUCH_JUMP = true
@export var MOUSE_SENS : float = 0.25
@export var LERP_SPEED : float = 10.0
@export var AIR_LERP_SPEED : float = 6.0
@export var FREE_LOOK_TILT_AMOUNT : float = 5.0
@export var SLIDING_SPEED : float = 5.0
@export var SLIDE_JUMP_MOD : float = 1.5
@export var disable_roll_anim : bool = false
@export var CAN_BUNNYHOP : bool = true
@export var BUNNY_HOP_ACCELERATION : float = 0.1
@export var BUNNY_HOP_WALL_SLIDE_ANGLE : int = 120
@export var INVERT_Y_AXIS : bool = true
## Controled by the game config. If false, player has to hold the crouch key to stay crouched.
@export var TOGGLE_CROUCH : bool = false
## How much strength the player has to push RigidBody3D objects.
@export var PLAYER_PUSH_FORCE : float = 1.3
@export var LANDING_MIN_VELOCITY : float = -6.0
@export var LANDING_MIN_ROLL_VELOCITY : float = -8.5
@export var FREE_FALL_MIN_VELOCITY : float = -15
@export var FREE_FALL_MIN_DIE_VELOCITY : float = -40

@export_group("Headbob Properties")
## Head bob strength. Currently controlled/overridden by the in-game options.
@export_enum("Minimal:0.1", "Average:0.7", "Full:1") var HEADBOBBLE : int
@export var WIGGLE_ON_WALKING_INTENSITY : float = 0.03
@export var WIGGLE_ON_WALKING_SPEED : float = 12.0
@export var WIGGLE_ON_SPRINTING_INTENSITY : float = 0.05
@export var WIGGLE_ON_SPRINTING_SPEED : float = 16.0
@export var WIGGLE_ON_CROUCHING_INTENSITY : float = 0.08
@export var WIGGLE_ON_CROUCHING_SPEED : float = 8.0
@export var WIGGLE_ON_SWIMMING_INTENSITY : float = 0.08
@export var WIGGLE_ON_SWIMMING_SPEED : float = 6.0

@export_group("Stair Handling")
## This sets the camera smoothing when going up/down stairs as the player snaps to each stair step.
@export var step_height_camera_lerp : float = 2.5
## This sets the height of what is still considered a step (instead of a wall/edge)
@export var STEP_HEIGHT_DEFAULT : Vector3 = Vector3(0, 0.5, 0)
## This sets the step slope degree check. When set to 0, tiny edges etc might stop the player in it's tracks. 1 seems to work fine.
@export var STEP_MAX_SLOPE_DEGREE : float = 0.0

@export_group("Ladder Handling")
var on_ladder : bool = false
@export var CAN_SPRINT_ON_LADDER : bool = false
@export var LADDER_SPEED : float = 2.0
@export var LADDER_SPRINT_SPEED : float = 3.3
@export var LADDER_COOLDOWN : float = 0.5
const LADDER_JUMP_SCALE : float = 0.5
var ladder_on_cooldown : bool = false

@export_group("Ledge Handling")
@export var CAN_CLIMB_LEDGE : bool = true
@export var AUTO_STAND_AFTER_CLIMB : bool = false
@export var CLIMBING_SPEED : float = 2.5
@export var ARM_LENGTH : float = 0.7
@export var MIN_FREE_SPACE_ABOVE_HEAD : float = 0.1
@export var MIN_CLIMB_HEIGHT : float = 1.3

@export_group("Swim Handling")
@export var SWIMMING_SPEED : float = 3.0
@export var WATER_GRAVITY_COEFFICIENT = 0.25

@export_group("Gamepad Properties")
@export var JOY_DEADZONE : float = 0.25
@export var JOY_V_SENS : float = 2
@export var JOY_H_SENS : float = 2

### WIGGLE MODIFIERS
var WIGGLE_INTENSITY_MODIFIER = 1

### NEW PLAYER ATTRIBUTE SYSTEM:
var player_attributes : Dictionary
var stamina_attribute : CogitoAttribute = null
var visibility_attribute : CogitoAttribute

### CURRENCIES
var player_currencies: Dictionary

## STAIR HANDLING STUFF
const WALL_MARGIN : float = 0.001
const STEP_DOWN_MARGIN : float = 0.01
const STEP_CHECK_COUNT : int = 2
const SPEED_CLAMP_AFTER_JUMP_COEFFICIENT : float = 0.3
var STEP_HEIGHT_IN_AIR_DEFAULT : Vector3 = STEP_HEIGHT_DEFAULT
var is_enabled_stair_stepping_in_air : bool = true
var step_check_height : Vector3 = STEP_HEIGHT_DEFAULT / STEP_CHECK_COUNT
var gravity_vec : Vector3 = Vector3.ZERO
var head_offset : Vector3 = Vector3.ZERO
var is_jumping_started : bool = false
var is_in_air : bool = false

var input_direction : Vector2 = Vector2.ZERO
var joystick_h_event
var joystick_v_event
 
var initial_carryable_height #DEPRECATED Used to change carryable position based if player is standing or crouching

var config = ConfigFile.new()

var current_speed : float = 5.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var main_velocity : Vector3 = Vector3.ZERO
var last_velocity : Vector3= Vector3.ZERO
var direction : Vector3 = Vector3.ZERO
var is_free_looking : bool  = false
var is_roll_animation_finished : bool = false
var is_movement_paused : bool = false
var is_in_unpausable_state : bool = false
var is_in_interaction_state : bool = true
var is_dead : bool = false
var slide_audio_player : AudioStreamPlayer3D
var swim_under_water_audio_player : AudioStreamPlayer3D
var radius : float
var standing_height : float
var crouching_height : float
var ledge_climbing_shapecast_height : float

# Node caching
@onready var player_interaction_component: PlayerInteractionComponent = $PlayerInteractionComponent
@onready var body: Node3D = $Body
@onready var neck: Node3D = $Body/Neck
@onready var head: Node3D = $Body/Neck/Head
@onready var eyes: Node3D = $Body/Neck/Head/Eyes
@onready var camera: Camera3D = $Body/Neck/Head/Eyes/Camera
@onready var animationPlayer: AnimationPlayer = $Body/Neck/Head/Eyes/AnimationPlayer
@onready var swimming_head_shapecast: ShapeCast3D = $Body/Neck/Head/Eyes/Camera/SwimmingHeadShapeCast
@onready var under_water_effect: ColorRect = $GUI/Panel/AspectRatioContainer/UnderWaterEffect
@onready var crouch_shapecast: ShapeCast3D = $CrouchShapeCast

@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var crouching_collision_shape: CollisionShape3D = $CrouchingCollisionShape

@onready var sliding_timer: Timer = $SlidingTimer
@onready var jump_timer: Timer = $JumpCooldownTimer

# Adding carryable position for item control.
@onready var footstep_player = $FootstepPlayer
@onready var footstep_surface_detector : FootstepSurfaceDetector = $FootstepPlayer

#Navigation agent for Player auto seat exit handling
@onready var navigation_agent = $NavigationAgent3D

## performance saving variable
@onready var footstep_interval_change_velocity_square : float = footstep_interval_change_velocity * footstep_interval_change_velocity

# Cache allocation of test motion parameters.
@onready var _params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()

@onready var self_rid: RID = self.get_rid()
@onready var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()

@onready var wieldables = %Wieldables

@onready var state_chart: StateChart = $StateChart
#endregion


func _ready():
	#Some Setup steps
	CogitoSceneManager._current_player_node = self
	player_interaction_component.interaction_raycast = $Body/Neck/Head/Eyes/Camera/InteractionRaycast
	player_interaction_component.exclude_player(get_rid())
	
	$GUI/Panel/AspectRatioContainer/StateChartDebugger.enabled = CogitoGlobals.cogito_settings.is_state_chart_debugger_enabled
	
	randomize() 
	
	radius = _calculate_player_radius()
	
	if standing_collision_shape.shape is BoxShape3D:
		standing_height = standing_collision_shape.shape.size.y
	elif standing_collision_shape.shape is CylinderShape3D or standing_collision_shape.shape is CapsuleShape3D:
		standing_height = standing_collision_shape.shape.height
		
	if crouching_collision_shape.shape is BoxShape3D:
		crouching_height = crouching_collision_shape.shape.size.y
	elif crouching_collision_shape.shape is CylinderShape3D or crouching_collision_shape.shape is CapsuleShape3D:
		crouching_height = crouching_collision_shape.shape.height
	
	ledge_climbing_shapecast.add_exception(self)
	
	if ledge_climbing_shapecast.shape is BoxShape3D:
		ledge_climbing_shapecast_height = ledge_climbing_shapecast.shape.size.y
	elif ledge_climbing_shapecast.shape is CylinderShape3D or ledge_climbing_shapecast.shape is CapsuleShape3D:
		ledge_climbing_shapecast_height = ledge_climbing_shapecast.shape.height
	
	crouch_shapecast.add_exception(self)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	### NEW PLAYER ATTRIBUTE SETUP:
	# Grabs all attached player attributes
	for attribute in find_children("","CogitoAttribute",false):
		player_attributes[attribute.attribute_name] = attribute
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Cogito Attribute found: " + attribute.attribute_name)

	# If found, hookup health attribute signal to detect player death
	var health_attribute = player_attributes.get("health")
	if health_attribute:
		health_attribute.death.connect(_on_death)
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
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Cogito Currency found: " + currency.currency_name)


	# Pause Menu setup
	if pause_menu:
		var pause_menu_node = get_node(pause_menu)
		pause_menu_node.resume.connect(_on_pause_menu_resume) # Hookup resume signal from Pause Menu
		pause_menu_node.close_pause_menu() # Making sure pause menu is closed on player scene load
	else:
		printerr("Player has no reference to pause menu.")
	
	_initialize_state_chart()
	
	#Sittable Signals setup
	CogitoSceneManager.connect("sit_requested", Callable(self, "_on_sit_requested"))
	CogitoSceneManager.connect("stand_requested", Callable(self, "_on_stand_requested"))
	CogitoSceneManager.connect("seat_move_requested", Callable(self, "_on_seat_move_requested"))
	
	CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Player has no reference to pause menu.")

	call_deferred("slide_audio_init")
	call_deferred("swim_audio_init")


func slide_audio_init():
	#setup sound effect for sliding
	slide_audio_player = Audio.play_sound_3d(slide_sound, false)
	slide_audio_player.reparent(self, false)


func swim_audio_init():
	#setup sound effect for swimming
	swim_under_water_audio_player = Audio.play_sound_3d(swim_under_water_sound, false)
	swim_under_water_audio_player.reparent(self, false)


# Use these functions to manipulate player attributes.
func increase_attribute(attribute_name: String, value: float, value_type: ConsumableItemPD.ValueType) -> bool:
	var attribute = player_attributes.get(attribute_name)
	if not attribute:
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Increase attribute: Attribute not found")
		return false
	if value_type == ConsumableItemPD.ValueType.CURRENT:
		if attribute.value_current == attribute.value_max:
			return false
		attribute.add(value)
		return true
	elif value_type == ConsumableItemPD.ValueType.MAX:
		attribute.value_max += value
		attribute.add(value)
		return true
	return false


func decrease_attribute(attribute_name: String, value: float):
	var attribute = player_attributes.get(attribute_name)
	if not attribute:
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Decrease attribute: " + attribute_name + " - Attribute not found")
		return
	attribute.subtract(value)


# Use these functions to manipulate player currencies.
func increase_currency(currency_name: String, value: float) -> bool:
	var currency = player_currencies.get(currency_name)
	if not currency:
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Increase currency: Currency not found")
		return false
	else:
		currency.add(value)
		return true


func decrease_currency(currency_name: String, value: float):
	var currency = player_currencies.get(currency_name)
	if not currency:
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Decrease currency: " + currency_name + " - Currency not found")
		return
	currency.subtract(value)



func _on_death():
	player_interaction_component.on_death()
	is_dead = true


# Methods to pause input (for Menu or Dialogues etc)
func _on_pause_movement():
	if !is_movement_paused:
		is_movement_paused = true
		state_chart.send_event("pause")
		# Only show mouse cursor if input device is KBM
		if InputHelper.device_index == -1:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_resume_movement():
	if is_movement_paused:
		is_movement_paused = false
		state_chart.send_event("resume")
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func pause_before_interaction():
	is_movement_paused = true
	state_chart.send_event("pause")


func resume_after_interaction():
	is_movement_paused = false
	state_chart.send_event("resume")


# reload options user may have changed while paused.
func _reload_options():
	var err = config.load(OptionsConstants.config_file_name)
	if err == 0:
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Options reloaded.")
		
		HEADBOBBLE = config.get_value(OptionsConstants.section_name, OptionsConstants.head_bobble_key, 1)
		MOUSE_SENS = config.get_value(OptionsConstants.section_name, OptionsConstants.mouse_sens_key, 0.25)
		INVERT_Y_AXIS = config.get_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, true)
		TOGGLE_CROUCH = config.get_value(OptionsConstants.section_name, OptionsConstants.toggle_crouching_key, true)
		JOY_H_SENS = config.get_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, 2)
		JOY_V_SENS = config.get_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, 2)


# Signal from Pause Menu
func _on_pause_menu_resume():
	_reload_options()
	_on_resume_movement()


func _input(event):
	if event is InputEventMouseMotion and !is_movement_paused:
		var look_movement: Vector2 = Vector2(0.0,0.0)
		
		#If players sitting & look marker is present, use sittable look handling
		if is_sitting and CogitoSceneManager._current_sittable_node.look_marker_node:
			handle_sitting_look(event)
		else:
			if is_free_looking:
				neck.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
				neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
			else:
				body.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
				look_movement.x = -event.relative.x
			
			if INVERT_Y_AXIS:
				head.rotate_x(-deg_to_rad(-event.relative.y * MOUSE_SENS))
				look_movement.y = -event.relative.y
			else:
				head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
				look_movement.y = event.relative.y
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			
		mouse_movement.emit(look_movement)

		
	# Checking Analog stick input for mouse look
	if event is InputEventJoypadMotion and !is_movement_paused:
		if event.get_axis() == 2:
			joystick_v_event = event
		if event.get_axis() == 3:
			joystick_h_event = event
	
	
	# Opens Pause Menu if Menu button is proessed.
	if event.is_action_pressed("menu"):
		if is_showing_ui: #Behaviour when pressing ESC/menu while external UI is open (Readables, Keypad, etc)
			menu_pressed.emit(player_interaction_component)
			if get_node(player_hud).inventory_interface.is_inventory_open: #Behaviour when pressing ESC/menu while Inventory is open
				toggle_inventory_interface.emit()
		elif !is_in_unpausable_state and !is_movement_paused and !is_dead:
			if !currently_tweening:
				_on_pause_movement()
				get_node(pause_menu).open_pause_menu()
			else:
				player_interaction_component.send_hint(null, "Wait until I’m seated or standing")

	# Open/closes Inventory if Inventory button is pressed
	if event.is_action_pressed("inventory") and !is_dead:
		if !is_showing_ui: #Making sure now external UI is open.
			toggle_inventory_interface.emit()
		elif is_showing_ui and get_node(player_hud).inventory_interface.is_inventory_open: #Making sure Inventory is open, and if yes, close it.
			toggle_inventory_interface.emit()


func get_params(transform3d, motion):
	var params : PhysicsTestMotionParameters3D = _params
	params.from = transform3d
	params.motion = motion
	params.recovery_as_collision = true
	return params


func test_motion(transform3d: Transform3D, motion: Vector3) -> bool:
	return PhysicsServer3D.body_test_motion(self_rid, get_params(transform3d, motion), test_motion_result)	


func _process_analog_stick_mouselook():
	if joystick_h_event:
			if abs(joystick_h_event.get_axis_value()) > JOY_DEADZONE:
				if INVERT_Y_AXIS:
					head.rotate_x(deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				else:
					head.rotate_x(-deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
				
	if joystick_v_event:
		if abs(joystick_v_event.get_axis_value()) > JOY_DEADZONE:
			neck.rotate_y(deg_to_rad(-joystick_v_event.get_axis_value() * JOY_V_SENS))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))	


func _free_look(delta):
	if Input.is_action_pressed("free_look") or !sliding_timer.is_stopped() or current_moving_state == MovingState.Rolling:
		is_free_looking = true
		if sliding_timer.is_stopped():
			eyes.rotation.z = -deg_to_rad(
				neck.rotation.y * FREE_LOOK_TILT_AMOUNT
			)
		else:
			eyes.rotation.z = lerp(
				eyes.rotation.z,
				deg_to_rad(4.0), 
				delta * LERP_SPEED
			)
	else:
		is_free_looking = false
		body.rotation.y += neck.rotation.y
		neck.rotation.y = 0
		eyes.rotation.z = lerp(
			eyes.rotation.z,
			0.0,
			delta*LERP_SPEED
		)


func _stair_handling(delta):
	if not is_jumping_started and is_on_floor():
		is_jumping_started = false
		is_in_air = false
	else:
		is_in_air = true
		
	var step_result : StepResult = StepResult.new()
	
	var is_step : bool = step_check(delta, is_jumping_started, step_result)
	
	if is_step:
		var is_enabled_stair_stepping: bool = true
		if step_result.is_step_up and is_in_air and not is_enabled_stair_stepping_in_air:
			is_enabled_stair_stepping = false

		if is_enabled_stair_stepping:
			global_transform.origin += step_result.diff_position
			head_offset = step_result.diff_position
			head.position -= head_offset
			head.position.y = lerp(head.position.y, 0.0, delta * step_height_camera_lerp)#TODO * 10
	else:
		head_offset = head_offset.lerp(Vector3.ZERO, delta * LERP_SPEED)
		#head.position.y = lerp(head.position.y, 0.0, delta * step_height_camera_lerp)
	
	if is_step and step_result.is_step_up and is_enabled_stair_stepping_in_air:
		if is_in_air or direction.dot(step_result.normal) > 0:
			main_velocity *= SPEED_CLAMP_AFTER_JUMP_COEFFICIENT
			gravity_vec *= SPEED_CLAMP_AFTER_JUMP_COEFFICIENT

	if is_jumping_started:
		is_jumping_started = false
		is_in_air = true


func step_check(delta: float, is_jumping_started_: bool, step_result: StepResult):
	var is_step: bool = false
	
	var step_height_main: Vector3 = STEP_HEIGHT_DEFAULT
	var step_incremental_check_height: Vector3 = STEP_HEIGHT_DEFAULT / STEP_CHECK_COUNT
	
	if is_in_air and is_enabled_stair_stepping_in_air:
		step_height_main = STEP_HEIGHT_IN_AIR_DEFAULT
		step_incremental_check_height = STEP_HEIGHT_IN_AIR_DEFAULT / STEP_CHECK_COUNT
		
	if main_velocity.y >= 0:
		for i in range(STEP_CHECK_COUNT):
			var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
			
			var step_height: Vector3 = step_height_main - i * step_incremental_check_height
			var transform3d: Transform3D = global_transform
			var motion: Vector3 = step_height
			var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)

			if is_player_collided and test_motion_result.get_collision_normal().y < 0:
				continue

			transform3d.origin += step_height
			motion = main_velocity * delta
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -step_height
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided:
					if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
						is_step = true
						step_result.is_step_up = true
						step_result.diff_position.y = -test_motion_result.get_remainder().y
						step_result.normal = test_motion_result.get_collision_normal()
						break
			else:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
				transform3d.origin += wall_collision_normal * WALL_MARGIN
				motion = (main_velocity * delta).slide(wall_collision_normal)
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					test_motion_params.from = transform3d
					test_motion_params.motion = motion
					
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
					
					if is_player_collided:
						if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
							is_step = true
							step_result.is_step_up = true
							step_result.diff_position.y = -test_motion_result.get_remainder().y
							step_result.normal = test_motion_result.get_collision_normal()
							break

	if not is_jumping_started_ and not is_step and is_on_floor():
		step_result.is_step_up = false
		var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var transform3d: Transform3D = global_transform
		var motion: Vector3 = main_velocity * delta
		var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
		if not is_player_collided:
			transform3d.origin += motion
			motion = -step_height_main
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if is_player_collided and test_motion_result.get_travel().y < -STEP_DOWN_MARGIN:
				if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
					is_step = true
					step_result.diff_position.y = test_motion_result.get_travel().y
					step_result.normal = test_motion_result.get_collision_normal()
		elif is_zero_approx(test_motion_result.get_collision_normal().y):
			var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
			transform3d.origin += wall_collision_normal * WALL_MARGIN
			motion = (main_velocity * delta).slide(wall_collision_normal)
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -step_height_main
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided and test_motion_result.get_travel().y < -STEP_DOWN_MARGIN:
					if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
						is_step = true
						step_result.diff_position.y = test_motion_result.get_travel().y
						step_result.normal = test_motion_result.get_collision_normal()

	return is_step
	
	
func _on_sliding_timer_timeout():
	is_free_looking = false


func _on_animation_player_animation_finished(anim_name):
	is_roll_animation_finished = anim_name == 'roll'


func apply_external_force(force_vector: Vector3):
	if force_vector and force_vector.length() > 0:
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Applying external force " + str(force_vector))
		velocity += force_vector
		move_and_slide()


func _calculate_player_radius():
	var radius : float = 0.0
	for child in find_children("*", "CollisionShape3D", false, false):
		if child.shape is BoxShape3D:
			var edge = max(child.shape.size.x, child.shape.size.z)
			var r = sqrt(2 * pow(edge / 2, 2))
			radius = max(r, radius)
		elif child.shape is CylinderShape3D or child.shape is CapsuleShape3D:
			radius = max(child.shape.radius, radius)
	
	return radius


func _on_player_state_loaded():
	#TODO - reset look on load if needed
	#self.global_transform.basis = Basis()
	#neck.global_transform.basis = Basis()
	pass


func _physics_process(delta):
	if is_movement_paused:
		return
	
	_process_analog_stick_mouselook()
	
	_free_look(delta)


#region State Chart
enum MovingState {
	Undefined,
	Grounded,
	Idle,
	Walking,
	Sprinting,
	Sliding,
	Sneaking,
	Sitting,
	LadderClimbing,
	Rolling,
	LedgeClimbing,
	Airborne,
	AirControl,
	Jumping,
	FreeFall,
	Swimming
}

enum BodyPostureState {
	Undefined,
	Crouching,
	Standing,
	Sitting
}

var current_moving_state : MovingState
var current_body_posture_state : BodyPostureState

var jump_target_speed : float = 0.0
var was_sprinting : bool = false
var is_sprinting_in_airborne : bool = false
var was_sliding : bool = false
var was_standing : bool = false
var was_jumping : bool = false
var jumped_from_slide : bool = false
var jumped_from_crouch : bool = false
var was_in_air : bool = false
var try_crouch : bool
var wiggle_index : float = 0.0
var wiggle_current_intensity : float = 0.0
var bunny_hop_speed : float = SPRINTING_SPEED
var ledge_position : Vector3
var is_in_ledge_climbing_middle_stage : bool = false
var is_in_ledge_climbing_final_stage : bool = false


func _initialize_state_chart():
	state_chart.set_expression_property("on_ladder", on_ladder)
	state_chart.set_expression_property("is_sitting", is_sitting)
	
	for node_path in no_pause_menu_states:
		var state = get_node(node_path)
		state.state_entered.connect(func(): is_in_unpausable_state = true)
		state.state_exited.connect(func(): is_in_unpausable_state = false)
	
	for node_path in no_interaction_states:
		var state = get_node(node_path)
		state.state_entered.connect(func(): is_in_interaction_state = false)
		state.state_exited.connect(func(): is_in_interaction_state = true)


func is_in_crouching_state():
	return current_body_posture_state == BodyPostureState.Crouching


func is_in_sprinting_state():
	return current_moving_state == MovingState.Sprinting


func _is_ledge_climbable() -> bool:
	if not input_direction:
		return false
	
	direction = (body.global_transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()

	if direction.dot(-body.global_basis.z) < 0.5:
		return false
	
	if current_moving_state != MovingState.Swimming and not CAN_CLIMB_LEDGE:
		return false
	
	var initial_position = ledge_climbing_shapecast.position
	
	# Check ladder first because its priority is higher
	ledge_climbing_shapecast.global_position -= Vector3(0, ledge_climbing_shapecast_height, 0)
	ledge_climbing_shapecast.global_position += -body.global_basis.z * radius
	
	ledge_climbing_shapecast.target_position = Vector3.ZERO
	
	ledge_climbing_shapecast.collide_with_areas = true
	
	ledge_climbing_shapecast.force_shapecast_update()
	
	if ledge_climbing_shapecast.is_colliding():
		if ledge_climbing_shapecast.get_collider(0) is Ladder:
			ledge_climbing_shapecast.position = initial_position
			return false
	
	ledge_climbing_shapecast.collide_with_areas = false
	
	ledge_climbing_shapecast.position = initial_position
	
	if current_moving_state == MovingState.Swimming:
		ledge_climbing_shapecast.global_position -= Vector3(0, standing_height - crouching_height, 0)
	
	ledge_climbing_shapecast.force_shapecast_update()
	
	if ledge_climbing_shapecast.is_colliding():
		ledge_climbing_shapecast.position = initial_position
		return false
	
	ledge_climbing_shapecast.target_position = Vector3(0, ARM_LENGTH + MIN_FREE_SPACE_ABOVE_HEAD, 0)
	
	ledge_climbing_shapecast.force_shapecast_update()
	
	var collision_safe_fraction : float = 1.0
	
	if ledge_climbing_shapecast.is_colliding():
		ledge_climbing_shapecast.position = initial_position
		collision_safe_fraction = ledge_climbing_shapecast.get_closest_collision_safe_fraction()
	
	ledge_climbing_shapecast.global_position += Vector3(0, ARM_LENGTH + MIN_FREE_SPACE_ABOVE_HEAD, 0) * collision_safe_fraction
	ledge_climbing_shapecast.target_position = ledge_climbing_shapecast.global_basis * body.global_basis.z * radius

	ledge_climbing_shapecast.force_shapecast_update()
	
	if ledge_climbing_shapecast.is_colliding():
		ledge_climbing_shapecast.position = initial_position
		
		ledge_climbing_shapecast.force_shapecast_update()
		
		if ledge_climbing_shapecast.is_colliding():
			ledge_climbing_shapecast.position = initial_position
			return false
	
	ledge_climbing_shapecast.global_position += -body.global_basis.z * radius
	ledge_climbing_shapecast.target_position = Vector3(0, -(ARM_LENGTH + MIN_FREE_SPACE_ABOVE_HEAD) - (standing_height - MIN_CLIMB_HEIGHT), 0)
	
	ledge_climbing_shapecast.force_shapecast_update()
	
	if not ledge_climbing_shapecast.is_colliding():
		ledge_climbing_shapecast.position = initial_position
		return false
	
	var collision_normal : Vector3 = ledge_climbing_shapecast.get_collision_normal(0)
	
	if not collision_normal.is_equal_approx(Vector3.UP):
		ledge_climbing_shapecast.position = initial_position
		return false
	
	var collision_point = ledge_climbing_shapecast.get_collision_point(0)
	
	ledge_climbing_shapecast.global_position.y = collision_point.y + (ARM_LENGTH + MIN_FREE_SPACE_ABOVE_HEAD) / 2
	ledge_climbing_shapecast.target_position = Vector3.ZERO
	
	ledge_climbing_shapecast.force_shapecast_update()
	
	if ledge_climbing_shapecast.is_colliding():
		ledge_climbing_shapecast.position = initial_position
		return false
	
	ledge_climbing_shapecast.global_position.y = collision_point.y + (ARM_LENGTH + MIN_FREE_SPACE_ABOVE_HEAD) / 2
	ledge_climbing_shapecast.target_position = ledge_climbing_shapecast.global_basis * body.global_basis.z * radius

	ledge_climbing_shapecast.force_shapecast_update()
	
	if ledge_climbing_shapecast.is_colliding():
		ledge_climbing_shapecast.position = initial_position
		return false
	
	ledge_position = ledge_climbing_shapecast.global_position
	ledge_position.y = collision_point.y
	ledge_position += -body.global_basis.z * radius / 2
	
	ledge_climbing_shapecast.position = initial_position
	
	return true


func _can_jump() -> bool:
	if is_sitting:
		return false
		
	var doesnt_need_stamina = not stamina_attribute or stamina_attribute.value_current >= stamina_attribute.jump_exhaustion
	var crouch_jump = current_body_posture_state != BodyPostureState.Crouching or CAN_CROUCH_JUMP

	if not doesnt_need_stamina:
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd","Not enough stamina to jump.")
		
	if doesnt_need_stamina and crouch_jump:
		return true
		
	return false


func _handle_jump_on_platform():
	if platform_on_leave != PLATFORM_ON_LEAVE_DO_NOTHING:
		var platform_velocity = get_platform_velocity()
		# TODO: Make PLATFORM_ON_LEAVE_ADD_VELOCITY work... somehow. 
		# Velocity X and Z gets overridden later, so you immediately lose the velocity
		if PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY:
			platform_velocity.x = 0
			platform_velocity.z = 0
		main_velocity += platform_velocity


func _jump(_jump_target_speed) -> void:
	jump_target_speed = _jump_target_speed
	
	if Input.is_action_pressed("sprint"):
		was_sprinting = true
	else:
		was_sprinting = false
		
	jump_timer.start() # prevent spam
	is_jumping_started = true
	is_in_air = false
	jumped_from_crouch = current_body_posture_state == BodyPostureState.Crouching
	
	var jump_vel = CROUCH_JUMP_VELOCITY if current_body_posture_state == BodyPostureState.Crouching else JUMP_VELOCITY
	
	# If Stamina Component is used, this checks if there's enough stamina to jump and denies it if not.
	if stamina_attribute:
		decrease_attribute("stamina",stamina_attribute.jump_exhaustion)
	
	animationPlayer.play("jump")
	Audio.play_sound(jump_sound)
	
	if current_moving_state != MovingState.LadderClimbing:
		main_velocity.y = jump_vel
	else:
		main_velocity.y = jump_vel * LADDER_JUMP_SCALE
	
	was_jumping = true
	jumped_from_slide = false
	
	_handle_jump_on_platform()
	
	state_chart.send_event("jump")


func _sliding_jump(_jump_target_speed) -> void:
	jump_target_speed = _jump_target_speed
	
	jump_timer.start() # prevent spam
	is_jumping_started = true
	is_in_air = false
	jumped_from_crouch = current_body_posture_state == BodyPostureState.Crouching
	
	# If Stamina Component is used, this checks if there's enough stamina to jump and denies it if not.
	if stamina_attribute:
		decrease_attribute("stamina",stamina_attribute.jump_exhaustion)
	
	animationPlayer.play("jump")
	Audio.play_sound(jump_sound)

	main_velocity.y = JUMP_VELOCITY * SLIDE_JUMP_MOD
	
	was_jumping = true
	jumped_from_slide = true
	
	sliding_timer.stop()
	
	_handle_jump_on_platform()
	
	try_crouch = false
	state_chart.send_event("stand_up")
	state_chart.send_event("jump")


func _input_handling_and_movement(delta):
	input_direction = Input.get_vector("left", "right", "forward", "back")

	current_speed = clamp(current_speed, MIN_SPEED, MAX_SPEED)
	
	if direction:
		main_velocity.x = direction.x * current_speed
		main_velocity.z = direction.z * current_speed
	else:
		main_velocity.x = move_toward(main_velocity.x, 0, current_speed)
		main_velocity.z = move_toward(main_velocity.z, 0, current_speed)
		
	# Store current velocity for the next frame
	last_velocity = main_velocity
	
	# Velocity for current frame
	var main_velocity_before_stair_stepping : Vector3 = main_velocity + gravity_vec
	
	_stair_handling(delta)
	
	# Velocity for next frame. Stair steppting can modify main_velocity and gravity_vec.
	main_velocity += gravity_vec
	
	velocity = main_velocity_before_stair_stepping
	
	move_and_slide()


func _handle_swim_under_water_sounds():
	if is_head_in_water():
		if not swim_under_water_audio_player:
			swim_audio_init()
		
		if !swim_under_water_audio_player.playing:
			var audio_length : float = swim_under_water_audio_player.stream.get_length()
			swim_under_water_audio_player.play(randf_range(0, audio_length))
	else:
		if swim_under_water_audio_player:
			swim_under_water_audio_player.stop()


#region Grounded State
var wiggle_vector : Vector2 = Vector2.ZERO
var can_play_footstep : bool = true


func _on_grounded_on_pause_taken() -> void:
	if not is_dead:
		if current_moving_state == MovingState.Sliding:
			was_sliding = true
	else:
		was_sliding = false


func _on_grounded_state_entered() -> void:
	# Only trigger landing sound if the player was airborne and the velocity exceeds the threshold
	if was_in_air and last_velocity.y < landing_threshold:
		# Calculate the volume and pitch based on the landing velocity
		var velocity_ratio = clamp((last_velocity.y - min_landing_velocity) / (max_landing_velocity - min_landing_velocity), 0.0, 1.0)
		# Set the volume and pitch of the landing sound
		LandingVolume = lerp(min_volume_db, max_volume_db, velocity_ratio)
		LandingPitch = lerp(max_pitch, min_pitch, velocity_ratio)
		# Play the landing sound
		footstep_player._play_interaction("landing")
	was_in_air = false  # Reset airborne state


func _on_grounded_state_physics_processing(delta: float) -> void:
	if is_sitting:
		return
		
	_input_handling_and_movement(delta)
	
	if not is_head_in_water():
		under_water_effect.visible = false
	else:
		under_water_effect.visible = true
	
	_handle_swim_under_water_sounds()
	
	if is_head_in_water():
		state_chart.send_event("swim")
		return
		
	if not is_on_floor():
		if current_moving_state == MovingState.Sliding:
			was_sliding = true
		state_chart.send_event("airborne")
		return
		
	if current_moving_state == MovingState.Rolling:
		return
		
	if not is_jumping_started:
		main_velocity.y = 0
		gravity_vec = Vector3.ZERO
	
	## Taking fall damage
	if fall_damage > 0 and last_velocity.y <= fall_damage_threshold:
		var damage_ratio : float = last_velocity.y / fall_damage_threshold
		decrease_attribute("health", int(fall_damage * damage_ratio))
		
	if last_velocity.y <= LANDING_MIN_ROLL_VELOCITY:
		if !disable_roll_anim:
			was_standing = current_body_posture_state == BodyPostureState.Standing
			is_sprinting_in_airborne = false
			state_chart.send_event("roll")
			return
	elif last_velocity.y <= LANDING_MIN_VELOCITY:
		animationPlayer.play("landing")
		
	if was_sliding:
		if is_on_floor():
			state_chart.send_event("slide")
			return
		
	if current_moving_state != MovingState.Sliding and input_direction != Vector2.ZERO:
		wiggle_vector.y = sin(wiggle_index)
		wiggle_vector.x = sin(wiggle_index / 2) + 0.5
		eyes.position.y = lerp(
			eyes.position.y,
			wiggle_vector.y * (wiggle_current_intensity / 2.0), 
			delta * LERP_SPEED
		)
		eyes.position.x = lerp(
			eyes.position.x,
			wiggle_vector.x * wiggle_current_intensity, 
			delta * LERP_SPEED
		)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * LERP_SPEED)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * LERP_SPEED)
		
	direction = lerp(
		direction,
		(body.global_transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized(),
		delta * LERP_SPEED
	)
	
	_footstep_sounds_system()
	
	if was_jumping and not jumped_from_slide and Input.is_action_pressed("sprint") and is_sprinting_in_airborne:
		if current_body_posture_state == BodyPostureState.Crouching and not jumped_from_crouch:
			was_sprinting = false
			state_chart.send_event("slide")
			
	is_sprinting_in_airborne = false


func _footstep_sounds_system():
	# FOOTSTEP SOUNDS SYSTEM = CHECK IF ON GROUND AND MOVING
	if main_velocity.length() >= 0.2:
		if current_moving_state == MovingState.Sliding:
			if !slide_audio_player.playing:
				slide_audio_player.play()
		else:
			if slide_audio_player:
				slide_audio_player.stop()
			
			if can_play_footstep && wiggle_vector.y > 0.9:
				#dynamic volume for footsteps
				if current_moving_state == MovingState.Walking:
					footstep_player.volume_db = walk_volume_db
				elif current_body_posture_state == BodyPostureState.Crouching:
					footstep_player.volume_db = crouch_volume_db
				elif current_moving_state == MovingState.Sprinting:
					footstep_player.volume_db = sprint_volume_db
				footstep_player._play_interaction("footstep")
					
				can_play_footstep = false
				
			if !can_play_footstep && wiggle_vector.y < 0.9:
				can_play_footstep = true
#endregion


#region Idle State
func _on_idle_state_entered() -> void:
	current_moving_state = MovingState.Idle


func _on_idle_state_exited() -> void:
	current_moving_state = MovingState.Undefined


func _on_idle_state_physics_processing(delta: float) -> void:
	if not main_velocity.is_equal_approx(Vector3.ZERO):
		if current_body_posture_state == BodyPostureState.Crouching:
			state_chart.send_event("sneak")
			return
		else:
			state_chart.send_event("walk")
			return
	
	if Input.is_action_pressed("jump") and jump_timer.is_stopped():
		if not _can_jump():
			return
		
		_jump(WALKING_SPEED)
#endregion


#region Walking State
func _on_walking_state_entered() -> void:
	current_moving_state = MovingState.Walking


func _on_walking_state_exited() -> void:
	current_moving_state = MovingState.Undefined


func _on_walking_state_physics_processing(delta: float) -> void:
	if current_body_posture_state == BodyPostureState.Crouching:
		state_chart.send_event("sneak")
		return

	if not on_ladder and Input.is_action_pressed("sprint") and stamina_attribute and stamina_attribute.value_current > 5:
		state_chart.send_event("sprint")
		return
		
	current_speed = lerp(current_speed, WALKING_SPEED, delta * LERP_SPEED)
	wiggle_current_intensity = WIGGLE_ON_WALKING_INTENSITY * HEADBOBBLE
	wiggle_index += WIGGLE_ON_WALKING_SPEED * delta
	
	if main_velocity.is_equal_approx(Vector3.ZERO):
		state_chart.send_event("idle")
	
	if Input.is_action_pressed("jump") and jump_timer.is_stopped():
		if not _can_jump():
			return

		#current_speed = WALKING_SPEED
		_jump(WALKING_SPEED)
#endregion


#region Sprinting State
func _on_sprinting_state_entered() -> void:
	current_moving_state = MovingState.Sprinting


func _on_sprinting_state_exited() -> void:
	current_moving_state = MovingState.Undefined


func _on_sprinting_state_physics_processing(delta: float) -> void:
	if Input.is_action_pressed("sprint"):
		if !stamina_attribute or (stamina_attribute and stamina_attribute.value_current > 0):
			if stamina_attribute and stamina_attribute.value_current <= 0.2:
				bunny_hop_speed = SPRINTING_SPEED
				state_chart.send_event("walk")
				return
			
			if !Input.is_action_pressed("jump"):
				if CAN_BUNNYHOP:
					bunny_hop_speed = SPRINTING_SPEED
					current_speed = lerp(current_speed, bunny_hop_speed, delta * LERP_SPEED)
				else:
					current_speed = lerp(current_speed, SPRINTING_SPEED, delta * LERP_SPEED)
				
			wiggle_current_intensity = WIGGLE_ON_SPRINTING_INTENSITY * HEADBOBBLE
			wiggle_index += WIGGLE_ON_SPRINTING_SPEED * delta
		
		if Input.is_action_pressed("jump") and jump_timer.is_stopped():
			if current_speed < bunny_hop_speed - 0.2:
				current_speed = lerp(current_speed, bunny_hop_speed, delta * LERP_SPEED)
			else:
				if CAN_BUNNYHOP:
					bunny_hop_speed += BUNNY_HOP_ACCELERATION
					bunny_hop_speed = clamp(bunny_hop_speed, SPRINTING_SPEED, MAX_SPEED)
					current_speed = bunny_hop_speed
				else:
					current_speed = SPRINTING_SPEED
			
			if not _can_jump():
				bunny_hop_speed = SPRINTING_SPEED
				return
			
			_jump(bunny_hop_speed)
	else:
		bunny_hop_speed = SPRINTING_SPEED
		state_chart.send_event("walk")
#endregion


#region Sliding State
var slide_vector : Vector2 = Vector2.ZERO


func _on_sliding_state_entered() -> void:
	current_moving_state = MovingState.Sliding
	
	if not was_sliding:
		sliding_timer.start()
		slide_vector = input_direction
		
	was_sliding = false


func _on_sliding_state_exited() -> void:
	current_moving_state = MovingState.Undefined
	
	if slide_audio_player:
		slide_audio_player.stop()


func _on_sliding_state_physics_processing(delta: float) -> void:
	if input_direction == Vector2.ZERO:
		sliding_timer.stop()
		state_chart.send_event("idle")
		return
		
	if !Input.is_action_pressed("sprint"):
		sliding_timer.stop()
		if current_body_posture_state == BodyPostureState.Standing:
			state_chart.send_event("walk")
		else:
			state_chart.send_event("sneak")
		return
		
	if sliding_timer.is_stopped():
		if current_body_posture_state == BodyPostureState.Standing:
			state_chart.send_event("walk")
		else:
			state_chart.send_event("sneak")
	else:
		direction = (body.global_transform.basis * Vector3(slide_vector.x, 0.0, slide_vector.y)).normalized()
		current_speed = (sliding_timer.time_left / sliding_timer.wait_time + 0.5) * SLIDING_SPEED
		
		if Input.is_action_pressed("jump") and jump_timer.is_stopped():
			if not _can_jump():
				return
				
			_sliding_jump(current_speed)
#endregion


#region Sneaking State
func _on_sneaking_state_entered() -> void:
	current_moving_state = MovingState.Sneaking


func _on_sneaking_state_exited() -> void:
	current_moving_state = MovingState.Undefined


func _on_sneaking_state_physics_processing(delta: float) -> void:
	wiggle_index += WIGGLE_ON_CROUCHING_SPEED * delta
	eyes.position.y = lerp(eyes.position.y, 0.0, delta * LERP_SPEED)
	eyes.position.x = lerp(eyes.position.x, 0.0, delta * LERP_SPEED)
	
	current_speed = lerp(current_speed, CROUCHING_SPEED, delta * LERP_SPEED)

	if main_velocity.is_equal_approx(Vector3.ZERO):
		state_chart.send_event("idle")
	
	if Input.is_action_pressed("jump") and jump_timer.is_stopped():
		if not _can_jump():
			return

		jumped_from_crouch = true
		_jump(CROUCHING_SPEED)
#endregion


#region Sitting State
#Sittable Vars
var original_position: Transform3D
var displacement_position: Vector3
var is_sitting: bool  = false
var sittable_look_marker: Vector3
var sittable_look_angle: float
var moving_seat: bool = false
var original_neck_basis: Basis = Basis()
var is_ejected: bool = false
var currently_tweening: bool = false


func _on_sitting_state_entered() -> void:
	state_chart.set_expression_property("is_sitting", is_sitting)
	current_moving_state = MovingState.Sitting


func _on_sitting_state_exited() -> void:
	state_chart.set_expression_property("is_sitting", is_sitting)
	current_moving_state = MovingState.Undefined


func _on_sitting_state_physics_processing(delta: float) -> void:
	if is_sitting:
		_process_on_sittable(delta)


func _process_on_sittable(delta):
	var sittable = CogitoSceneManager._current_sittable_node
	# Processing analog stick mouselook  TODO Rewrite for Look angle marker support
	if joystick_h_event:
			if abs(joystick_h_event.get_axis_value()) > JOY_DEADZONE:
				if INVERT_Y_AXIS:
					head.rotate_x(deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				else:
					head.rotate_x(-deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-sittable.horizontal_look_angle), deg_to_rad(sittable.horizontal_look_angle))
				
	if joystick_v_event:
		if abs(joystick_v_event.get_axis_value()) > JOY_DEADZONE:
			neck.rotate_y(deg_to_rad(-joystick_v_event.get_axis_value() * JOY_V_SENS))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-180), deg_to_rad(180))

	#avoids instantly moving to seat before tween is finished
	if not currently_tweening:
		self.global_transform = sittable.sit_position_node.global_transform
	#Check if the player should be ejected, is_ejected is flag to prevent multiple calls
	if sittable.eject_on_fall == true and not is_ejected:
		var chair_up_vector = sittable.global_transform.basis.y
		var global_up_vector = Vector3(0, 1, 0)
		# Calculate angle between chair's up vector and the global up vector
		var angle_to_up = rad_to_deg(chair_up_vector.angle_to(global_up_vector))
		# If the angle is greater than a threshold of 45 degrees, the chair has fallen over
		if angle_to_up > sittable.eject_angle:
			is_ejected = true  # Set the flag to avoid repeated ejections
			CogitoSceneManager._current_sittable_node.interact(player_interaction_component) #Interact with sittable to reset state and eject


func toggle_sitting():
	if is_sitting:
		_stand_up()
	else:
		_sit_down()


func _on_sit_requested(sittable: Node):
	if not is_sitting:
		_sit_down()


func _on_stand_requested():
	if is_sitting:
		_stand_up()	


func _on_seat_move_requested(sittable: Node):
	moving_seat = true
	_sit_down()


func handle_sitting_look(event):
	#TODO - Fix for vehicles by handling dynamic look marker, Fix for controller support
	var neck_position = neck.global_transform.origin
	var look_marker_position = sittable_look_marker
	var target_direction = Vector2(look_marker_position.x - neck_position.x, look_marker_position.z - neck_position.z).normalized()

	# Get the current neck forward direction
	var neck_forward = neck.global_transform.basis.z
	var neck_direction = Vector2(neck_forward.x, neck_forward.z).normalized()

	# Angle between neck direction and look marker direction
	var angle_to_marker = rad_to_deg(neck_direction.angle_to(target_direction))

	# Apply mouse input to rotate neck
	neck.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))

	# Updated neck direction after rotation
	neck_forward = neck.global_transform.basis.z
	neck_direction = Vector2(neck_forward.x, neck_forward.z).normalized()

	# New angle after rotation
	var new_angle_to_marker = rad_to_deg(neck_direction.angle_to(target_direction))
	new_angle_to_marker = wrapf(new_angle_to_marker, 0, 360)
	
	# Check if the new angle is within the limits
	if not (new_angle_to_marker > 180-sittable_look_angle and new_angle_to_marker < (180 + sittable_look_angle)):
		neck.rotation.y -= deg_to_rad(-event.relative.x * MOUSE_SENS)
	
	if INVERT_Y_AXIS:
		head.rotate_x(-deg_to_rad(-event.relative.y * MOUSE_SENS))
	else:
		head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
	
	var sittable = CogitoSceneManager._current_sittable_node
	
	if sittable.physics_sittable == false:
		#static sittables are fine to be clamped this way
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-sittable.vertical_look_angle), deg_to_rad(sittable.vertical_look_angle))
	else:
		# TODO replace with dynamic vertical look range based on look marker
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-sittable.vertical_look_angle), deg_to_rad(sittable.vertical_look_angle))


func _sit_down():
	standing_collision_shape.disabled = true
	crouching_collision_shape.disabled = true
	is_ejected = false 
		
	var sittable = CogitoSceneManager._current_sittable_node
	if sittable:
		is_sitting = true
		set_physics_process(false)
		state_chart.send_event("sit")
		if sittable.look_marker_node:
			sittable_look_marker = sittable.look_marker_node.global_transform.origin
		sittable_look_angle = sittable.horizontal_look_angle
		if moving_seat == false:
			original_position = self.global_transform
			original_neck_basis = neck.global_transform.basis
			displacement_position = sittable.global_transform.origin - self.global_transform.origin
		
		#TODO: Implement crouch handling
		
		# Check if the sittable is physics-based
		if sittable.physics_sittable:
			currently_tweening = true
			set_physics_process(true)
			#just using same tween for now with less tween time on chair_desk, TODO create a more dynamic 'tween' in physics process
			var tween = create_tween()
			tween.tween_property(self, "global_transform", sittable.sit_position_node.global_transform, sittable.tween_duration)
			tween.tween_callback(Callable(self, "_sit_down_finished"))

		else:
			# Static tween for non-physics sittable
			currently_tweening = true
			var tween = create_tween()
			tween.tween_property(self, "global_transform", sittable.sit_position_node.global_transform, sittable.tween_duration)
			tween.tween_callback(Callable(self, "_sit_down_finished"))


func _sit_down_finished():
	is_sitting = true
	crouch_shapecast.enabled = false
	set_physics_process(true)
	var sittable = CogitoSceneManager._current_sittable_node
	standing_collision_shape.disabled = true
	crouching_collision_shape.disabled = true
	currently_tweening = false
	if sittable_look_marker:
		var tween = create_tween()
		var target_transform = neck.global_transform.looking_at(sittable_look_marker, Vector3.UP)
		tween.tween_property(neck, "global_transform:basis", target_transform.basis, sittable.rotation_tween_duration)


func _stand_up():
	var sittable = CogitoSceneManager._current_sittable_node
	if sittable:
		
		#is_sitting = false
		set_physics_process(false)
		state_chart.send_event("grounded")
		#TODO: Implement crouch handling
		# Handle player exit placement on stand-up based on the placement_leave_behaviour of the sittable
		match sittable.placement_on_leave:
			sittable.PlacementOnLeave.ORIGINAL:
				_move_to_original_position(sittable)
			sittable.PlacementOnLeave.AUTO:
				_move_to_nearby_location(sittable)
			sittable.PlacementOnLeave.TRANSFORM:
				_move_to_leave_node(sittable)
			sittable.PlacementOnLeave.DISPLACEMENT:
				_move_to_displacement_position(sittable) 
					
		moving_seat = false

#Functions to handle Exit types


#Return player to Original position
func _move_to_original_position(sittable):
	currently_tweening = true
	var tween = create_tween()
	tween.tween_property(self, "global_transform", original_position, sittable.tween_duration)
	tween.tween_property(neck, "global_transform:basis", original_neck_basis, sittable.rotation_tween_duration)
	tween.tween_callback(Callable(self, "_stand_up_finished"))


#Return player to Leave node position
func _move_to_leave_node(sittable):
	currently_tweening = true
	if sittable.leave_node_path:
		var leave_node = sittable.get_node(sittable.leave_node_path)
		if leave_node:
			var tween = create_tween()
			tween.tween_property(self, "global_transform", leave_node.global_transform, sittable.tween_duration)
			tween.tween_property(neck, "global_transform:basis", original_neck_basis, sittable.rotation_tween_duration)
			tween.tween_callback(Callable(self, "_stand_up_finished"))
		else:
			CogitoGlobals.debug_log(true, "CogitoProjectile", "No leave node found. Returning to Original position")
			_move_to_original_position(sittable)


#Find location using navmesh to place player
func _move_to_nearby_location(sittable):
	CogitoGlobals.debug_log(true, "CogitoPlayer", "Attempting to find available locations to move player to")
	var seat_position = sittable.global_transform.origin
	var exit_distance: float = 1.0
	var max_distance: float = 10.0 # Max distance from Sittable to try, multiplies the random direction
	var step_increase: float = 0.5
	var max_attempts: int = 10
	var navmesh_offset_y: float = 0.25
	var attempts: int = 0


	var player_position = self.global_transform.origin

	while attempts < max_attempts:
		# Generate random direction
		var random_direction = Vector3(
			randf_range(-0.1, 0.1),
			randf_range(-0.1, 0.1),  # Degree of Y random actually makes this work better at finding candidates
			randf_range(-0.1, 0.1)
		).normalized()
		
		var candidate_pos = seat_position + (random_direction * exit_distance)
		candidate_pos.y = navmesh_offset_y  # to check navmesh at navmesh height

		navigation_agent.target_position = candidate_pos

		# Check if position is reachable
		if navigation_agent.is_navigation_finished():
			currently_tweening = true
			var tween = create_tween()
			navigation_agent.target_position.y += 1 # To avoid player going through floor
			tween.tween_property(self, "global_transform:origin", navigation_agent.target_position, sittable.tween_duration)
			tween.tween_property(neck, "global_transform:basis", original_neck_basis, sittable.rotation_tween_duration)
			tween.tween_callback(Callable(self, "_stand_up_finished"))
			return
		else:
			exit_distance += step_increase
			attempts += 1

		if exit_distance > max_distance:
			exit_distance = 1

	# If no valid location found, try leave node
	CogitoGlobals.debug_log(true, "CogitoPlayer", "No available location found after " + str(attempts) + " tries. Testing for leave node.")
	_move_to_leave_node(sittable)


func _move_to_displacement_position(sittable):
	var tween = create_tween()
	var new_position = sittable.global_transform.origin - displacement_position
	var new_transform = self.global_transform
	new_transform.origin = new_position
	tween.tween_property(self, "global_transform", new_transform, sittable.tween_duration)
	tween.tween_property(neck, "global_transform:basis", original_neck_basis, sittable.rotation_tween_duration)
	tween.tween_callback(Callable(self, "_stand_up_finished"))


func _stand_up_finished():
	is_sitting = false
	crouch_shapecast.enabled = true
	set_physics_process(true)
	state_chart.send_event("grounded")
	try_crouch = false
	state_chart.send_event("stand_up")
	standing_collision_shape.disabled = false
	#crouching_collision_shape.disabled = false
	self.global_transform.basis = Basis()
	neck.global_transform.basis = original_neck_basis  
	currently_tweening = false
#endregion


#region Rolling state
func _on_rolling_state_entered() -> void:
	current_moving_state = MovingState.Rolling
	animationPlayer.play("roll")
	try_crouch = true
	state_chart.send_event("crouch")


func _on_rolling_state_exited() -> void:
	current_moving_state = MovingState.Undefined


func _on_rolling_state_physics_processing(delta: float) -> void:
	if is_roll_animation_finished:
		is_roll_animation_finished = false
		if was_standing:
			try_crouch = false
			state_chart.send_event("stand_up")
		else:
			state_chart.send_event("grounded")
#endregion


#region Airborne State
func _on_airborne_state_entered() -> void:
	was_in_air = true  # Set airborne state
	current_moving_state = MovingState.Airborne


func _on_airborne_state_physics_processing(delta: float) -> void:
	_input_handling_and_movement(delta)
	
	if is_head_in_water():
		state_chart.send_event("swim")
		return
	
	if is_on_ceiling():
		main_velocity.y = 0
	
	gravity_vec = Vector3.DOWN * gravity * delta

	if was_sprinting and Input.is_action_pressed("sprint"):
		is_sprinting_in_airborne = true
	else:
		bunny_hop_speed = SPRINTING_SPEED
		was_sprinting = false
		is_sprinting_in_airborne = false

	if slide_audio_player:
		slide_audio_player.stop()

	if is_on_floor():
		state_chart.send_event("grounded")
#endregion


#region AirControl State
func _on_air_control_state_entered() -> void:
	current_moving_state = MovingState.AirControl


func _on_air_control_state_exited() -> void:
	current_moving_state = MovingState.Undefined


func _on_air_control_state_physics_processing(delta: float) -> void:
	if input_direction != Vector2.ZERO:
		direction = lerp(
			direction,
			(body.global_transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized(),
			delta * AIR_LERP_SPEED
		)
		
	if main_velocity.y <= FREE_FALL_MIN_VELOCITY:
		state_chart.send_event("fall")
#endregion


#region Jumping State
func _on_jumping_state_entered() -> void:
	current_moving_state = MovingState.Jumping


func _on_jumping_state_exited() -> void:
	current_moving_state = MovingState.Undefined


func _on_jumping_state_physics_processing(delta: float) -> void:
	if input_direction != Vector2.ZERO:
		direction = lerp(
			direction,
			(body.global_transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized(),
			delta * AIR_LERP_SPEED
		)
		
	current_speed = lerp(current_speed, jump_target_speed, delta * LERP_SPEED)
	
	if is_on_wall():
		var normal = get_wall_normal()
		var angle = rad_to_deg(direction.angle_to(normal))
		if angle > BUNNY_HOP_WALL_SLIDE_ANGLE:
			bunny_hop_speed = SPRINTING_SPEED
	
	if current_body_posture_state != BodyPostureState.Crouching:
		if _is_ledge_climbable():
			bunny_hop_speed = SPRINTING_SPEED
			state_chart.send_event("ledge_climb")
			return
	
	if main_velocity.y <= FREE_FALL_MIN_VELOCITY:
		state_chart.send_event("fall")
#endregion


#region FreeFall State
func _on_free_fall_state_entered() -> void:
	current_moving_state = MovingState.FreeFall


func _on_free_fall_state_exited() -> void:
	current_moving_state = MovingState.Undefined


func _on_free_fall_state_physics_processing(delta: float) -> void:
	if main_velocity.y <= FREE_FALL_MIN_DIE_VELOCITY:
		decrease_attribute("health", $HealthAttribute.value_max)
#endregion


#region LadderClimbing State
var ladder_direction : Vector3

func _on_ladder_climbing_state_entered() -> void:
	current_moving_state = MovingState.LadderClimbing
	
	last_velocity = Vector3.ZERO
	
	was_jumping = false


func _on_ladder_climbing_state_exited() -> void:
	on_ladder = false
	state_chart.set_expression_property("on_ladder", on_ladder)
	current_moving_state = MovingState.Undefined


func _on_ladder_climbing_state_physics_processing(delta: float) -> void:
	if not is_head_in_water():
		under_water_effect.visible = false
	else:
		under_water_effect.visible = true
		
	_process_on_ladder(delta)


func _process_on_ladder(_delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	
	_handle_swim_under_water_sounds()
	
	var ladder_speed = LADDER_SPEED
	
	if CAN_SPRINT_ON_LADDER and Input.is_action_pressed("sprint") and input_dir.length_squared() > 0.1:
		#is_sprinting = true
		if stamina_attribute.value_current > 0:
			ladder_speed = LADDER_SPRINT_SPEED
	#else:
		#is_sprinting = false
		
	var jump = Input.is_action_pressed("jump")

	# Processing analog stick mouselook
	if joystick_h_event:
			if abs(joystick_h_event.get_axis_value()) > JOY_DEADZONE:
				if INVERT_Y_AXIS:
					head.rotate_x(deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				else:
					head.rotate_x(-deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
				
	if joystick_v_event:
		if abs(joystick_v_event.get_axis_value()) > JOY_DEADZONE:
			neck.rotate_y(deg_to_rad(-joystick_v_event.get_axis_value() * JOY_V_SENS))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))

	var look_vector = camera.get_camera_transform().basis
	var looking_down = look_vector.z.dot(Vector3.UP) > 0.5

	# Applying ladder input_dir to direction
	var y_dir = 1 if looking_down else -1
	direction = (body.global_transform.basis * Vector3(input_dir.x,input_dir.y * y_dir,0)).normalized()
	main_velocity = direction * ladder_speed
	
	if jump:
		var jump_direction = (body.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if jump_direction and not jump_direction.dot(ladder_direction) < 0:
			if not _can_jump():
				return
			
			_jump(WALKING_SPEED)
			
			return
	
	velocity = main_velocity
	move_and_slide()
	
	#Step off ladder when on ground
	if is_on_floor() and not ladder_on_cooldown:
		on_ladder = false
		state_chart.send_event("grounded")


func ladder_buffer_finished():
	ladder_on_cooldown = false


func enter_ladder(ladder: CollisionShape3D, ladderDir: Vector3):
	# called by ladder_area.gd
	ladder_direction = ladderDir
	# try and capture player's intent based on where they're looking
	var look_vector = camera.get_camera_transform().basis
	var looking_away = look_vector.z.dot(ladderDir) < 0.33
	var looking_down = look_vector.z.dot(Vector3.UP) > 0.5
	if looking_down or not looking_away:
		var ladder_timer = get_tree().create_timer(LADDER_COOLDOWN)
		ladder_timer.timeout.connect(ladder_buffer_finished)
		ladder_on_cooldown = true
		if not on_ladder:
			on_ladder = true
			state_chart.send_event("climb_ladder")
			state_chart.set_expression_property("on_ladder", on_ladder)


func exit_ladder():
	var is_still_on_ladder = false
	
	var ladder_check_shapecast : ShapeCast3D = ShapeCast3D.new()
	add_child(ladder_check_shapecast)
	ladder_check_shapecast.add_exception(self)
	ladder_check_shapecast.collision_mask = 3
	ladder_check_shapecast.collide_with_areas = true
	ladder_check_shapecast.position = crouching_collision_shape.position
	ladder_check_shapecast.target_position = Vector3.ZERO
	ladder_check_shapecast.shape = crouching_collision_shape.shape
	ladder_check_shapecast.force_shapecast_update()
	if ladder_check_shapecast.is_colliding():
		for i in ladder_check_shapecast.get_collision_count():
			var collider = ladder_check_shapecast.get_collider(i)
			if collider is Ladder:
				is_still_on_ladder = true
				break
	
	remove_child(ladder_check_shapecast)
	
	if is_still_on_ladder:
		on_ladder = true
		return
		
	on_ladder = false
	state_chart.set_expression_property("on_ladder", on_ladder)
	
	state_chart.send_event("airborne")
#endregion


#region Swimming State
var can_play_swim_movement : bool = true


func is_body_in_water() -> bool:
	if get_tree().get_nodes_in_group("water_area").all(func(area): return !area.overlaps_body(self)):
		return false
	else:
		return true


func is_head_in_water() -> bool:
	swimming_head_shapecast.force_shapecast_update()
	
	if not swimming_head_shapecast.is_colliding():
		return false
	
	return true


func _handle_water_physics(delta) -> void:
	input_direction = Input.get_vector("left", "right", "forward", "back")
	
	var look_vector = camera.get_camera_transform().basis
	var direction = look_vector * Vector3(input_direction.x, 0, input_direction.y).normalized()
	
	if not is_head_in_water() and direction.dot(Vector3.UP) > 0:
		direction = direction.slide(Vector3.UP)
	
	current_speed = lerp(current_speed, SWIMMING_SPEED, delta * LERP_SPEED)
	
	if input_direction:
		main_velocity = lerp(main_velocity, direction * SWIMMING_SPEED, delta * LERP_SPEED)
	else:
		main_velocity = lerp(main_velocity, Vector3.ZERO, delta * LERP_SPEED)
		
		if Input.is_action_pressed("jump"):
			if is_head_in_water():
				main_velocity.y = lerp(main_velocity.y, SWIMMING_SPEED, delta * LERP_SPEED)
		else:
			if not is_on_floor():
				main_velocity.y -= gravity * WATER_GRAVITY_COEFFICIENT * delta
	
	_handle_swim_under_water_sounds()
	
	if input_direction and main_velocity.length() >= 0.2:
		if can_play_swim_movement && wiggle_vector.y > 0.9:
			Audio.play_sound_3d(swim_movement_sound)
			can_play_swim_movement = false
		
		if !can_play_swim_movement && wiggle_vector.y < 0.9:
			can_play_swim_movement = true
	
	velocity = main_velocity
	
	move_and_slide()


func _on_swimming_state_entered() -> void:
	current_moving_state = MovingState.Swimming
	
	last_velocity = Vector3.ZERO
	gravity_vec = Vector3.ZERO
	direction = Vector3.ZERO
	
	try_crouch = true
	state_chart.send_event("crouch")


func _on_swimming_state_exited() -> void:
	current_moving_state = MovingState.Undefined


func _on_swimming_state_physics_processing(delta: float) -> void:
	wiggle_index += WIGGLE_ON_SWIMMING_SPEED * delta
	wiggle_vector.y = sin(wiggle_index)
	wiggle_vector.x = sin(wiggle_index / 2) + 0.5
	
	if not is_head_in_water():
		under_water_effect.visible = false
		if is_on_floor():
			state_chart.send_event("grounded")
			return
	else:
		under_water_effect.visible = true
	
	_handle_water_physics(delta)
	
	if Input.is_action_pressed("jump") and _is_ledge_climbable():
		state_chart.send_event("ledge_climb")
		return
		
#endregion


#region LedgeClimbing State
func _on_ledge_climbing_state_entered() -> void:
	current_moving_state = MovingState.LedgeClimbing
	
	main_velocity = Vector3.ZERO
	last_velocity = Vector3.ZERO
	gravity_vec = Vector3.ZERO
	direction = Vector3.ZERO
	
	was_jumping = false


func _on_ledge_climbing_state_exited() -> void:
	current_moving_state = MovingState.Undefined
	is_in_ledge_climbing_final_stage = false
	is_in_ledge_climbing_middle_stage = false


func _on_ledge_climbing_state_physics_processing(delta: float) -> void:
	if not is_head_in_water():
		under_water_effect.visible = false
	else:
		under_water_effect.visible = true
	
	_handle_swim_under_water_sounds()
	
	if not Input.is_action_pressed("jump") and not is_in_ledge_climbing_middle_stage:
		state_chart.send_event("idle")
		try_crouch = false
		state_chart.send_event("stand_up")
		return
	
	var move_direction = Vector3.UP
	velocity = move_direction * CLIMBING_SPEED
	
	if crouching_collision_shape.global_position.y + ((standing_height - (2 * crouching_height)) + crouching_height / 2) < ledge_position.y:
		move_and_slide()
		return
	
	if current_body_posture_state != BodyPostureState.Crouching:
		is_in_ledge_climbing_middle_stage = true
		try_crouch = true
		state_chart.send_event("crouch")
		return
	
	is_in_ledge_climbing_middle_stage = true
	
	if not is_in_ledge_climbing_final_stage and crouching_collision_shape.global_position.y - (crouching_height / 2 + MIN_FREE_SPACE_ABOVE_HEAD) < ledge_position.y:
		move_and_slide()
		return
	
	is_in_ledge_climbing_final_stage = true

	move_direction = crouching_collision_shape.global_position.direction_to(ledge_position + Vector3(0, crouching_height / 2, 0))

	velocity = move_direction * CLIMBING_SPEED
	
	move_and_slide()
	
	if (ledge_position + Vector3(0, crouching_height / 2, 0)).distance_to(crouching_collision_shape.global_position) < 0.1:
		state_chart.send_event("idle")
		if AUTO_STAND_AFTER_CLIMB:
			try_crouch = false
			state_chart.send_event("stand_up")
#endregion


#region Crouching State
func _on_crouching_state_entered() -> void:
	current_body_posture_state = BodyPostureState.Crouching
	standing_collision_shape.disabled = true
	crouching_collision_shape.disabled = false
	wiggle_current_intensity = WIGGLE_ON_CROUCHING_INTENSITY


func _on_crouching_state_exited() -> void:
	current_body_posture_state = BodyPostureState.Undefined


func _on_crouching_state_physics_processing(delta: float) -> void:
	head.position.y = lerp(head.position.y, CROUCHING_DEPTH, delta * LERP_SPEED)
	
	if is_head_in_water():
		eyes.position.y = lerp(eyes.position.y, -0.05, delta * LERP_SPEED * 1.5)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.05, delta * LERP_SPEED * 1.5)
	
	swimming_head_shapecast.global_position = head.global_position
	
	if current_moving_state != MovingState.Swimming:
		if TOGGLE_CROUCH and Input.is_action_just_pressed("crouch"):
			try_crouch = !try_crouch
		elif !TOGGLE_CROUCH:
			try_crouch = Input.is_action_pressed("crouch")
		
		if not try_crouch and not crouch_shapecast.is_colliding():
			state_chart.send_event("stand_up")
#endregion


#region Standing State
func _on_standing_state_entered() -> void:
	current_body_posture_state = BodyPostureState.Standing
	sliding_timer.stop()


func _on_standing_state_exited() -> void:
	current_body_posture_state = BodyPostureState.Undefined
	

func _on_standing_state_physics_processing(delta: float) -> void:
	if current_moving_state != MovingState.LedgeClimbing:
		if TOGGLE_CROUCH and Input.is_action_just_pressed("crouch"):
			try_crouch = !try_crouch
		elif !TOGGLE_CROUCH:
			try_crouch = Input.is_action_pressed("crouch")
		
		if try_crouch or crouch_shapecast.is_colliding():
			state_chart.send_event("crouch")
			return
	
	head.position.y = lerp(head.position.y, 0.0, delta * LERP_SPEED)
	
	if is_head_in_water():
		eyes.position.y = lerp(eyes.position.y, -0.05, delta * LERP_SPEED * 1.5)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.05, delta * LERP_SPEED * 1.5)
	
	swimming_head_shapecast.global_position = head.global_position
	
	if head.position.y > CROUCHING_DEPTH/4:
		if is_sitting:
			return
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
#endregion


#region PushingObjects State
func _on_pushing_objects_state_physics_processing(delta: float) -> void:
	# Pushing RigidBody3Ds
	for col_idx in get_slide_collision_count():
		var col := get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse(-col.get_normal() * PLAYER_PUSH_FORCE)
#endregion

#endregion


class StepResult:
	var diff_position: Vector3 = Vector3.ZERO
	var normal: Vector3 = Vector3.ZERO
	var is_step_up: bool = false
