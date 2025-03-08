@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoPlayer.svg")
extends CharacterBody3D
class_name CogitoSDPC # state_driven_player_controller_vrood_redux.gd


#region Signals
## Emits when ESC/Menu input map action is pressed. Can be used to exit out other interfaces, etc.
signal menu_pressed(player_interaction_component: PlayerInteractionComponent)
signal toggle_inventory_interface()
signal player_state_loaded()

## Used to hide UI elements like the crosshair when another interface is active (like a container or readable)
signal toggled_interface(is_showing_ui:bool)
signal mouse_movement(relative_mouse_movement:Vector2)

#endregion

#region Components
@export_group("Components")
## Reference to the Pause menu Node
@export var pause_menu : NodePath
## Refereence to Player HUD node
@export var player_hud : NodePath
## Ref to the State Machine
@export var state_machine: SDPCStateMachine

@export var inventory_data: CogitoInventory
#endregion


#region Movement
@export_group("Movement")

@export_subgroup("Standing")
@export_enum("CAN_SPRINT", "WALK_ONLY", "AUTO_SPRINT") var MOVEMENT_TYPE : int
@export_range(1.0, 25.0, 0.01) var WALKING_SPEED : float = 5.0
@export_range(1.0, 25.0, 0.01) var SPRINTING_SPEED : float = 8.0
@export_range(1.0, 25.0, 0.01) var JUMP_VELOCITY: float = 4.5
@export_range(0.01, 50.0, 0.01) var LERP_SPEED: float = 10.0

@export_subgroup("Crouching")
@export var crouching_enabled: bool = true # Turn Crouching On/Off
@export var CAN_CROUCH_JUMP = true # Turn Crouch Jump On/Off
@export var TOGGLE_CROUCH: bool = false # Controlled by game config, if false Hold-To-Crouch is enabled
@export_range(1.0, 25.0, 0.01) var CROUCHING_SPEED : float = 3.0
@export_range(-2.0, 0.0, 0.001) var CROUCHING_DEPTH : float = -0.9
@export_range(1.0, 25.0, 0.01) var CROUCH_JUMP_VELOCITY: float = 3.0

@export_subgroup("Airborne")
@export var multijump_enabled: bool = false
@export var max_jumps: int = 2
@export var fall_damage: int = 0 ## dmg the player takes if falling from great height, leave at 0 if youd on't want to use
@export var fall_damage_threshold: float = -5.0 ## Fall velocity at which fall damage is triggered. This is negative y-Axis. -5 is a good starting point but might be a bit too sensitive.
@export_range(0.01, 50.0, 0.01) var AIR_LERP_SPEED: float = 6.0
var current_jumps: int

@export_group("Advanced Movement")
## How much strength the player has to push RigidBody3D objects.
@export var push_force_enabled: bool = true # Turn Pushing Rigids On/Off
@export_range(0.01, 100.0, 0.01) var PLAYER_PUSH_FORCE : float = 1.3

@export_subgroup("Sliding")
@export var slide_enabled: bool = true # Turn Sliding On/Off
@export var CAN_BUNNYHOP: bool = true
@export_range(1.0, 25.0, 0.01) var SLIDING_SPEED: float = 5.0
@export_range(1.0, 10.0, 0.01) var SLIDE_JUMP_MOD: float = 1.5
@export_range(0.01, 2.0, 0.01) var BUNNY_HOP_ACCELERATION: float = 0.1

@export_subgroup("Stairs")
## This sets the height of what is still considered a step (instead of a wall/edge)
@export var STEP_HEIGHT_DEFAULT : Vector3 = Vector3(0, 0.5, 0)
## This sets the step slope degree check. When set to 0, tiny edges etc might stop the player in it's tracks. 1 seems to work fine.
@export_range(0.01, 1.0, 0.01) var STEP_MAX_SLOPE_DEGREE : float = 0.5
## This sets the camera smoothing when going up/down stairs as the player snaps to each stair step.
@export_range(0.01, 10.0, 0.01) var step_height_camera_lerp : float = 2.5

