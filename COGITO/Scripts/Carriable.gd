extends RigidBody3D

@export_group("Carriable Settings")
@export var interaction_text : String = "Carry"
@export var pick_up_sound : AudioStream
@export var drop_sound : AudioStream
@onready var audio_stream_player_3d = $AudioStreamPlayer3D

var is_being_carried
var holder

func carry(player):
	holder = player

	if is_being_carried:
		leave()
	else:
		hold()

func _process(delta):
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
	
	self.set_freeze_enabled(true)
	is_being_carried = true

func leave():
	$CollisionShape3D.set_disabled(false)
	holder.carried_object = null
	self.set_freeze_enabled(false)
	is_being_carried = false


func throw(power):
	leave()
	if drop_sound != null:
		audio_stream_player_3d.stream = drop_sound
		audio_stream_player_3d.play()
	apply_central_impulse(holder.look_vector * Vector3(power, power, power))
