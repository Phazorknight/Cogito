extends CharacterBody3D

## Reference to Pause menu node
@export var pause_menu : NodePath
## Refereence to Player HUD node
@export var player_hud : NodePath
## Flag if Stamina component isused (as this effects movement)
@export var is_using_stamina : bool = true
# Components:
@onready var health_component = $HealthComponent
@onready var sanity_component = $SanityComponent
@onready var brightness_component = $BrightnessComponent
@onready var stamina_component = $StaminaComponent

@onready var player_interaction_component = $PlayerInteractionComponent

@export var inventory_data : InventoryPD
@onready var drop_position = $DropPosition
signal toggle_inventory_interface()


# Adding carryable position for item control.
@onready var carryable_position = %CarryablePosition
@onready var footstep_player = $FootstepPlayer

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

@export_group("Gamepad Properties")
@export var JOY_DEADZONE : float = 0.25
@export var JOY_V_SENS : int = 3
@export var JOY_H_SENS : int = 2

var joystick_h_event
var joystick_v_event

# Used to change carryable position based if player is standing or crouching
var initial_carryable_height

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


func _ready():
	randomize()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	config = load(OptionsConstants.config_file_name)
	if config != null:
		INVERT_Y_AXIS = config.get_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, true)
	
	if pause_menu:
		get_node(pause_menu).close_pause_menu()
	else:
		print("Player has no reference to pause menu.")
		
	initial_carryable_height = carryable_position.position.y
	
	# Hookup brightness component signal
	brightness_component.brightness_changed.connect(_on_brightness_changed)


func increase_attribute(attribute_name: String, value: float):
	match attribute_name:
		"health":
			health_component.add(value)
		"health_max":
			health_component.max_health += value
		"sanity":
			sanity_component.add(value)
		"sanity_max":
			sanity_component.max_sanity += value
		"stamina":
			stamina_component.add(value)
		"stamina_max":
			stamina_component.max_stamina += value
		_:
			print("Increase attribute failed: no match.")


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


# Signal from Pause Menu
func _on_pause_menu_resume():
	_on_resume_movement()

# Signal from Inventory
func _on_player_hud_resume():
	_on_resume_movement()


