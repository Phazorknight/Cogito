class_name SDPCStateSlide
extends SDPCState

# TODO Implement Slide Physics


@export_group("State Connections")
@export var move_state: SDPCStateMove
@export var bunny_hop_state: SDPCStateBunnyHop
@export var fall_state: SDPCStateFall
@export var crouch_state: SDPCStateCrouch

@export_group("State Properties")
@export_range(0.0, 10.0, 0.1) var slide_duration: float ## in seconds

func enter():
	player.is_sliding = true
	var slide_timer = get_tree().create_timer(slide_duration).timeout.connect(_end_slide)


func exit():
	player.is_sliding = false


func process_physics(delta):
	if !player.is_on_floor():
		return fall_state

	# TODO Implement Slide Physics

func process_input(event):
	if event.is_action_just_pressed(player.JUMP):
		return bunny_hop_state


func _end_slide():
	if player.input_direction:
		return move_state
	else:
		return crouch_state
