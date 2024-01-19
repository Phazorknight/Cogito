extends CharacterBody3D

signal toggle_inventory_interface()
signal player_state_loaded()

## Reference to Pause menu node
@export var pause_menu : NodePath
## Refereence to Player HUD node
@export var player_hud : NodePath

## Damage the player takes if falling from great height. Leave at 0 if you don't want to use this.
@export var fall_damage : int
## Fall velocity at which fall damage is triggered. This is negative y-Axis. -5 is a good starting point but might be a bit too sensitive.
@export var fall_damage_threshold : float = -5

## Flag if Stamina component isused (as this effects movement)
@export var is_using_stamina : bool = true
# Components:
@onready var health_component = $HealthComponent
@onready var sanity_component = $SanityComponent
@onready var brightness_component = $BrightnessComponent
@onready var stamina_component = $StaminaComponent

# Node caching
@onready var player_interaction_component: PlayerInteractionComponent = $PlayerInteractionComponent
@onready var neck: Node3D = $Neck
@onready var head: Node3D = $Neck/Head
@onready var eyes: Node3D = $Neck/Head/Eyes
@onready var camera: Camera3D = $Neck/Head/Eyes/Camera
@onready var animationPlayer: AnimationPlayer = $Neck/Head/Eyes/AnimationPlayer

@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var crouching_collision_shape: CollisionShape3D = $CrouchingCollisionShape
@onready var crouch_raycast: RayCast3D = $CrouchRayCast
@onready var sliding_timer: Timer = $SlidingTimer
@onready var footstep_timer: Timer = $FootstepTimer

## Inventory resource that stores the player inventory.
@export var inventory_data : InventoryPD

# Adding carryable position for item control.
@onready var carryable_position = %CarryablePosition
@onready var footstep_player = $FootstepPlayer

@export_group("Audio")
## AudioStream that gets played when the player jumps.
@export var jump_sound : AudioStream

@export_group("Movement Properties")
@export var JUMP_VELOCITY = 4.5
@export var WALKING_SPEED = 5.0
@export var SPRINTING_SPEED = 8.0
@export var CROUCHING_SPEED = 3.0
@export var CROUCHING_DEPTH = -0.9
@export var MOUSE_SENS = 0.25
@export var LERP_SPEED = 10.0
@export var AIR_LERP_SPEED = 6.0
@export var FREE_LOOK_TILT_AMOUNT = 5.0
@export var SLIDING_SPEED = 5.0
@export var WIGGLE_ON_WALKING_SPEED = 14.0
@export var WIGGLE_ON_SPRINTING_SPEED = 22.0
@export var WIGGLE_ON_CROUCHING_SPEED = 10.0
@export var WIGGLE_ON_WALKING_INTENSITY = 0.1
@export var WIGGLE_ON_SPRINTING_INTENSITY = 0.2
@export var WIGGLE_ON_CROUCHING_INTENSITY = 0.05
@export var BUNNY_HOP_ACCELERATION = 0.1
@export var INVERT_Y_AXIS : bool = true

## STAIR HANDLING STUFF
@export_group("Stair Handling")
var is_step : bool = false
var step_check_height : Vector3 = STEP_HEIGHT_DEFAULT / STEP_CHECK_COUNT
var gravity_vec : Vector3 = Vector3.ZERO
var head_offset : Vector3 = Vector3.ZERO
var snap : Vector3 = Vector3.ZERO
## This sets the camera smoothing when going up/down stairs as the player snaps to each stair step.
@export var step_height_camera_lerp : float = 2.5
## This sets the height of what is still considered a step (instead of a wall/edge)
@export var STEP_HEIGHT_DEFAULT : Vector3 = Vector3(0, 0.5, 0)
## This sets the step slope degree check. When set to 0, tiny edges etc might stop the player in it's tracks. 1 seems to work fine.
@export var STEP_MAX_SLOPE_DEGREE : float = 0.0
const STEP_CHECK_COUNT : int = 2
const WALL_MARGIN : float = 0.001


@export_group("Ladder Handling")
var on_ladder : bool = false
@export var ladder_speed : float = 2.0

@export_group("Gamepad Properties")
@export var JOY_DEADZONE : float = 0.25
@export var JOY_V_SENS : int = 3
@export var JOY_H_SENS : int = 2

var joystick_h_event
var joystick_v_event
 
var initial_carryable_height #DEPRECATED Used to change carryable position based if player is standing or crouching

