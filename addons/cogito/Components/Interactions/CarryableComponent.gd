extends InteractionComponent
class_name CogitoCarryableComponent

signal carry_state_changed(is_being_carried : bool)
signal thrown(impulse)

@export_group("Carriable Settings")
@export var pick_up_sound : AudioStream
@export var drop_sound : AudioStream
##Sets whether the object can be carried while wielding a weapon
@export var is_carryable_while_wielding : bool = false
## Use this to adjust the carry position distance from the player. Per default it's the interaction raycast length. Negative values are closer, positive values are further away.
@export var carry_distance_offset : float = 0
## Set if the object should not rotate when being carried. Usually true is preferred.
@export var lock_rotation_when_carried : bool = true
## Sets how fast the carriable is being pulled towards the carrying position. The lower, the "floatier" it will feel.
@export var carrying_velocity_multiplier : float = 10
## Sets how far away the carried object needs to be from the carry_position before it gets dropped.
@export var drop_distance : float = 1.5
## Sets if object can be rotated while being carried
@export var enable_manual_rotating : bool = true
## How fast the object rotates (in degrees per second)
@export var rotation_speed : float = 2.0

@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var camera : Camera3D = get_viewport().get_camera_3d()

var parent_object
var is_being_carried : bool
var is_being_rotated : bool = false
var player_interaction_component : PlayerInteractionComponent
var carry_position : Vector3 #Position the carriable "floats towards".


func _ready():
	parent_object = get_parent()
	if parent_object.has_signal("body_entered"):
		parent_object.body_entered.connect(_on_body_entered) #Connecting to body entered signal
	else:
		CogitoGlobals.debug_log(true,"CarryableComponent.gd", parent_object.name + ": CarriableComponent needs to be child to a RigidBody3D to work.")


func interact(_player_interaction_component:PlayerInteractionComponent):
	if !is_disabled:
		if attribute_check == AttributeCheck.NONE:
			carry(_player_interaction_component)
			was_interacted_with.emit(interaction_text,input_map_action)
		else:
			if check_attribute(_player_interaction_component):
				carry(_player_interaction_component)
				was_interacted_with.emit(interaction_text,input_map_action)


func carry(_player_interaction_component:PlayerInteractionComponent):
	player_interaction_component = _player_interaction_component
	if player_interaction_component.is_wielding and not is_carryable_while_wielding:
		player_interaction_component.send_hint(null,"Can't carry an object while wielding.")
		return

	if is_being_carried:
		leave()
	else:
		hold()


func _physics_process(_delta):
	if is_being_carried:
		#carry_position = player_interaction_component.get_interaction_raycast_tip(carry_distance_offset)
		carry_position = player_interaction_component.get_carryable_destination_point(carry_distance_offset)
		parent_object.set_linear_velocity((carry_position - parent_object.global_position) * carrying_velocity_multiplier)
		
		if enable_manual_rotating:
			if enable_manual_rotating and Input.is_action_pressed("action_secondary"):
				player_interaction_component.player.is_movement_paused = true
				is_being_rotated = true
				rotate_object(_delta)
		
		# Resume player movement when input action is released
		if is_being_rotated and Input.is_action_just_released("action_secondary"):
			player_interaction_component.player.is_movement_paused = false
		
		if(carry_position-parent_object.global_position).length() >= drop_distance:
			leave()


func rotate_object(_delta):
	var input_dir
	input_dir = Input.get_vector("left", "right", "forward", "back")
	
	if input_dir.length() > 0:
		var rotation_vector: Vector3 = Vector3(input_dir.y, input_dir.x, 0)
		parent_object.global_rotate(rotation_vector, deg_to_rad(rotation_speed) )


func _on_body_entered(body):
	if body.is_in_group("Player") and is_being_carried:
		leave()


func _exit_tree():
	if is_being_carried:
		leave()


func hold():
	if lock_rotation_when_carried:
		parent_object.set_lock_rotation_enabled(true)
	parent_object.freeze = false
	player_interaction_component.start_carrying(self)
	player_interaction_component.interaction_raycast.add_exception(parent_object)
	
	# Play Pick up sound.
	if pick_up_sound != null:
		audio_stream_player_3d.stream = pick_up_sound
		audio_stream_player_3d.play()
	
	is_being_carried = true
	carry_state_changed.emit(is_being_carried)


func leave():
	# Making sure the player movement resumes when object is dropped while being rotated
	if is_being_rotated:
		player_interaction_component.player.is_movement_paused = false
		
	if lock_rotation_when_carried:
		parent_object.set_lock_rotation_enabled(false)
	if player_interaction_component and is_instance_valid(player_interaction_component):
		player_interaction_component.stop_carrying()
		player_interaction_component.interaction_raycast.remove_exception(parent_object)
	is_being_carried = false
	carry_state_changed.emit(is_being_carried)


func throw(power):
	leave()
	if drop_sound:
		audio_stream_player_3d.stream = drop_sound
		audio_stream_player_3d.play()
	var impulse = player_interaction_component.Get_Look_Direction() * power
	parent_object.apply_central_impulse(impulse)
	thrown.emit(impulse)