func _input(event):
	if event is InputEventMouseMotion and !is_movement_paused:
		if is_free_looking:
			$Neck.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
			$Neck.rotation.y = clamp($Neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
		
		if INVERT_Y_AXIS:
			$Neck/Head.rotate_x(-deg_to_rad(-event.relative.y * MOUSE_SENS))
		else:
			$Neck/Head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
		$Neck/Head.rotation.x = clamp($Neck/Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
	# Checking Analog stick input for mouse look
	if event is InputEventJoypadMotion and !is_movement_paused:
		if event.get_axis() == 2:
			joystick_v_event = event
		if event.get_axis() == 3:
			joystick_h_event = event
	
	# Opens Pause Menu if Menu button is proessed.
	if event.is_action_pressed("menu"):
		if !is_movement_paused:
			_on_pause_movement()
			get_node(pause_menu).open_pause_menu()
	
	# Open/closes Inventory if Inventory button is pressed
	if event.is_action_pressed("inventory"):
		toggle_inventory_interface.emit()


func _process(delta): 
	# If SanityComponent is used, this decreases health when sanity is 0.
	if sanity_component.current_sanity <= 0:
		take_damage(health_component.no_sanity_damage * delta)


func _physics_process(delta):
	# Getting input direction
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	
	# LERP the up/down rotation of whatever you're carrying.
	carryable_position.rotation.z = lerp_angle(carryable_position.rotation.z, $Neck/Head.rotation.x, 5 * delta)
	
	# Processing analog stick mouselook
	if joystick_v_event and !is_movement_paused:
			if abs(joystick_h_event.get_axis_value()) > JOY_DEADZONE:
				if INVERT_Y_AXIS:
					$Neck/Head.rotate_x(deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				else:
					$Neck/Head.rotate_x(-deg_to_rad(joystick_h_event.get_axis_value() * JOY_H_SENS))
				$Neck/Head.rotation.x = clamp($Neck/Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
				
	if joystick_h_event and !is_movement_paused:
		if abs(joystick_v_event.get_axis_value()) > JOY_DEADZONE:
			$Neck.rotate_y(deg_to_rad(-joystick_v_event.get_axis_value() * JOY_V_SENS))
			$Neck.rotation.y = clamp($Neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
	
	if stand_after_roll:
		$Neck/Head.position.y = lerp($Neck/Head.position.y, 0.0, delta * LERP_SPEED)
		$StandingCollisionShape.disabled = true
		$CrouchingCollisionShape.disabled = false
		stand_after_roll = false
	
	if Input.is_action_pressed("crouch") and !is_movement_paused or $RayCast.is_colliding():
		if is_on_floor():
			current_speed = lerp(current_speed, CROUCHING_SPEED, delta * LERP_SPEED)
		$Neck/Head.position.y = lerp($Neck/Head.position.y, CROUCHING_DEPTH, delta * LERP_SPEED)
		carryable_position.position.y = lerp(carryable_position.position.y, initial_carryable_height-.8, delta * LERP_SPEED)
		$StandingCollisionShape.disabled = true
		$CrouchingCollisionShape.disabled = false
		wiggle_current_intensity = WIGGLE_ON_CROUCHING_INTENSITY
		wiggle_index += WIGGLE_ON_CROUCHING_SPEED * delta
		if is_sprinting and input_dir != Vector2.ZERO and is_on_floor():
			$SlidingTimer.start()
			slide_vector = input_dir
		elif !Input.is_action_pressed("sprint"):
			$SlidingTimer.stop()
		is_walking = false
		is_sprinting = false
		is_crouching = true
	else:
		$Neck/Head.position.y = lerp($Neck/Head.position.y, 0.0, delta * LERP_SPEED)
		carryable_position.position.y = lerp(carryable_position.position.y, initial_carryable_height, delta * LERP_SPEED)
		$StandingCollisionShape.disabled = false
		$CrouchingCollisionShape.disabled = true
		$SlidingTimer.stop()
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
	
	if Input.is_action_pressed("free_look") or !$SlidingTimer.is_stopped():
		is_free_looking = true
		if $SlidingTimer.is_stopped():
			$Neck/Head/Eyes.rotation.z = -deg_to_rad(
				$Neck.rotation.y * FREE_LOOK_TILT_AMOUNT
			)
		else:
			$Neck/Head/Eyes.rotation.z = lerp(
				$Neck/Head/Eyes.rotation.z,
				deg_to_rad(4.0), 
				delta * LERP_SPEED
			)
	else:
		is_free_looking = false
		rotation.y += $Neck.rotation.y
		$Neck.rotation.y = 0
		$Neck/Head/Eyes.rotation.z = lerp(
			$Neck/Head/Eyes.rotation.z,
			0.0,
			delta*LERP_SPEED
		)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif $SlidingTimer.is_stopped() and input_dir != Vector2.ZERO:
		wiggle_vector.y = sin(wiggle_index)
		wiggle_vector.x = sin(wiggle_index / 2) + 0.5
		$Neck/Head/Eyes.position.y = lerp(
			$Neck/Head/Eyes.position.y,
			wiggle_vector.y * (wiggle_current_intensity / 2.0), 
			delta * LERP_SPEED
		)
		$Neck/Head/Eyes.position.x = lerp(
			$Neck/Head/Eyes.position.x,
			wiggle_vector.x * wiggle_current_intensity, 
			delta * LERP_SPEED
		)
	else:
		$Neck/Head/Eyes.position.y = lerp($Neck/Head/Eyes.position.y, 0.0, delta * LERP_SPEED)
		$Neck/Head/Eyes.position.x = lerp($Neck/Head/Eyes.position.x, 0.0, delta * LERP_SPEED)
		if last_velocity.y <= -7.5:
			$Neck/Head.position.y = lerp($Neck/Head.position.y, CROUCHING_DEPTH, delta * LERP_SPEED)
			$StandingCollisionShape.disabled = false
			$CrouchingCollisionShape.disabled = true
			$Neck/Head/Eyes/AnimationPlayer.play("roll")
		elif last_velocity.y <= -5.0:
			$Neck/Head/Eyes/AnimationPlayer.play("landing")
	
	if Input.is_action_pressed("jump") and !is_movement_paused and is_on_floor():
		
		# If Stamina Component is used, this checks if there's enough stamina to jump and denies it if not.
		if is_using_stamina and stamina_component.current_stamina >= stamina_component.jump_exhaustion:
			decrease_attribute("stamina",stamina_component.jump_exhaustion)
		else:
			print("Not enough stamina to jump.")
			return
			
		$Neck/Head/Eyes/AnimationPlayer.play("jump")
		AudioManagerPd.play_audio("jump")
		if !$SlidingTimer.is_stopped():
			velocity.y = JUMP_VELOCITY * 1.5
			$SlidingTimer.stop()
		else:
			velocity.y = JUMP_VELOCITY
		if is_sprinting:
			bunny_hop_speed += BUNNY_HOP_ACCELERATION
		else:
			bunny_hop_speed = SPRINTING_SPEED
	
	if $SlidingTimer.is_stopped():
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
		current_speed = ($SlidingTimer.time_left / $SlidingTimer.wait_time + 0.5) * SLIDING_SPEED
	
	current_speed = clamp(current_speed, 3.0, 12.0)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	last_velocity = velocity

	if !is_movement_paused:
		move_and_slide()
	
	# FOOTSTEP SYSTEM = CHECK IF ON GROUND AND MOVING
	if is_on_floor() and velocity.length() >= 0.2:
		if $FootstepTimer.time_left <= 0:
			# Grab a random number with the range being the ammount of sound effects that can be used.
			var random_index = randi() % footstep_player.footsteps.size()
			footstep_player.play_sfx(random_index)
			if velocity.length() >= 3.2:
				$FootstepTimer.start(.3)
			else:
				$FootstepTimer.start(.6)

func _on_sliding_timer_timeout():
	is_free_looking = false

func _on_animation_player_animation_finished(anim_name):
	stand_after_roll = anim_name == 'roll' and !is_crouching



