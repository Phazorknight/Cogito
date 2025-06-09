@tool
extends Node3D
class_name CogitoSnapSlot

signal object_placed
signal object_removed
signal object_state_updated(interaction_text:String)

@onready var snap_area_3d: Area3D = $SnapArea3D
@onready var snap_shape: Node3D = $SnapShape
@onready var snap_position: Node3D = $SnapPosition

## PackedScene of the carryable object that this snapslot is expecting.
@export var expected_object : PackedScene


@export_group("Audio")
## Plays when object is snapped into place.
@export var object_placement_sound : AudioStream
## Plays when object is removed from the slot.
@export var object_removed_sound : AudioStream
## Audio that is played continuiosly while object is placed.
@export var active_sound_loop : AudioStream

@export_group("Interaction Settings")
## Is active or not. You might want to only activate this slot when another condition is met. Also used to deactivate after object is placed.
@export var is_active : bool = true
## Text that appears on the interaction prompt when an inventory item is expected.
@export var interaction_text_to_place : String = "Place"
## Text that appears on the interaction prompt when an object is placed that can be removed.
@export var interaction_text_to_remove : String = "Remove"
## Hint that is displayed if the player interacts while the snapslot is empty.
@export var expected_object_hint : String = "Looks like an object could fit here."
## Delay in seconds after slotting or removing an object. This is there to prevent immediate re-slotting of an object that can be removed.
@export var setter_delay : float = 0.8

var instanced_expected_object
var preloaded_expected_item
var spawned_object = null
var interaction_text = null
var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null
var player_interaction_component : PlayerInteractionComponent


var is_holding_object : bool:
	set(value):
		is_holding_object = value
		
		if snap_shape:
			snap_shape.visible = !is_holding_object
		
		if is_holding_object:
			object_placed.emit()
			interaction_text = interaction_text_to_remove
			
			await get_tree().create_timer(setter_delay).timeout
			
			# Connect to body_exited signal, disconnect the body_entered signal.
			if !snap_area_3d.body_exited.is_connected(_on_body_exited_snap_area):
				snap_area_3d.body_exited.connect(_on_body_exited_snap_area)
			if snap_area_3d.body_entered.is_connected(_on_body_entered_snap_area):
				snap_area_3d.body_entered.disconnect(_on_body_entered_snap_area)
			
		else:
			object_removed.emit()
			interaction_text = interaction_text_to_place
			
			await get_tree().create_timer(setter_delay).timeout
			
			# Connect to body_entered signal, disconnect the body_exited signal.
			if snap_area_3d.body_exited.is_connected(_on_body_exited_snap_area):
				snap_area_3d.body_exited.disconnect(_on_body_exited_snap_area)
			if !snap_area_3d.body_entered.is_connected(_on_body_entered_snap_area):
				snap_area_3d.body_entered.connect(_on_body_entered_snap_area)
		
		object_state_updated.emit(interaction_text)



func _ready() -> void:
	set_state()
	
	if expected_object:
		instanced_expected_object = load(expected_object.resource_path).instantiate()
		CogitoGlobals.debug_log(true,"cogito_snap_slot.gd", "expected object cogito_name=" + instanced_expected_object.cogito_name)


func interact(interactor: Node3D):
	player_interaction_component = interactor
	


func place_item():
	#TODO PLACE ITEM LOGIC GOES HERE
	Audio.play_sound_3d(object_placement_sound).global_position = self.global_position
	spawned_object = preloaded_expected_item.instantiate()
	
	is_holding_object = true
	
	get_tree().current_scene.add_child(spawned_object)
	if spawned_object.is_class("RigidBody3D"):
		spawned_object.set_freeze_mode(0)
		spawned_object.freeze = true
	spawned_object.global_transform = snap_position.global_transform
	spawned_object.object_exits_tree.connect(remove_object)


func place_carryable(world_carryable: Node3D):
	if !world_carryable:
		return
	if !world_carryable.is_class("RigidBody3D"):
		CogitoGlobals.debug_log(true,"cogito_snap_slot.gd", "place_carryable(): body wasn't a RigidBody3D.")
		return
		
	Audio.play_sound_3d(object_placement_sound).global_position = self.global_position
	if player_interaction_component and player_interaction_component.carried_object:
		player_interaction_component.carried_object.leave()
	is_holding_object = true
	world_carryable.set_freeze_mode(0)
	world_carryable.freeze = true
	world_carryable.global_transform = snap_position.global_transform


func remove_object():
	Audio.play_sound_3d(object_removed_sound).global_position = self.global_position
	is_holding_object = false
	if spawned_object:
		spawned_object = null


func _on_body_entered_snap_area(body : Node3D):
	if !expected_object:
		return
	
	if !player_interaction_component:
		player_interaction_component = CogitoSceneManager._current_player_node.player_interaction_component
	
	if body is CogitoObject:
		CogitoGlobals.debug_log(true,"cogito_snap_slot.gd", "body is CogitoObject with cogito_name=" + body.cogito_name)
		if instanced_expected_object.cogito_name == body.cogito_name:
			CogitoGlobals.debug_log(true,"cogito_snap_slot.gd", "Expected object detected: " + body.cogito_name)
			place_carryable(body)
	pass


func _on_body_exited_snap_area(body: Node3D):
	if !expected_object:
		return
	if body is CogitoObject and instanced_expected_object.cogito_name == body.cogito_name:
		remove_object()


func set_state():
	add_to_group("interactable")
	add_to_group("save_object_state")
	
	if is_holding_object:
		if !snap_area_3d.body_exited.is_connected(_on_body_exited_snap_area):
			snap_area_3d.body_exited.connect(_on_body_exited_snap_area)
	else:
		if !snap_area_3d.body_entered.is_connected(_on_body_entered_snap_area):
			snap_area_3d.body_entered.connect(_on_body_entered_snap_area)

	
	interaction_text = interaction_text_to_place
	object_state_updated.emit(interaction_text)
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components


func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"is_active" : is_active,
		"is_holding_object" : is_holding_object,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