@export_subgroup("Sitting")
## This allows the player to Subscribe to Sittable Signals
@export var sitting_enabled: bool = true

@export_subgroup("Ladders")
@export var ladder_climbing_enabled: bool = true
@export var CAN_SPRINT_ON_LADDER : bool = false
@export_range(1.0, 25.0, 0.01) var LADDER_SPEED : float = 2.0
@export_range(1.0, 25.0, 0.01) var LADDER_SPRINT_SPEED : float = 3.3
@export_range(0.01, 1.0, 0.01) var LADDER_COOLDOWN : float = 0.5
@export_range(0.25, 0.75, 0.5) var LADDER_JUMP_SCALE : float = 0.5
var ladder_on_cooldown : bool = false


@export_group("Camera Control")
@export var INVERT_Y_AXIS: bool = false
@export_range(1.0, 25.0, 0.01) var FREE_LOOK_TILT_AMOUNT: float = 5.0

@export_subgroup("Mouse")
@export_range(0.01, 20.0, 0.01) var MOUSE_SENS : float = 0.25

@export_subgroup("Gamepad")
@export_range(0.01, 20.0, 0.01) var JOY_DEADZONE : float = 0.25
@export_range(0.01, 20.0, 0.01) var JOY_V_SENS : float = 2
@export_range(0.01, 20.0, 0.01) var JOY_H_SENS : float = 2

@export_subgroup("Headbob")
@export var disable_roll_anim: bool = false
## Head bob strength. Currently controlled/overridden by the in-game options.
@export_enum("Minimal:0.1", "Average:0.7", "Full:1") var HEADBOBBLE : int
@export_range(0, 0.25, 0.01) var WIGGLE_ON_WALKING_INTENSITY : float = 0.03
@export_range(0, 25, 0.01) var WIGGLE_ON_WALKING_SPEED : float = 12.0
@export_range(0, 0.25, 0.01) var WIGGLE_ON_SPRINTING_INTENSITY : float = 0.05
@export_range(0, 25, 0.01) var WIGGLE_ON_SPRINTING_SPEED : float = 16.0
@export_range(0, 0.25, 0.01) var WIGGLE_ON_CROUCHING_INTENSITY : float = 0.08
@export_range(0, 25, 0.01) var WIGGLE_ON_CROUCHING_SPEED : float = 8.0
var WIGGLE_INTENSITY_MODIFIER : float = 1
#endregion


#region Audio
@export_group("Audio")
## AudioStream that gets played when the player jumps.
@export var jump_sound : AudioStream
## AudioStream that gets played when the player slides (sprint + crouch).
@export var slide_sound : AudioStream

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
var slide_audio_player: AudioStreamPlayer3D
var can_play_footstep: bool = true
#endregion

#region Debug
@export_group("Debug")
## Toggle printing debug messages or not. Works with the CogitoSceneManager
@export var is_logging: bool = false
@export var use_local_rng: bool = true

#endregion

#region Onready
# Components
@onready var player_interaction_component: PlayerInteractionComponent = $PlayerInteractionComponent
@onready var wieldables := %Wieldables


# Body/Animations
@onready var body: Node3D = $Body
@onready var neck: Node3D = $Body/Neck
@onready var head: Node3D = $Body/Neck/Head
@onready var eyes: Node3D = $Body/Neck/Head/Eyes
@onready var camera: Camera3D = $Body/Neck/Head/Eyes/Camera
@onready var animationPlayer: AnimationPlayer = $Body/Neck/Head/Eyes/AnimationPlayer

# Collision Checking
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var crouching_collision_shape: CollisionShape3D = $CrouchingCollisionShape
@onready var crouch_raycast: RayCast3D = $CrouchRayCast
@onready var staircheck_ray_cast_3d: RayCast3D = $StaircheckRayCast3D

