extends RigidBody3D

@export_group("Carriable Settings")
@export var interaction_text : String = "Carry"
@export var pick_up_sound : AudioStream
@export var drop_sound : AudioStream
## Use this to adjust the carry position distance from the player. Per default it's the interaction raycast length. Negative values are closer, positive values are further away.
@export var carry_distance_offset : float = 0
## Set if the object should not rotate when being carried. Usually true is preferred.
@export var lock_rotation_when_carried : bool = true
## Sets how fast the carriable is being pulled towards the carrying position. The lower, the "floatier" it will feel.
@export var carrying_velocity_multiplier : float = 10

@onready var audio_stream_player_3d = $AudioStreamPlayer3D

@onready var camera : Camera3D = get_viewport().get_camera_3d()

var is_being_carried
var holder
# Position the carriable "floats to".
var carry_position : Vector3

func _ready():
	self.add_to_group("Persist")

func carry(player_interaction_component):
	holder = player_interaction_component

	if is_being_carried:
		leave()
	else:
		hold()

func _physics_process(_delta):
	if is_being_carried:
		carry_position = holder.get_interaction_raycast_tip(carry_distance_offset)
		set_linear_velocity((carry_position - global_position) * carrying_velocity_multiplier)
		
		

func hold():
	if lock_rotation_when_carried:
		set_lock_rotation_enabled(true)
	holder.carried_object = self
	holder.interaction_raycast.add_exception(self)
	
	# Play Pick up sound.
	if pick_up_sound != null:
		audio_stream_player_3d.stream = pick_up_sound
		audio_stream_player_3d.play()
	
	is_being_carried = true

func leave():
	if lock_rotation_when_carried:
		set_lock_rotation_enabled(false)
	holder.carried_object = null
	holder.interaction_raycast.remove_exception(self)
	
	is_being_carried = false


func throw(power):
	leave()
	if drop_sound:
		audio_stream_player_3d.stream = drop_sound
		audio_stream_player_3d.play()
	apply_central_impulse(holder.look_vector * Vector3(power, power, power))


# Function to handle persistency and saving
func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return save_dict
