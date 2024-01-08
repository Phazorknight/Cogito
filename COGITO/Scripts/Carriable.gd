extends RigidBody3D

@export_group("Carriable Settings")
@export var interaction_text : String = "Carry"
@export var pick_up_sound : AudioStream
@export var drop_sound : AudioStream
@onready var audio_stream_player_3d = $AudioStreamPlayer3D

var is_being_carried
var holder

func _ready():
	self.add_to_group("Persist")

func carry(player):
	holder = player

	if is_being_carried:
		leave()
	else:
		hold()

func _process(_delta):
	if is_being_carried:
		global_position = holder.carryable_position.global_position
		global_rotation = holder.carryable_position.global_rotation
#		set_global_transform(holder.carryable_position.get_global_transform())

func hold():
	$CollisionShape3D.set_disabled(true)
	holder.carried_object = self
	
	# Play Pick up sound.
	if pick_up_sound != null:
		audio_stream_player_3d.stream = pick_up_sound
		audio_stream_player_3d.play()
	
	self.set_sleeping(true)
	#self.set_freeze_enabled(true)
	is_being_carried = true

func leave():
	$CollisionShape3D.set_disabled(false)
	holder.carried_object = null
	self.set_sleeping(false)
	#self.set_freeze_enabled(false)
	is_being_carried = false


func throw(power):
	leave()
	if drop_sound != null:
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
