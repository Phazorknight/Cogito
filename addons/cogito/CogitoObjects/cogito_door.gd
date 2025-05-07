@tool
@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoDoor.svg")
class_name CogitoDoor
extends Node3D

signal object_state_updated(interaction_text:String)
signal lock_state_updated(lock_interaction_text:String)
signal door_state_changed(is_open:bool)
signal lock_state_changed(is_locked:bool)
signal damage_received(damage_value:float)

enum DoorType {
  ROTATING,
  SLIDING,
  ANIMATED
}

#region Variables
## Name that will displayed when interacting. Leave blank to hide
@export var display_name : String

@export_group("Audio")
@export var open_sound : AudioStream
@export var close_sound : AudioStream
## Sound that plays when attempting to open while locked.
@export var rattle_sound : AudioStream
@export var unlock_sound : AudioStream
@export var lock_sound : AudioStream

@export_group("Door Settings")
## Start state of the door (usually closed).
@export var is_open : bool = false
## Text that appears on the interaction prompt when locked.
@export var interaction_text_when_locked : String = "Unlock"
## Text that appears on the interaction prompt when locked.
@export var interaction_text_when_unlocked : String = "Lock"
## Text that appears on the interaction prompt when closed.
@export var interaction_text_when_closed : String = "Open"
## Text that appears on the interaction prompt when open.
@export var interaction_text_when_open : String = "Close"
## Use this if you don't want the door mesh to be detected by the interaction raycast. Useful if you have doors that are controlled by other interactables.
@export var ignore_interaction_raycast: bool = false
@export var is_locked : bool = false
## Item resources that is needed to unlock the door.
@export var key : InventoryItemPD
## Hint that is displayed if the player attempts to open the door but doesn't have the key item.
@export var key_hint : String
##Alternate item resource that can unlock this door
@export var lockpick : InventoryItemPD
## Other doors that should sync their state (locked, unlocked, open, closed) with this door. Useful for double-doors, etc.
@export var doors_to_sync_with : Array[NodePath]

## If higher than zero, the door will auto-close after this amount of time has passed.
@export var auto_close_time: float

## Use these if you don't have an animation.
@export_group("Door Parameters")

@export var door_type := DoorType.ROTATING:
	set(value):
		door_type = value
		notify_property_list_changed()

func _validate_property(property: Dictionary):
	if property.name in ["bidirectional_swing", "open_rotation", "closed_rotation", "forced_rotation_axis","angle_tolerance"] and door_type != DoorType.ROTATING:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["open_position", "closed_position"] and door_type != DoorType.SLIDING:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["animation_player", "opening_animation", "reverse_opening_anim_for_close", "closing_animation"] and door_type != DoorType.ANIMATED:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["closing_animation"] and reverse_opening_anim_for_close:
		property.usage = PROPERTY_USAGE_NO_EDITOR


## Set this to true if the door should swing opposite the direction of the interactor
@export var bidirectional_swing : bool = false
## Rotation Y when the door is open. In degrees.
@export var open_rotation : Vector3 = Vector3.ZERO
## Rotation Y when the door is closed. In degrees.
@export var closed_rotation : Vector3 = Vector3.ZERO
## Local position of transform when closed
@export var closed_position : Vector3
## Local position of transform when open
@export var open_position : Vector3
## Force single rotation axis. Use this if your objects rotation seems to tilt.
enum ForcedRotationAxis {
  None,
  AxisX,
  AxisY,
  AxisZ,
}
@export var forced_rotation_axis : ForcedRotationAxis = ForcedRotationAxis.None

## Speed in which the door moves between open and closed position.
@export var door_speed : float = 1
## The stop tolerance if the door rotation reaches the target angle. If your door keeps "oversteering", increase this value.
@export var angle_tolerance : float = 1

# Aimation Parameters
@export var animation_player : NodePath
@export var opening_animation : String
@export var reverse_opening_anim_for_close : bool = true:
	set(value):
		reverse_opening_anim_for_close = value
		notify_property_list_changed()

@export var closing_animation : String

var anim_player : AnimationPlayer
var is_moving : bool = false
var target_rotation_vector : Vector3 = Vector3.ZERO
var interaction_text
var lock_interaction_text
var close_timer : Timer #Used for auto-close

var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null
var player_interaction_component : PlayerInteractionComponent

@onready var audio_stream_player_3d = $AudioStreamPlayer3D

#endregion


func _ready():
	if !ignore_interaction_raycast:
		add_to_group("interactable")
	add_to_group("save_object_state")
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	
	if door_type == DoorType.ANIMATED:
		anim_player = get_node(animation_player)
		
	if is_open:
		interaction_text = interaction_text_when_open
	else:
		interaction_text = interaction_text_when_closed
	
	if is_locked:
		lock_interaction_text = interaction_text_when_locked
	else:
		lock_interaction_text = interaction_text_when_unlocked
		
	object_state_updated.emit(interaction_text)
	lock_state_updated.emit(lock_interaction_text)


func interact(interactor: Node3D):
	player_interaction_component = interactor
	if !is_locked:
		if !is_open:
			open_door(interactor)
			
			for nodepath in doors_to_sync_with:
				if nodepath != null:
					var object = get_node(nodepath)
					object.open_door(interactor)
		else:
			close_door(interactor)
			
			for nodepath in doors_to_sync_with:
				if nodepath != null:
					var object = get_node(nodepath)
					object.close_door(interactor)
	else:
		door_rattle(interactor)


func door_rattle(interactor):
	audio_stream_player_3d.stream = rattle_sound
	audio_stream_player_3d.play()
	interactor.send_hint(null,"I can't open it")