# Timers
@onready var sliding_timer: Timer = $SlidingTimer
@onready var jump_timer: Timer = $JumpCooldownTimer

# Dynamic Footstep
@onready var footstep_player = $FootstepPlayer
@onready var footstep_surface_detector : FootstepSurfaceDetector = $FootstepPlayer
@onready var footstep_interval_change_velocity_square : float = footstep_interval_change_velocity * footstep_interval_change_velocity


# Sitting
@onready var navigation_agent = $NavigationAgent3D #Navigation agent for Player auto seat exit handling

# Debug
# Cache allocation of test motion parameters.
@onready var _params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
@onready var self_rid: RID = self.get_rid()
@onready var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()

#endregion

#region Systems
var player_currencies: Dictionary

var player_attributes: Dictionary
var stamina_attribute: CogitoAttribute = null
var visibility_attribute: CogitoAttribute

#endregion

#region Player States
# Here lay all "states" the player can exist in
var is_showing_ui: bool = false
var is_movement_paused: bool = false
var is_dead: bool = false
var currently_tweening: bool = false

var is_jumping: bool = false
var is_falling: bool = false
var is_in_air: bool = false
var is_landing: bool = false
var is_standing: bool = true
var is_idle: bool = false

var is_walking: bool = false
var is_sprinting: bool = false
var is_crouching: bool = false

var is_free_looking: bool = false
var on_ladder: bool = false
var is_sitting: bool = false
var is_ejected: bool = false

var jumped_from_slide: bool = false
var was_sprinting: bool = false
var was_in_air: bool = false
var was_on_floor: bool = false
#endregion

#region Variables
# Saving
var config: ConfigFile = ConfigFile.new()

# Gravity
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_vec := Vector3.ZERO # preset for Stair Handling

# Movement
var current_speed: float = 5.0
var main_velocity : Vector3 = Vector3.ZERO
var last_velocity : Vector3= Vector3.ZERO
var direction : Vector3 = Vector3.ZERO
var input_dir : Vector2
var bunny_hop_speed: float = SPRINTING_SPEED
var joystick_h_event
var joystick_v_event
var wiggle_current_intensity: float = 0.0
var wiggle_vector := Vector2.ZERO
var wiggle_index : float = 0.0
var slide_vector := Vector2.ZERO

var try_crouch: bool
var stand_after_roll: bool = false

var initial_carryable_height # DEPRECATED



# Stair Handling
const WALL_MARGIN : float = 0.001
const STEP_DOWN_MARGIN : float = 0.01
const STEP_CHECK_COUNT : int = 2
const SPEED_CLAMP_AFTER_JUMP_COEFFICIENT : float = 0.3
var STEP_HEIGHT_IN_AIR_DEFAULT : Vector3 = STEP_HEIGHT_DEFAULT
var is_enabled_stair_stepping_in_air : bool = true
var step_check_height : Vector3 = STEP_HEIGHT_DEFAULT / STEP_CHECK_COUNT
var head_offset : Vector3 = Vector3.ZERO

class StepResult:
	var diff_position: Vector3 = Vector3.ZERO
	var normal: Vector3 = Vector3.ZERO
	var is_step_up: bool = false

# Sitting
var original_position: Transform3D
var displacement_position: Vector3
var sittable_look_marker: Vector3
var sittable_look_angle: float
var moving_seat: bool = false
var original_neck_basis: Basis = Basis()
#endregion


########################################################################################################################
########################################################################################################################

func _ready() -> void:
	CogitoSceneManager._current_player_node = self
	if use_local_rng:
		randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	setup_attribute_system()
	setup_interaction_component()
	setup_currency_system()
	subscribe_to_sittables()
	call_deferred("slide_audio_init")
	state_machine.initialize(self)


func _process(delta: float) -> void:
	state_machine.process_frames(delta)


