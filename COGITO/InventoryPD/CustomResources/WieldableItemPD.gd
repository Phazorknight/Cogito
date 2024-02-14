extends InventoryItemPD
class_name WieldableItemPD

# Signal that gets sent when the wiedlable charge changes. Currently used to update Slot UI
signal charge_changed()

@export_group("Wieldable settings")
## HUD text for primary use (for example: shoot, switch on/off etc.)
@export var primary_use_prompt : String
## HUD text for secondary use (for example: swing, look down sight, etc.)
@export var secondary_use_prompt : String
## Icon that is displayed on the HUD when item is wielded.
@export var wieldable_data_icon : Texture2D

var wieldable_data_text : String

## The maximum charge of the item (this equals fully charged battery in a flashlight or magazine size in guns)
@export var charge_max : float
## Name of the item this item uses as Ammo. Needs to match exactly.
@export var ammo_item_name : String
## Current charge of item (aka how much is in the magazine).
@export var charge_current : float
## Used for weapons
@export var wieldable_range : float
## Used for weapons
@export var wieldable_damage : float


func use(target) -> bool:
	# Target should always be player? Null check to override using the CogitoSceneManager, which stores a reference to current player node
	if target == null or target.is_in_group("external_inventory"):
		print("Bad target pass. Setting target to", CogitoSceneManager._current_player_node)
		target = CogitoSceneManager._current_player_node
		
	player_interaction_component = target.player_interaction_component
	if player_interaction_component.carried_object != null:
		player_interaction_component.send_hint(null,"Can't equip item while carrying.")
		return false
	if is_being_wielded:
		print("Inventory item: ", player_interaction_component, " is putting away wieldable ", name)
		put_away()
		return true
	else:
		print("Inventory item: ", player_interaction_component, " is taking out wieldable ", name)
		take_out()
		return true


# Functions for WIELDABLES
func take_out():
	print("Taking out ", name)
	is_being_wielded = true
	update_wieldable_data(player_interaction_component)
	player_interaction_component.set_use_prompt.emit(primary_use_prompt)
	player_interaction_component.change_wieldable_to(self)


func put_away():
	print("Putting away ", name)
	is_being_wielded = false
	update_wieldable_data(player_interaction_component)
	player_interaction_component.set_use_prompt.emit("")
	player_interaction_component.change_wieldable_to(null)


func update_wieldable_data(_player_interaction_component : PlayerInteractionComponent):
	if _player_interaction_component: #Only update if something get's passed
		if is_being_wielded:
			wieldable_data_text = str(int(charge_current)) + "|" + str(get_item_amount_in_inventory(ammo_item_name))
			_player_interaction_component.updated_wieldable_data.emit(wieldable_data_icon, wieldable_data_text)
		else:
			_player_interaction_component.updated_wieldable_data.emit(null, null)


func subtract(amount):
	charge_current -= amount
	if charge_current < 0:
		charge_current = 0
		player_interaction_component.send_hint(null, name + " is out of battery.")
	
	if is_being_wielded:
		update_wieldable_data(player_interaction_component)
	
	charge_changed.emit()
	

func add(amount):
	charge_current += amount
	if charge_current > charge_max:
		charge_current = charge_max
	
	if is_being_wielded:
		update_wieldable_data(player_interaction_component)
	charge_changed.emit()


func get_item_amount_in_inventory(item_name_to_check_for: String) -> int:
	var item_count : int = 0
	if player_interaction_component.get_parent().inventory_data != null:
		var inventory_to_check = player_interaction_component.get_parent().inventory_data
		for slot in inventory_to_check.inventory_slots:
			if slot != null and slot.inventory_item.name == item_name_to_check_for:
				item_count += slot.quantity
				
	return item_count


func save():
	var saved_item_data = {
		"resource" : self,
		"charge_current" : charge_current
	}
	return saved_item_data