func _physics_process(_delta):
	if door_type == DoorType.ROTATING:
		if is_moving:
			match forced_rotation_axis:
				ForcedRotationAxis.None:
					rotation = rotation.move_toward(target_rotation_vector, _delta * door_speed)
					if vectors_approx_equal(target_rotation_vector, rotation_degrees, angle_tolerance):
						is_moving = false
					
				ForcedRotationAxis.AxisX:
					rotation.x = lerp_angle( deg_to_rad(rotation_degrees.x), deg_to_rad(target_rotation_vector.x), clampf(_delta * door_speed,0.0,1.0) )
					if rotation_degrees.x == target_rotation_vector.x:
						is_moving = false
						
				ForcedRotationAxis.AxisY:
					rotation.y = lerp_angle( deg_to_rad(rotation_degrees.y), deg_to_rad(target_rotation_vector.y), clampf(_delta * door_speed,0.0,1.0) )
					if rotation_degrees.y == target_rotation_vector.y:
						is_moving = false
				ForcedRotationAxis.AxisZ:
					rotation.x = lerp_angle( deg_to_rad(rotation_degrees.z), deg_to_rad(target_rotation_vector.z), clampf(_delta * door_speed,0.0,1.0) )
					if rotation_degrees.z == target_rotation_vector.z:
						is_moving = false


func vectors_approx_equal( v1 : Vector3, v2 : Vector3, epsilon : float ) -> bool:
	var diff = v1 - v2
	return abs( diff.x ) < epsilon and abs( diff.y ) < epsilon and abs( diff.z ) < epsilon


func lock_unlock_switch():
	if is_locked:
		unlock_door()
		
	else: 
		lock_door()
	
	for nodepath in doors_to_sync_with:
		if nodepath != null:
			var object = get_node(nodepath)
			object.lock_unlock_switch()


func unlock_door():
	audio_stream_player_3d.stream = unlock_sound
	audio_stream_player_3d.play()
	is_locked = false
	lock_interaction_text = interaction_text_when_unlocked	
	lock_state_updated.emit(lock_interaction_text)
	lock_state_changed.emit(is_locked)


func lock_door():
	audio_stream_player_3d.stream = lock_sound
	audio_stream_player_3d.play()
	is_locked = true
	lock_interaction_text = interaction_text_when_locked	
	lock_state_updated.emit(lock_interaction_text)
	lock_state_changed.emit(is_locked)


func open_door(interactor: Node3D):
	audio_stream_player_3d.stream = open_sound
	audio_stream_player_3d.play()

	if door_type == DoorType.ANIMATED:
		anim_player.play(opening_animation)
	elif door_type == DoorType.ROTATING:
		target_rotation_vector = open_rotation
		var swing_direction: int = 1

		if bidirectional_swing:
			var offset: Vector3 = interactor.global_transform.origin - global_transform.origin
			var offset_dot_product: float = offset.dot(global_transform.basis.x)
			swing_direction = -1 if offset_dot_product < 0 else 1

		target_rotation_vector = open_rotation * swing_direction
		is_moving = true
	else:
		var tween_door = get_tree().create_tween()
		tween_door.tween_property(self,"position", open_position, door_speed)
	
	is_open = true
	interaction_text = interaction_text_when_open
	object_state_updated.emit(interaction_text)
	door_state_changed.emit(true)
	# Only used if there's an auto close time set.
	if auto_close_time > 0:
		close_timer = Timer.new()
		add_child(close_timer)
		close_timer.wait_time = auto_close_time
		close_timer.one_shot = true
		close_timer.start()
		close_timer.timeout.connect(on_auto_close_time)


func on_auto_close_time():
	close_door(player_interaction_component)


func close_door(_interactor: Node3D):
	if close_timer: #If there's an auto_close_timer, destroy it.
		close_timer.queue_free()
	
	audio_stream_player_3d.stream = close_sound
	audio_stream_player_3d.play()
	
	if door_type == DoorType.ANIMATED:
		if reverse_opening_anim_for_close:
			anim_player.play_backwards(opening_animation)
		else:
			anim_player.play(closing_animation)
	elif door_type == DoorType.ROTATING:
		target_rotation_vector = closed_rotation
		is_moving = true
	else:
		# Sliding door close
		var tween_door = get_tree().create_tween()
		tween_door.tween_property(self,"position", closed_position, door_speed)
	is_open = false
	interaction_text = interaction_text_when_closed
	object_state_updated.emit(interaction_text)
	door_state_changed.emit(false)


func set_state():
	if is_open:
		if auto_close_time > 0:
			set_to_closed_position()
			interaction_text = interaction_text_when_closed
		else:
			set_to_open_position()
			interaction_text = interaction_text_when_open
	else:
		set_to_closed_position()
		interaction_text = interaction_text_when_closed
	if is_locked:
		lock_interaction_text = interaction_text_when_locked
	else:
		lock_interaction_text = interaction_text_when_unlocked
		
	object_state_updated.emit(interaction_text)
	lock_state_updated.emit(lock_interaction_text)


func set_to_open_position():
	if door_type == DoorType.SLIDING:
		position = open_position
	else:
		rotation_degrees = open_rotation


func set_to_closed_position():
	if door_type == DoorType.SLIDING:
		position = closed_position
	else:
		rotation_degrees = closed_rotation

#alternate interaction for locking/unlocking
func interact2(interactor: Node3D):
	if not is_open:
		lock_unlock_switch()
	else:
		interactor.send_hint(null,"Can't lock an open door")

func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"is_locked" : is_locked,
		"is_open" : is_open,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