func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)
	if !is_movement_paused:
		# Handle Timing based Inputs
		input_dir = Input.get_vector("left", "right", "forward", "back")
		if input_dir:
			print(input_dir)
		crouch_input()
		process_analog_stick_mouselook(delta)
		lerp_head_position(delta)


	if is_sitting:
		_process_on_sittable(delta)
		return
	#if on_ladder:
		#_process_on_ladder(delta)
		#return

	was_on_floor = is_on_floor()
	was_in_air = is_in_air
	was_sprinting = is_sprinting

	if is_on_floor():
		if !ladder_on_cooldown:
			on_ladder = false
		is_jumping = false
		is_in_air = false
		main_velocity.y = 0
		current_jumps = 0
		gravity_vec = Vector3.ZERO


	elif !is_on_floor():
		is_in_air = true
		gravity_vec = Vector3.DOWN * gravity * delta


	# For the most part, the current speed is being handled by the state machine.
	current_speed = clamp(current_speed, 0.5, 12.0)
	if direction and !is_movement_paused and !is_dead:
		main_velocity.x = direction.x * current_speed
		main_velocity.y = direction.y * current_speed
	elif !is_movement_paused and !is_dead:
		main_velocity.x = move_toward(main_velocity.x, 0.0, current_speed)
		main_velocity.z = move_toward(main_velocity.y, 0.0, current_speed)

	apply_external_force()
	handle_stairs(delta)
	main_velocity += gravity_vec
	last_velocity = main_velocity
	velocity = main_velocity
	process_footstep_system(delta)
	move_and_slide()
	push_rigids()


func _input(event: InputEvent) -> void:
	pass
# Currently Unused by any State Machines
func _unhandled_input(event: InputEvent) -> void:
	state_machine.process_handled_inputs(event)

	if !is_movement_paused:
		handle_first_person_camera(event)
	if event.is_action_pressed("menu"):
		handle_menu_controls(event)
	if event.is_action_pressed("inventory"):
		handle_inventory_controls(event)

	state_machine.process_unhandled_inputs(event)



func push_rigids() -> void:
	if !push_force_enabled: return
	for col_idx in get_slide_collision_count():
		var col := get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse(-col.get_normal() * PLAYER_PUSH_FORCE)


func apply_external_force(force_vector: Vector3 = Vector3.ZERO) -> void:
	if force_vector.length() > 0:
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Applying external force " + str(force_vector))
		velocity += force_vector
		move_and_slide()



func process_footstep_system(_delta: float) -> void:
	# FOOTSTEP SOUNDS SYSTEM = CHECK IF ON GROUND AND MOVING
	if is_on_floor() and main_velocity.length() >= 0.2:
		if not sliding_timer.is_stopped():
			if !slide_audio_player.playing:
				slide_audio_player.play()

		else:
			if slide_audio_player:
				slide_audio_player.stop()

			if can_play_footstep && wiggle_vector.y > 0.9:
				#dynamic volume for footsteps
				if is_walking:
					footstep_player.volume_db = walk_volume_db
				elif is_crouching:
					footstep_player.volume_db = crouch_volume_db
				elif is_sprinting:
					footstep_player.volume_db = sprint_volume_db
				footstep_player._play_interaction("footstep")

				can_play_footstep = false

			if !can_play_footstep && wiggle_vector.y < 0.9:
				can_play_footstep = true

	elif slide_audio_player:
		slide_audio_player.stop()


func lerp_head_position(delta: float):
	if is_showing_ui or is_movement_paused: return

	if is_crouching:
			head.position.y = lerp(head.position.y, 0.0, delta * LERP_SPEED)
			#CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "567: Standing up...")
	if is_standing:
		head.position.y = lerp(head.position.y, CROUCHING_DEPTH, delta * LERP_SPEED)
	# While transitioning positons, keep the crouch collision on
	if head.position.y < CROUCHING_DEPTH/4:
		set_crouching_collision()
	else:
		set_standing_collision()