var config = ConfigFile.new()

var current_speed = 5.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var direction = Vector3.ZERO
var is_walking = false
var is_sprinting = false
var is_crouching = false
var is_free_looking = false
var slide_vector = Vector2.ZERO
var wiggle_vector = Vector2.ZERO
var wiggle_index = 0.0
var wiggle_current_intensity = 0.0
var bunny_hop_speed = SPRINTING_SPEED
var last_velocity = Vector3.ZERO
var stand_after_roll = false
var is_movement_paused = false
var is_dead : bool = false


# Use this to refresh/update when a player state is loaded.
func _on_player_state_loaded():
	health_component.health_changed.emit(health_component.current_health,health_component.max_health)
	stamina_component.stamina_changed.emit(stamina_component.current_stamina,stamina_component.max_stamina)
	sanity_component.sanity_changed.emit(sanity_component.current_sanity,sanity_component.max_sanity)


func _ready():
	#Some Setup steps
	CogitoSceneManager._current_player_node = self
	player_interaction_component.interaction_raycast = $Neck/Head/Eyes/Camera/InteractionRaycast
	
	randomize()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Pause Menu setup
	if pause_menu:
		var pause_menu_node = get_node(pause_menu)
		pause_menu_node.resume.connect(_on_pause_menu_resume) # Hookup resume signal from Pause Menu
		pause_menu_node.close_pause_menu() # Making sure pause menu is closed on player scene load
	else:
		print("Player has no reference to pause menu.")
		
	initial_carryable_height = carryable_position.position.y #DEPRECATED
	
	health_component.death.connect(_on_death) # Hookup HealthComponent signal to detect player death
	brightness_component.brightness_changed.connect(_on_brightness_changed) # Hookup brightness component signal

# Use this function to manipulate player attributes.
func increase_attribute(attribute_name: String, value: float) -> bool:
	match attribute_name:
		"health":
			if health_component.current_health == health_component.max_health:
				return false
			else:
				print("Adding ", value, " to current_health.")
				health_component.add(value)
				return true
		"health_max":
			health_component.max_health += value
			health_component.health_changed.emit(health_component.current_health,health_component.max_health)
			return true
		"sanity":
			if sanity_component.current_sanity == sanity_component.max_sanity:
				return false
			else:
				sanity_component.add(value)
				return true
		"sanity_max":
			sanity_component.max_sanity += value
			sanity_component.sanity_changed.emit(sanity_component.current_sanity,sanity_component.max_sanity)
			return true
		"stamina":
			if stamina_component.current_stamina == stamina_component.max_stamina:
				return false
			else:
				stamina_component.add(value)
				return true
		"stamina_max":
			stamina_component.max_stamina += value
			stamina_component.stamina_changed.emit(stamina_component.current_stamina,stamina_component.max_stamina)
			return true
		_:
			print("Increase attribute failed: no match.")
			return false


func decrease_attribute(attribute_name: String, value: float):
	match attribute_name:
		"health":
			health_component.subtract(value)
		"sanity":
			sanity_component.subtract(value)
		"stamina":
			stamina_component.subtract(value)
		_:
			print("Decrease attribute failed: no match.")


func take_damage(value):
	health_component.subtract(value)


func add_sanity(value):
	sanity_component.add(value)


func _on_death():
	is_dead = true


func _on_brightness_changed(current_brightness,max_brightness):
	print("Brightness changed to ", current_brightness)
	if current_brightness <= 0:
		if sanity_component.is_recovering:
			sanity_component.stop_recovery()
		else:
			sanity_component.start_decay()
	else:
		sanity_component.stop_decay()
		print("Checking if ", (sanity_component.current_sanity/sanity_component.max_sanity), " < ", (current_brightness/max_brightness))
		if (sanity_component.current_sanity/sanity_component.max_sanity) < (current_brightness/max_brightness):
			sanity_component.start_recovery(2.0, (sanity_component.max_sanity/max_brightness) * current_brightness)
			

# Methods to pause input (for Menu or Dialogues etc)
func _on_pause_movement():
	if !is_movement_paused:
		is_movement_paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_resume_movement():
	if is_movement_paused:
		is_movement_paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# reload options user may have changed while paused.
func _reload_options():
	var err = config.load(OptionsConstants.config_file_name)
	if err == 0:
		INVERT_Y_AXIS = config.get_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, true)

