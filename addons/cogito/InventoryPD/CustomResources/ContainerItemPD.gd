extends WieldableItemPD
class_name ContainerItemPD

# Signal that gets sent when the wiedlable charge changes. Currently used to update Slot UI
signal contents_changed(index: int)

@export_group("Container Item settings")
## Current index of content type. This defines the type of content, index will match which consumable effect will be applied. 0 == empty.
@export var current_content_index : int = 0
## Array of consumable effects, only the effect at the same index of the content will be applied.
@export var consumable_effects : Array[ConsumableEffect]



func use(target) -> bool:
	if target.is_in_group("external_inventory"):
		CogitoGlobals.debug_log(true,"WieldableItemPD.gd", "Can't use wieldable that is not in your inventory." )
		return false
		
	# Target should always be player? Null check to override using the CogitoSceneManager, which stores a reference to current player node
	if target == null:
		CogitoGlobals.debug_log(true,"WieldableItemPD.gd", "Bad target pass. Setting target to " + CogitoSceneManager._current_player_node.name )
		target = CogitoSceneManager._current_player_node

		
	player_interaction_component = target.player_interaction_component
	if player_interaction_component.carried_object != null:
		player_interaction_component.send_hint(null,"Can't equip item while carrying.")
		return false
	if is_being_wielded:
		CogitoGlobals.debug_log(true,"WieldableItemPD.gd", player_interaction_component.name + " is putting away wieldable " + name )
		put_away()
		return true
	else:
		CogitoGlobals.debug_log(true,"WieldableItemPD.gd", player_interaction_component.name + " is taking out wieldable " + name )
		take_out()
		return true


# Functions for WIELDABLES
func take_out():
	if player_interaction_component.is_changing_wieldables:
		return
	
	is_being_wielded = true
	change_content_to(current_content_index)
	update_wieldable_data(player_interaction_component)
	player_interaction_component.change_wieldable_to(self)


func put_away():
	if player_interaction_component.is_changing_wieldables:
		return
	
	is_being_wielded = false
	update_wieldable_data(player_interaction_component)
	player_interaction_component.change_wieldable_to(null)


func update_wieldable_data(_player_interaction_component : PlayerInteractionComponent):
	if _player_interaction_component: #Only update if something get's passed
		if is_being_wielded:
			_player_interaction_component.updated_wieldable_data.emit(self,0,null)
		else:
			_player_interaction_component.updated_wieldable_data.emit(null, 0, null)


func change_content_to(_content_index: int):
	if current_content_index == _content_index:
		player_interaction_component.send_hint(null, "Contents are already index " + str(current_content_index) )
		return
	else:
		current_content_index = _content_index
		player_interaction_component.send_hint(null, "Contents changed to index " + str(current_content_index) )
		contents_changed.emit(current_content_index)


func subtract(amount):
	charge_current -= amount
	if charge_current < 0:
		charge_current = 0
	
	if is_being_wielded:
		update_wieldable_data(player_interaction_component)
	
	charge_changed.emit()

func send_empty_hint():
	if hint_on_empty:
		player_interaction_component.send_hint(null, tr(name) + ": "+ tr(hint_on_empty) )


func add(amount):
	charge_current += amount
	if charge_current > charge_max:
		charge_current = charge_max
	
	if is_being_wielded:
		update_wieldable_data(player_interaction_component)
	charge_changed.emit()


# Function to get the AmmoItemPD
func get_ammo_item(item_name_to_check_for: String) -> InventoryItemPD:
	var ammo_item : InventoryItemPD
	if player_interaction_component.get_parent().inventory_data != null:
		var inventory_to_check = player_interaction_component.get_parent().inventory_data
		for slot in inventory_to_check.inventory_slots:
			if slot != null and slot.inventory_item.name == item_name_to_check_for:
				ammo_item = slot.inventory_item
				
	return ammo_item


# Function to get the amount of ammo in the player inventory
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
		"charge_current" : charge_current,
		"current_content_index" : current_content_index
	}
	return saved_item_data


func build_wieldable_scene():
	var scene = wieldable_scene.instantiate()
	scene.item_reference = self
	return scene