func handle_stairs(delta) -> void:
	var step_result : StepResult = StepResult.new()
	var is_step : bool = step_check(delta, is_jumping, step_result)

	if is_step:
		var is_enabled_stair_stepping: bool = true
		if step_result.is_step_up and is_in_air and not is_enabled_stair_stepping_in_air:
			is_enabled_stair_stepping = false

		if is_enabled_stair_stepping:
			global_transform.origin += step_result.diff_position
			head_offset = step_result.diff_position
			head.position -= head_offset
			head.position.y = lerp(head.position.y, 0.0, delta * step_height_camera_lerp)
	else:
		head_offset = head_offset.lerp(Vector3.ZERO, delta * LERP_SPEED)
		head.position.y = lerp(head.position.y, 0.0, delta * step_height_camera_lerp)

	if is_step and step_result.is_step_up and is_enabled_stair_stepping_in_air:
		if is_in_air or direction.dot(step_result.normal) > 0:
			main_velocity *= SPEED_CLAMP_AFTER_JUMP_COEFFICIENT
			gravity_vec *= SPEED_CLAMP_AFTER_JUMP_COEFFICIENT


#region Actions
func crouch_input() -> bool:
	# CROUCH HANDLING dependant on toggle_crouch
	if !is_movement_paused:
		match TOGGLE_CROUCH:
			true:
				if Input.is_action_just_pressed("crouch"):
					try_crouch = !try_crouch
			false:
				try_crouch = Input.is_action_pressed("crouch")
	return try_crouch





#region Menu Controls
func handle_menu_controls(event):

	# Opens Pause Menu if Menu button is pressed.
		if is_showing_ui: #Behaviour when pressing ESC/menu while external UI is open (Readables, Keypad, etc)
			menu_pressed.emit(player_interaction_component)
			if get_node(player_hud).inventory_interface.is_inventory_open: #Behaviour when pressing ESC/menu while Inventory is open
				toggle_inventory_interface.emit()

		elif !is_movement_paused and !is_dead:
			if !currently_tweening:
				_on_pause_movement()
				get_node(pause_menu).open_pause_menu()

			# This line is to prevent interacting when transitioning from sitting to standing
			else:
				player_interaction_component.send_hint(null, "Wait until I’m seated or standing")


func handle_inventory_controls(event):
	# Open/closes Inventory if Inventory button is pressed
	if !is_dead:
		if !is_showing_ui: #Making sure now external UI is open.
			toggle_inventory_interface.emit()
		elif is_showing_ui and get_node(player_hud).inventory_interface.is_inventory_open: #Making sure Inventory is open, and if yes, close it.
			toggle_inventory_interface.emit()


#endregion


#region Camera Control
func handle_first_person_camera(event):
	if event is InputEventMouseMotion:
		handle_camera_mouse(event)
	elif event is InputEventJoypadMotion:
		handle_camera_joypad(event)
	else:
		pass

func handle_camera_mouse(event):
	var look_movement := Vector2.ZERO

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


func handle_camera_joypad(event):
	if event.get_axis() == 2:
		joystick_v_event = event
	if event.get_axis() == 3:
		joystick_h_event = event


func process_analog_stick_mouselook(_delta: float) -> void:
	if is_movement_paused: return

	if on_ladder:
		process_analog_stick_mouselook_on_ladder(_delta)

	else:
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

#endregion


#region Attribute System Functions
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
#endregion


#region Collision Functions
func set_crouching_collision():
	standing_collision_shape.disabled = false
	crouching_collision_shape.disabled = true

func set_standing_collision():
	standing_collision_shape.disabled = true
	crouching_collision_shape.disabled = false

func disable_collision():
	standing_collision_shape.disabled = false
	crouching_collision_shape.disabled = false
#endregion


#region Currency Functions
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
#endregion