# Signal from Pause Menu
func _on_pause_menu_resume():
	_reload_options()
	_on_resume_movement()

# Signal from Inventory
func _on_player_hud_resume():
	_on_resume_movement()


func _input(event):
	if event is InputEventMouseMotion and !is_movement_paused:
		if is_free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
		
		if INVERT_Y_AXIS:
			head.rotate_x(-deg_to_rad(-event.relative.y * MOUSE_SENS))
		else:
			head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	# Checking Analog stick input for mouse look
	if event is InputEventJoypadMotion and !is_movement_paused:
		if event.get_axis() == 2:
			joystick_v_event = event
		if event.get_axis() == 3:
			joystick_h_event = event
	
	# Opens Pause Menu if Menu button is proessed.
	if event.is_action_pressed("menu"):
		if !is_movement_paused and !is_dead:
			_on_pause_movement()
			get_node(pause_menu).open_pause_menu()
	
	# Open/closes Inventory if Inventory button is pressed
	if event.is_action_pressed("inventory") and !is_dead:
		toggle_inventory_interface.emit()


func _process(delta): 
	# If SanityComponent is used, this decreases health when sanity is 0.
	if sanity_component.current_sanity <= 0:
		take_damage(health_component.no_sanity_damage * delta)

# Cache allocation of test motion parameters.
@onready var _params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()

func params(transform3d, motion):
	var params : PhysicsTestMotionParameters3D = _params
	params.from = transform3d
	params.motion = motion
	params.recovery_as_collision = true
	return params

@onready var self_rid: RID = self.get_rid()
@onready var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()

func test_motion(transform3d: Transform3D, motion: Vector3) -> bool:
	return PhysicsServer3D.body_test_motion(self_rid, params(transform3d, motion), test_motion_result)	

