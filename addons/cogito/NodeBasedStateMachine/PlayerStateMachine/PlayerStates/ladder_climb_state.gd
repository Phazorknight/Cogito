class_name LadderClimbState
extends CogitoState



# Called when entering this state.
func enter_state(character_controller: CogitoCharacterStateMachine):
	super(character_controller)
	var ladder_timer = get_tree().create_timer(character.LADDER_COOLDOWN)
	ladder_timer.timeout.connect(character.ladder_buffer_finished)
	character.on_ladder = true
	character.ladder_on_cooldown = true

# Called when exiting this state.
func exit_state():
	character.on_ladder = false




func handle_input(_delta):
	# Here lies the artist formally known as '_process_on_ladder'
	var input_dir: Vector2
	if character.is_movement_paused: return
	else:
		input_dir = Input.get_vector("left", "right" , "forward", "back")

	var ladder_speed = character.LADDER_SPEED
	if character.CAN_SPRINT_ON_LADDER and Input.is_action_pressed("sprint") and input_dir.length_squared() > 0.1:
		character.is_sprinting = true
		if character.stamina_attribute.value_current > 0:
			ladder_speed = character.LADDER_SPRINT_SPEED
	else:
		character.is_sprinting = false
		ladder_speed = character.LADDER_SPEED


	# Processing analog stick mouselook
	if character.joystick_h_event:
			if abs(character.joystick_h_event.get_axis_value()) > character.JOY_DEADZONE:
				if character.INVERT_Y_AXIS:
					character.head.rotate_x(deg_to_rad(character.joystick_h_event.get_axis_value() * character.JOY_H_SENS))
				else:
					character.head.rotate_x(-deg_to_rad(character.joystick_h_event.get_axis_value() * character.JOY_H_SENS))
				character.head.rotation.x = clamp(character.head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	if character.joystick_v_event:
		if abs(character.joystick_v_event.get_axis_value()) > character.JOY_DEADZONE:
			character.neck.rotate_y(deg_to_rad(-character.joystick_v_event.get_axis_value() * character.JOY_V_SENS))
			character.neck.rotation.y = clamp(character.neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))

	var look_vector = character.camera.get_camera_transform().basis
	var looking_down = look_vector.z.dot(Vector3.UP) > 0.5

	# Applying ladder input_dir to direction
	var y_dir = 1 if looking_down else -1
	character.direction = (character.body.global_transform.basis * Vector3(input_dir.x,input_dir.y * y_dir,0)).normalized()
	character.main_velocity = character.direction * ladder_speed


	var jump = Input.is_action_pressed("jump")
	var ladder_jump_vector3: = Vector3(character.JUMP_VELOCITY * character.LADDER_JUMP_SCALE,
									character.JUMP_VELOCITY * character.LADDER_JUMP_SCALE,
									character.JUMP_VELOCITY * character.LADDER_JUMP_SCALE)
	if jump:
		character.main_velocity += look_vector * ladder_jump_vector3
		character.change_state("JumpState")

	character.velocity = character.main_velocity

	# NOTE: may be best to just have the character call mas() not the states
	#character.move_and_slide()

	if character.is_on_floor() and not character.ladder_on_cooldown:
		character.change_state("IdleState")