#region Stair Functions
func step_check(delta: float, is_jumping_: bool, step_result: StepResult):
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

	if not is_jumping_ and not is_step and is_on_floor():
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
#endregion


#region Sitting Functions
func _process_on_sittable(_delta: float) -> void:
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


func toggle_sitting() -> void:
	if is_sitting: _stand_up()
	else: _sit_down()


func _sit_down() -> void:
	disable_collision()
	is_ejected = false
	var sittable = CogitoSceneManager._current_sittable_node
	if sittable:
		is_sitting = true
		set_physics_process(false)
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
	set_physics_process(true)
	var sittable = CogitoSceneManager._current_sittable_node
	disable_collision()
	currently_tweening = false
	state_machine.change_state(state_machine.sit_state)
	if sittable_look_marker:
		var tween = create_tween()
		var target_transform = neck.global_transform.looking_at(sittable_look_marker, Vector3.UP)
		tween.tween_property(neck, "global_transform:basis", target_transform.basis, sittable.rotation_tween_duration)




func _stand_up():
	var sittable = CogitoSceneManager._current_sittable_node
	if sittable:
		is_sitting = false
		set_physics_process(false)
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


func _stand_up_finished():
	is_sitting = false
	set_physics_process(true)
	set_standing_collision()
	self.global_transform.basis = Basis()
	neck.global_transform.basis = original_neck_basis
	currently_tweening = false
	state_machine.change_state(state_machine.initial_state)

## Handles Various Methods of Standing Up
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
			print("No leave node found. Returning to Original position")
			_move_to_original_position(sittable)


#Find location using navmesh to place player
func _move_to_nearby_location(sittable):
	print("Attempting to find available locations to move player to")
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
	print("No available location found after ",attempts, " tries. Testing for leave node.")
	_move_to_leave_node(sittable)


func _move_to_displacement_position(sittable):
	var tween = create_tween()
	var new_position = sittable.global_transform.origin - displacement_position
	var new_transform = self.global_transform
	new_transform.origin = new_position
	tween.tween_property(self, "global_transform", new_transform, sittable.tween_duration)
	tween.tween_property(neck, "global_transform:basis", original_neck_basis, sittable.rotation_tween_duration)
	tween.tween_callback(Callable(self, "_stand_up_finished"))


func _on_sit_requested(sittable: Node) -> void:
	if is_sitting: return
	_sit_down()

func _on_stand_requested() -> void:
	if is_sitting: _stand_up()

func _on_set_move_requested(sittable: Node) -> void:
	moving_seat = true
	_sit_down()
#endregion



#region Ladder Functions




func process_analog_stick_mouselook_on_ladder(_delta: float) -> void:
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



func enter_ladder(ladder: CollisionShape3D, ladderDir: Vector3) -> void:
	# try and capture player's intent based on where they're looking
	var look_vector = camera.get_camera_transform().basis
	var looking_away = look_vector.z.dot(ladderDir) < 0.33
	var looking_down = look_vector.z.dot(Vector3.UP) > 0.5
	if looking_down or not looking_away:
		var offset = (global_position - ladder.global_position)
		if offset.dot(ladderDir) < -0.1:
			global_translate(ladderDir*offset.length()/4.0)
		var ladder_timer = get_tree().create_timer(LADDER_COOLDOWN)
		ladder_timer.timeout.connect(ladder_buffer_finished)
		ladder_on_cooldown = true
		on_ladder = true
		state_machine.change_state(state_machine.ladder_climb_state)
		return


func ladder_buffer_finished():
	ladder_on_cooldown = false
#endregion


#region Subscribed Functions
# Signal from Pause Menu
func _on_pause_menu_resume() -> void:

	state_machine.change_state(state_machine.initial_state)


func _on_death()-> void:
	state_machine.change_state(state_machine.death_state)

# Methods to pause input (for Menu or Dialogues etc)
func _on_pause_movement()-> void:
	state_machine.change_state(state_machine.paused_state)

