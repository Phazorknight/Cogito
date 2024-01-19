extends Node3D

@onready var audio_stream_player_3d = $AudioStreamPlayer3D

## Sets if object starts as on or off.
@export var is_on : bool = false
## Toggle if switchable can be interacted with repeatedly or not.
@export var allows_repeated_interaction : bool = true
## Hint that displays after this has been used.
@export var has_been_used_hint : String
@export var interaction_text_when_on : String = "Switch off"
@export var interaction_text_when_off : String = "Switch on"
## Sound that plays when switched.
@export var switch_sound : AudioStream
## Check this if player needs to have an item in the inventory to switch.
@export var needs_item_to_operate : bool
## The item that the player needs to have in their inventory.
@export var required_item : InventoryItemPD
@export var item_hint : String
## Nodes that will become visible when switch is ON. These will hide again when switch is OFF.
@export var nodes_to_show_when_on : Array[Node]
## Nodes that will become hidden when switch is ON. These will show again when switch is OFF.
@export var nodes_to_hide_when_on : Array[Node]

@export var objects_call_interact : Array[NodePath]
@export var objects_call_delay : float = 0.0
var interaction_text : String 
var interactor

func _ready():
	add_to_group("Save_object_state")
	audio_stream_player_3d.stream = switch_sound
	
	if is_on:
		interaction_text = interaction_text_when_on
	else:
		interaction_text = interaction_text_when_off

func interact(interaction_component):
	interactor = interaction_component
	if !allows_repeated_interaction and is_on:
		interactor.send_hint(null, has_been_used_hint)
		return
	if needs_item_to_operate:
		if check_for_item() == true:
			switch()
	else:
		switch()

func switch():
	audio_stream_player_3d.play()
	is_on = !is_on
	
	for nodepath in objects_call_interact:
		await get_tree().create_timer(objects_call_delay).timeout
		if nodepath != null:
			var object = get_node(nodepath)
			object.interact(interactor)
	
	if is_on:
		for node in nodes_to_show_when_on:
			node.show()
		
		for node in nodes_to_hide_when_on:
			node.hide()
			
		interaction_text = interaction_text_when_on
	else:
		for node in nodes_to_show_when_on:
			node.hide()
		
		for node in nodes_to_hide_when_on:
			node.show()
			
		interaction_text = interaction_text_when_off
		
		
func check_for_item() -> bool:
	var inventory = interactor.get_parent().inventory_data
	for slot_data in inventory.inventory_slots:
		if slot_data != null and slot_data.inventory_item == required_item:
			interactor.send_hint(null, required_item.name + " used.") # Sends a hint with the key item name.
			if slot_data.inventory_item.discard_after_use:
				inventory.remove_slot_data(slot_data)
			return true
	
	if item_hint != "":
		interactor.send_hint(null,item_hint) # Sends the key hint with the default hint icon.
	return false
	
	
func set_state():
	if is_on:
		for node in nodes_to_show_when_on:
			node.show()
		
		for node in nodes_to_hide_when_on:
			node.hide()
			
		interaction_text = interaction_text_when_on
	else:
		for node in nodes_to_show_when_on:
			node.hide()
		
		for node in nodes_to_hide_when_on:
			node.show()
			
		interaction_text = interaction_text_when_off
	

func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"is_on" : is_on,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
