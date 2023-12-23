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
## Typed Array of NodePaths. Drag the objects you want switched in here from your scene hierarchy. Their visibility will be flipped when switched. This means you have to set them to the correct starting visibility.
@export var objects_toggle_visibility : Array[NodePath]
@export var objects_call_interact : Array[NodePath]
@export var objects_call_delay : float = 0.0
var interaction_text : String 
var interactor

func _ready():
	audio_stream_player_3d.stream = switch_sound
	
	if is_on:
		interaction_text = interaction_text_when_on
	else:
		interaction_text = interaction_text_when_off

func interact(_player):
	interactor = _player
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
	
	for nodepath in objects_toggle_visibility:
		if nodepath != null:
			var object = get_node(nodepath)
			object.visible = !object.visible
			
	for nodepath in objects_call_interact:
		await get_tree().create_timer(objects_call_delay).timeout
		if nodepath != null:
			var object = get_node(nodepath)
			object.interact(interactor)
	
	if is_on:
		interaction_text = interaction_text_when_on
	else:
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