# Likely DEPRECATED. Currently being called from state_machine.paused_state in case others are subscribed to this signal -V
func _on_resume_movement()-> void:
	if is_movement_paused:
		is_movement_paused = false



# reload options user may have changed while paused.
func _reload_options()-> void:
	var err = config.load(OptionsConstants.config_file_name)
	if err == 0:
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Options reloaded.")

		HEADBOBBLE = config.get_value(OptionsConstants.section_name, OptionsConstants.head_bobble_key, 1)
		MOUSE_SENS = config.get_value(OptionsConstants.section_name, OptionsConstants.mouse_sens_key, 0.25)
		INVERT_Y_AXIS = config.get_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, true)
		TOGGLE_CROUCH = config.get_value(OptionsConstants.section_name, OptionsConstants.toggle_crouching_key, true)
		JOY_H_SENS = config.get_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, 2)
		JOY_V_SENS = config.get_value(OptionsConstants.section_name, OptionsConstants.gp_looksens_key, 2)

func _on_player_state_loaded()-> void:
	#TODO - reset look on load if needed
	#self.global_transform.basis = Basis()
	#neck.global_transform.basis = Basis()
	pass

func _on_sliding_timer_timeout() -> void:
	is_free_looking = false

func _on_animation_player_animation_finished(anim_name) -> void:
	stand_after_roll = anim_name == "roll" and !is_crouching

#endregion


#region Initialization
func setup_attribute_system() -> void:
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


func setup_interaction_component() -> void:
	player_interaction_component.interaction_raycast = $Body/Neck/Head/Eyes/Camera/InteractionRaycast
	player_interaction_component.exclude_player(get_rid())


func setup_currency_system() -> void:
	### CURRENCY SETUP
	for currency in find_children("", "CogitoCurrency", false):
		player_currencies[currency.currency_name] = currency
		CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Cogito Currency found: " + currency.currency_name)


func setup_pause_menu() -> void:
	# Pause Menu setup
	if pause_menu:
		var pause_menu_node = get_node(pause_menu)
		pause_menu_node.resume.connect(_on_pause_menu_resume) # Hookup resume signal from Pause Menu
		pause_menu_node.close_pause_menu() # Making sure pause menu is closed on player scene load
	else:
		printerr("Player has no reference to pause menu.")


func subscribe_to_sittables() -> void:
	if !sitting_enabled: return
	# Sittable Signals setup
	CogitoSceneManager.connect("sit_requested", Callable(self, "_on_sit_requested"))
	CogitoSceneManager.connect("stand_requested", Callable(self, "_on_stand_requested"))
	CogitoSceneManager.connect("seat_move_requested", Callable(self, "_on_seat_move_requested"))
	# Debug
	CogitoGlobals.debug_log(is_logging, "cogito_player.gd", "Player has no reference to pause menu.")


func slide_audio_init():
	#setup sound effect for sliding
	slide_audio_player = Audio.play_sound_3d(slide_sound, false)
	slide_audio_player.reparent(self, false)

#endregion


#region Debug Functions
func test_motion(transform3d: Transform3D, motion: Vector3) -> bool:
	return PhysicsServer3D.body_test_motion(self_rid, get_params(transform3d, motion), test_motion_result)

func get_params(transform3d, motion):
	var params : PhysicsTestMotionParameters3D = _params
	params.from = transform3d
	params.motion = motion
	params.recovery_as_collision = true
	return params
#endregion

func reset_state_flags_to_idle() -> void:
	is_idle = true
	is_standing = true

	# Just in case  bug happens elsewhere we reset all the bools
	is_showing_ui = false
	is_movement_paused = false
	on_ladder = false
	is_free_looking = false
	is_in_air = false
	is_jumping = false
	is_falling = false
	is_landing = false
	is_walking = false
	is_sprinting = false
	is_crouching = false