### LADDER MOVEMENT
func _process_on_ladder(_delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")

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

	# Applying ladder input_dir to direction
	direction = (transform.basis * Vector3(input_dir.x,input_dir.y * -1,0)).normalized()
	velocity = direction * ladder_speed

	var look_vector = camera.get_camera_transform().basis
	if jump:
		velocity += look_vector * Vector3(JUMP_VELOCITY, JUMP_VELOCITY, JUMP_VELOCITY)
	
	# print("Input_dir:", input_dir, ". direction:", direction)
	move_and_slide()
	
	#Step off ladder when on ground
	if is_on_floor():
		on_ladder = false


func _physics_process(delta):
	if is_movement_paused:
		return
		
	if on_ladder:
		_process_on_ladder(delta)
		return
		
	var is_falling: bool = false	
	
	# Getting input direction
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	
	# LERP the up/down rotation of whatever you're carrying.
	carryable_position.rotation.z = lerp_angle(carryable_position.rotation.z, head.rotation.x, 5 * delta)
	
	# Processing analog stick mouselook
	if joystick_h_event and !is_movement_paused:
			if abs(joystick_h_event.get_axis_value()) > JOY_DEADZONE:
				if INVERT_Y_AXIS:
					head.rotate_x(deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				else:
					head.rotate_x(-deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
				
	if joystick_v_event and !is_movement_paused:
		if abs(joystick_v_event.get_axis_value()) > JOY_DEADZONE:
			neck.rotate_y(deg_to_rad(-joystick_v_event.get_axis_value() * JOY_V_SENS))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
	
	if stand_after_roll:
		head.position.y = lerp(head.position.y, 0.0, delta * LERP_SPEED)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		stand_after_roll = false
	
	if Input.is_action_pressed("crouch") and !is_movement_paused or crouch_raycast.is_colliding():
		if is_on_floor():
			current_speed = lerp(current_speed, CROUCHING_SPEED, delta * LERP_SPEED)
		head.position.y = lerp(head.position.y, CROUCHING_DEPTH, delta * LERP_SPEED)
		carryable_position.position.y = lerp(carryable_position.position.y, initial_carryable_height-.8, delta * LERP_SPEED)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		wiggle_current_intensity = WIGGLE_ON_CROUCHING_INTENSITY
		wiggle_index += WIGGLE_ON_CROUCHING_SPEED * delta
		if is_sprinting and input_dir != Vector2.ZERO and is_on_floor():
			sliding_timer.start()
			slide_vector = input_dir
		elif !Input.is_action_pressed("sprint"):
			sliding_timer.stop()
		is_walking = false
		is_sprinting = false
		is_crouching = true
	else:
		head.position.y = lerp(head.position.y, 0.0, delta * LERP_SPEED)
		carryable_position.position.y = lerp(carryable_position.position.y, initial_carryable_height, delta * LERP_SPEED)
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		sliding_timer.stop()
		# Prevent sprinting if player is out of stamina.
		if Input.is_action_pressed("sprint") and is_using_stamina and stamina_component.current_stamina > 0:
			if !Input.is_action_pressed("jump"):
				bunny_hop_speed = SPRINTING_SPEED
			current_speed = lerp(current_speed, bunny_hop_speed, delta * LERP_SPEED)
			wiggle_current_intensity = WIGGLE_ON_SPRINTING_INTENSITY
			wiggle_index += WIGGLE_ON_SPRINTING_SPEED * delta
			is_walking = false
			is_sprinting = true
			is_crouching = false
		elif Input.is_action_pressed("sprint") and !is_using_stamina:	
			if !Input.is_action_pressed("jump"):
				bunny_hop_speed = SPRINTING_SPEED
			current_speed = lerp(current_speed, bunny_hop_speed, delta * LERP_SPEED)
			wiggle_current_intensity = WIGGLE_ON_SPRINTING_INTENSITY
			wiggle_index += WIGGLE_ON_SPRINTING_SPEED * delta
			is_walking = false
			is_sprinting = true
			is_crouching = false
		else:
			current_speed = lerp(current_speed, WALKING_SPEED, delta * LERP_SPEED)
			wiggle_current_intensity = WIGGLE_ON_WALKING_INTENSITY
			wiggle_index += WIGGLE_ON_WALKING_SPEED * delta
			is_walking = true
			is_sprinting = false
			is_crouching = false
	
	if Input.is_action_pressed("free_look") or !sliding_timer.is_stopped():
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
		rotation.y += neck.rotation.y
		neck.rotation.y = 0
		eyes.rotation.z = lerp(
			eyes.rotation.z,
			0.0,
			delta*LERP_SPEED
		)
	
	
	### STAIR FLOOR SNAP
		#jumping and gravity
	if is_on_floor():
		snap = -get_floor_normal()
		gravity_vec = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		gravity_vec = Vector3.DOWN * gravity * delta
	###
	
	
	if not is_on_floor():
		#snap = Vector3.DOWN
		#velocity.y -= gravity * delta
		pass
	elif sliding_timer.is_stopped() and input_dir != Vector2.ZERO:
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
		snap = -get_floor_normal()
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * LERP_SPEED)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * LERP_SPEED)
		if last_velocity.y <= -7.5:
			head.position.y = lerp(head.position.y, CROUCHING_DEPTH, delta * LERP_SPEED)
			standing_collision_shape.disabled = false
			crouching_collision_shape.disabled = true
			animationPlayer.play("roll")
		elif last_velocity.y <= -5.0:
			animationPlayer.play("landing")
		
		# Taking fall damage
		if fall_damage > 0 and last_velocity.y <= fall_damage_threshold:
			health_component.subtract(fall_damage)
	
	if Input.is_action_pressed("jump") and !is_movement_paused and is_on_floor():
		snap = Vector3.ZERO
		is_falling = true
		# If Stamina Component is used, this checks if there's enough stamina to jump and denies it if not.
		if is_using_stamina and stamina_component.current_stamina >= stamina_component.jump_exhaustion:
			decrease_attribute("stamina",stamina_component.jump_exhaustion)
		else:
			print("Not enough stamina to jump.")
			return
			
		animationPlayer.play("jump")
		Audio.play_sound(jump_sound)
		if !sliding_timer.is_stopped():
			velocity.y = JUMP_VELOCITY * 1.5
			sliding_timer.stop()
		else:
			velocity.y = JUMP_VELOCITY
		if is_sprinting:
			bunny_hop_speed += BUNNY_HOP_ACCELERATION
		else:
			bunny_hop_speed = SPRINTING_SPEED
	
	if sliding_timer.is_stopped():
		if is_on_floor():
			direction = lerp(
				direction,
				(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				delta * LERP_SPEED
			)
		elif input_dir != Vector2.ZERO:
			direction = lerp(
				direction,
				(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				delta * AIR_LERP_SPEED
			)
	else:
		direction = (transform.basis * Vector3(slide_vector.x, 0.0, slide_vector.y)).normalized()
		current_speed = (sliding_timer.time_left / sliding_timer.wait_time + 0.5) * SLIDING_SPEED
	
	current_speed = clamp(current_speed, 3.0, 12.0)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	last_velocity = velocity


	# STAIR HANDLING
	is_step = false
	
	if gravity_vec.y >= 0:
		for i in range(STEP_CHECK_COUNT):			
			var step_height: Vector3 = STEP_HEIGHT_DEFAULT - i * step_check_height
			var transform3d: Transform3D = global_transform
			var motion: Vector3 = step_height
			
			var is_player_collided: bool = test_motion(transform3d, motion)
			
			if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).y < 0:
				continue
			
			if not is_player_collided:
				transform3d.origin += step_height
				motion = velocity * delta
				is_player_collided = test_motion(transform3d, motion)
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					is_player_collided = test_motion(transform3d, motion)
					if is_player_collided:
						if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
							head_offset = -test_motion_result.get_remainder()
							is_step = true
							global_transform.origin += -test_motion_result.get_remainder()
							break
				else:
					var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)

					transform3d.origin += test_motion_result.get_collision_normal(0) * WALL_MARGIN
					motion = (velocity * delta).slide(wall_collision_normal)
					is_player_collided = test_motion(transform3d, motion)
					if not is_player_collided:
						transform3d.origin += motion
						motion = -step_height
						is_player_collided = test_motion(transform3d, motion)
						if is_player_collided:
							if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
								head_offset = -test_motion_result.get_remainder()
								is_step = true
								global_transform.origin += -test_motion_result.get_remainder()
								break
			else:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
				transform3d.origin += test_motion_result.get_collision_normal(0) * WALL_MARGIN
				motion = step_height
				is_player_collided = test_motion(transform3d, motion)
				if not is_player_collided:
					transform3d.origin += step_height
					motion = (velocity * delta).slide(wall_collision_normal)
					is_player_collided = test_motion(transform3d, motion)
					if not is_player_collided:
						transform3d.origin += motion
						motion = -step_height
						is_player_collided = test_motion(transform3d, motion)
						if is_player_collided:
							if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
								head_offset = -test_motion_result.get_remainder()
								is_step = true
								global_transform.origin += -test_motion_result.get_remainder()
								break

	
	
	if not is_step and is_on_floor():
		var step_height: Vector3 = STEP_HEIGHT_DEFAULT
		var transform3d: Transform3D = global_transform
		var motion: Vector3 = velocity * delta
		var is_player_collided: bool = test_motion(transform3d, motion)
		
		if not is_player_collided:
			transform3d.origin += motion
			motion = -step_height
			is_player_collided = test_motion(transform3d, motion)
			if is_player_collided:
				if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
					head_offset = test_motion_result.get_travel()
					is_step = true
					global_transform.origin += test_motion_result.get_travel()
			else:
				is_falling = true
		else:
			if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).y == 0:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
				transform3d.origin += test_motion_result.get_collision_normal(0) * WALL_MARGIN
				motion = (velocity * delta).slide(wall_collision_normal)
				is_player_collided = test_motion(transform3d, motion)
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					is_player_collided = test_motion(transform3d, motion)
					if is_player_collided:
						if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
							head_offset = test_motion_result.get_travel()
							is_step = true
							global_transform.origin += test_motion_result.get_travel()
					else:
						is_falling = true
	
	
	if is_step and !is_falling:
		head.position -= head_offset
		head.position.y = lerp(head.position.y, 0.0, delta * step_height_camera_lerp)
	else:
		head_offset = head_offset.lerp(Vector3.ZERO, delta * LERP_SPEED)
		head.position.y = lerp(head.position.y, 0.0, delta * step_height_camera_lerp)
	
	velocity += gravity_vec

	if is_falling:
		snap = Vector3.ZERO


	if !is_movement_paused:
		move_and_slide()
	
	# FOOTSTEP SOUNDS SYSTEM = CHECK IF ON GROUND AND MOVING
	if is_on_floor() and velocity.length() >= 0.2:
		if footstep_timer.time_left <= 0:
			footstep_player.play()
			# These "magic numbers" determine the frequency of sounds depending on speed of player. Need to make these variables.
			if velocity.length() >= 3.4:
				footstep_timer.start(.3)
			else:
				footstep_timer.start(.6)

func _on_sliding_timer_timeout():
	is_free_looking = false

func _on_animation_player_animation_finished(anim_name):
	stand_after_roll = anim_name == 'roll' and !is_crouching



