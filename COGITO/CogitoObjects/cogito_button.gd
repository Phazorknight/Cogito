@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoButton.svg")
extends Node3D
signal object_state_updated(interaction_text: String) #used to display correct interaction prompts
signal pressed()
signal damage_received(damage_value:float)


@export_group("Cogito Button Settings")
## Sound that plays when pressed.
@export var press_sound : AudioStream
## Default prompt text when button can be pressed
@export var usable_interaction_text : String = "Press"
## Toggle if button can be interacted with repeatedly or not.
@export var allows_repeated_interaction : bool = true
## Forced time until button can be pressed again 
@export var press_cooldown_time : float
## Hint that displays after this has been used.
@export var has_been_used_hint : String
##Hint that displays if player doesn't have enough currency to interact
@export var not_enough_currency_hint : String
## Prompt text when button has been pressed and can't be used repeatedly.
@export var unusable_interaction_text : String = "Unavailable"
## Check this if player needs to have an item in the inventory to switch.
@export var needs_item_to_operate : bool
## The item that the player needs to have in their inventory.
@export var required_item : InventoryItemPD
## Hint that gets displayed if the switch requires an item that the player currently doesn't have.
@export var item_hint : String

##How much it costs to use this button
@export var currency_cost : int  = 0

var currency_text : String
##Text that joins Press & Cost for Interaction 
@export var currency_text_joiner : String = " | Cost: "

## Nodes that will have their interact function called when this switch is used.
@export var objects_call_interact : Array[NodePath]
@export var objects_call_delay : float = 0


var has_been_used : bool = false
var interaction_text : String 
var player_interaction_component : PlayerInteractionComponent
var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null
var cooldown : float

func _ready() -> void:
	self.add_to_group("interactable")
	add_to_group("save_object_state")
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	cooldown = 0 #Enabling button to be pressed right away.
	if currency_cost != 0: 
		currency_text = currency_text_joiner + str(currency_cost)
	interaction_text = usable_interaction_text  + currency_text
	object_state_updated.emit(interaction_text)
	find_cogito_properties()
func find_cogito_properties():
	var property_nodes = find_children("","CogitoProperties",true) #Grabs all attached property components
	if property_nodes:
		cogito_properties = property_nodes[0]

func _physics_process(delta: float) -> void:
	if cooldown > 0:
		cooldown -= delta


func interact(_player_interaction_component:PlayerInteractionComponent):
	if cooldown > 0:
		return
		
	player_interaction_component = _player_interaction_component
	if !check_for_currency():
		player_interaction_component.send_hint(null, not_enough_currency_hint)
		return
	if !allows_repeated_interaction and has_been_used:
		player_interaction_component.send_hint(null, has_been_used_hint)
		return
	if needs_item_to_operate:
		if check_for_item() == true:
			press()
	else:
		press()


func press():
	pressed.emit()
	Audio.play_sound_3d(press_sound).global_position = global_position
	if !allows_repeated_interaction:
		has_been_used = true
		interaction_text = unusable_interaction_text
		object_state_updated.emit(interaction_text)
	else:
		cooldown = press_cooldown_time
	
	if !objects_call_interact:
		return
	for nodepath in objects_call_interact:
		await get_tree().create_timer(objects_call_delay).timeout
		if nodepath != null:
			var object = get_node(nodepath)
			object.interact(player_interaction_component)


func _on_damage_received():
	interact(CogitoSceneManager._current_player_node.player_interaction_component)


func check_for_item() -> bool:
	var inventory = player_interaction_component.get_parent().inventory_data
	for slot_data in inventory.inventory_slots:
		if slot_data != null and slot_data.inventory_item == required_item:
			player_interaction_component.send_hint(null, required_item.name + " used.") # Sends a hint with the key item name.
			if slot_data.inventory_item.discard_after_use:
				inventory.remove_item_from_stack(slot_data)
				# inventory.remove_slot_data(slot_data) (removed on 20240913, leaving line just in case there's bugs.
			return true
	
	if item_hint != "":
		player_interaction_component.send_hint(null,item_hint) # Sends the key hint with the default hint icon.
	return false

func check_for_currency() -> bool:
	var found_currency
	var player = player_interaction_component.get_parent()
	for attribute in player.find_children("", "CogitoCurrency", false):
		if attribute is CogitoCurrency:
			found_currency = attribute
			break
	
	if found_currency.value_current >= currency_cost:
		##Player has enough currency, apply transaction and return true
		found_currency.value_current = found_currency.value_current-currency_cost
		return true 
	else:
		##Player doesn't have enough currency, don't apply transaction and return false
		return false
	

func set_state():
	if has_been_used:
		interaction_text = unusable_interaction_text
	else:
		interaction_text = usable_interaction_text

	object_state_updated.emit(interaction_text)
	

func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"has_been_used" : has_been_used,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
