class_name SDPCStateSprint
extends SDPCState


@export_group("State Connections")
@export var fall_state: SDPCStateFall
@export var jump_state: SDPCStateJump
@export var move_state: SDPCStateMove
@export var slide_state: SDPCStateSlide

var direction : Vector3 = Vector3.ZERO
var input_dir : Vector2 = Vector2.ZERO


func enter() -> void:
	super()
	player.view_bobbing_amount = player.default_view_bobbing_amount
	player.is_sprinting = true

func exit() -> void:
	player.is_sprinting = false


func process_input(event: InputEvent) -> SDPCState:
	if Input.is_action_just_released(player.SPRINT):
		return move_state

	if event.is_action_pressed(player.JUMP) && player.is_on_floor() && player.allow_jump:
		return jump_state

	if player.can_crouch && player.allow_crouch && player.allow_slide:
		if event.is_action_pressed(player.CROUCH) && player.is_on_floor():
			return slide_state

	return null


func process_physics(delta: float) -> SDPCState:
	input_dir = player.input_direction
	direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Disallows Sprinting in reverse
	if input_dir.y > 0 or !player.allow_sprint:
		return move_state

	if player.movement_strength == 0:
		move_speed = player.sprint_speed
	else:
		move_speed = player.sprint_speed * player.movement_strength

	if direction and player.allow_sprint:
		player.velocity.x = direction.x * move_speed
		player.velocity.z = direction.z * move_speed
	else:
		return move_state

	if player.velocity.y < 0:
		state_machine.stored_state = self
		return fall_state

	return null
