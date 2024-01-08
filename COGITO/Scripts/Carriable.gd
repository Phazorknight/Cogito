extends RigidBody3D
class_name Carriable

@export_group("Carriable Settings")
@export var interaction_text : String = "Carry"
@export var pick_up_sound : AudioStream
@export var drop_sound : AudioStream
@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var camera: Camera3D = get_viewport().get_camera_3d()
const OFFSET = Vector3.UP * -0.25

var is_being_carried: bool = false
var is_dropping: bool = false
var holder: PlayerInteractionComponent = null

func carry(player: PlayerInteractionComponent):
	holder = player

	if is_being_carried:
		leave()
	else:
		hold()

func _process(_delta):
	if is_being_carried:
		# carry the object at the end of a stick where the user is looking.
		global_position = camera.global_position + OFFSET - 2.5 * camera.get_global_transform().basis.z
		global_rotation = holder.global_rotation
#		set_global_transform(holder.carryable_position.get_global_transform())

func hold():
	self.disable_collisions()
	self.gravity_scale = 0.25
	holder.carried_object = self
	
	# Play Pick up sound.
	if pick_up_sound != null:
		audio_stream_player_3d.stream = pick_up_sound
		audio_stream_player_3d.play()
	
	self.set_sleeping(true)
	#self.set_freeze_enabled(true)
	is_being_carried = true

func leave():
	is_being_carried = false
	self.enable_collisions()
	holder.carried_object = null
	self.set_sleeping(false)
	#self.set_freeze_enabled(false)

func disable_collisions():
	$CollisionShape3D.set_disabled(true)

func enable_collisions():
	$CollisionShape3D.set_disabled(false)	

func _on_begin_dropping():
	print("dropping begins")
	self.is_dropping = true
	self.continuous_cd = true
	self.contact_monitor = true
	self.max_contacts_reported = 1

# while object is being dropped, monitor collisions.
func _integrate_forces(state: PhysicsDirectBodyState3D):
	if is_dropping:
		var count = state.get_contact_count()
		if count > 0:
			_on_end_dropping()

func _on_end_dropping():
	print("dropping ends")
	self.is_dropping = false
	self.gravity_scale = 1.0
	self.continuous_cd = false
	self.contact_monitor = false
	self.max_contacts_reported = 0

func drop():
	_on_begin_dropping()
	leave()
	if drop_sound != null:
		audio_stream_player_3d.stream = drop_sound
		audio_stream_player_3d.play()

func throw(power):
	leave()
	if drop_sound != null:
		audio_stream_player_3d.stream = drop_sound
		audio_stream_player_3d.play()
	apply_central_impulse(holder.look_vector * Vector3(power, power, power))
