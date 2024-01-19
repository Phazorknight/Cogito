extends Resource
class_name InventoryPD

signal inventory_interact(inventory_data: InventoryPD, index: int, mouse_button: int)
signal inventory_button_press(inventory_data: InventoryPD, index: int, action: String)
signal inventory_updated(inventory_data: InventoryPD)

@export var inventory_slots : Array[InventorySlotPD]
@export var first_slot : InventorySlotPD

func _init():
	if inventory_slots.size() > 0:
		first_slot = inventory_slots[0]

func on_slot_clicked(index: int, mouse_button: int):
	inventory_interact.emit(self, index, mouse_button)

func on_slot_button_pressed(index: int, action: String):
	print("Pressed ", action, " on slot index ", index)
	inventory_button_press.emit(self, index, action)


# Returns slot data without actually changing the slot
func get_slot_data(index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	if slot_data:
		return slot_data
	else:
		return null


func grab_slot_data(index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	
	if slot_data:
		inventory_slots[index] = null
		inventory_updated.emit(self)
		return slot_data
	else:
		return null


func grab_single_slot_data(index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	if slot_data:
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			inventory_slots[index] = null
		inventory_updated.emit(self)
		return slot_data
	else:
		return null
	


func use_slot_data(index: int):
	var slot_data = inventory_slots[index]
	
	if not slot_data:
		return
	
	print("InventoryPD: Using ", slot_data.inventory_item.name)

	# THIS USES RESOURCE LOCAL TO SCENE DATA. Local scene in this case is player. If player is persistent, this should work, but might break if not!?
	# This also throws an error when an item is used out of a container.
	var use_successful : bool = slot_data.inventory_item.use(get_local_scene())
	if slot_data.inventory_item.item_type == 0 and use_successful:
		print("InventoryPD: Item is consumable, reducing quantity.")
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			inventory_slots[index] = null
	
	inventory_updated.emit(self)
	
	
# Function to remove a specific item from inventory directly (without picking it up etc)
# Used for example by KEY items to be discarded after using them
func remove_slot_data(slot_data_to_remove: InventorySlotPD):
	var index = inventory_slots.find(slot_data_to_remove,0)
	if index == -1:
		print("Couldn't remove item from inventory as it wasn't found.")
		return
	else:
		print("Removing ", slot_data_to_remove, " at index ", index)
		inventory_slots[index] = null
		inventory_updated.emit(self)


func remove_item_from_stack(slot_data: InventorySlotPD):
	var index = inventory_slots.find(slot_data,0)
	if index == -1:
		print("Couldn't remove item from item stack as it wasn't found.")
		return
	else:
		print("Removing ", slot_data, " at index ", index)
		inventory_slots[index].quantity -= 1
		if inventory_slots[index].quantity <= 0:
			inventory_slots[index] = null
		inventory_updated.emit(self)


func drop_slot_data(grabbed_slot_data: InventorySlotPD, index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	
	var return_slot_data : InventorySlotPD
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	else:
		inventory_slots[index] = grabbed_slot_data
		return_slot_data = slot_data
		
	inventory_updated.emit(self)
	return return_slot_data


func drop_single_slot_data(grabbed_slot_data: InventorySlotPD, index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	
	if not slot_data:
		inventory_slots[index] = grabbed_slot_data.create_single_slot_data()
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data.create_single_slot_data())
	# Logic for ammo items
	elif slot_data.inventory_item == grabbed_slot_data.inventory_item.target_item_ammo:
		print("Attempt to reload!")
		# Check if there's room for charge
		if slot_data.inventory_item.charge_max - slot_data.inventory_item.charge_current >= grabbed_slot_data.inventory_item.reload_amount:
			get_local_scene().player_interaction_component.send_hint(null,"Charging " + slot_data.inventory_item.name + " by " + str(grabbed_slot_data.inventory_item.reload_amount))
			slot_data.inventory_item.add(grabbed_slot_data.inventory_item.reload_amount)
			grabbed_slot_data.quantity -= 1
	# Check if grabbed item is a combinable AND check if slot item is the target combine item:
	elif grabbed_slot_data.inventory_item.item_type == 2 and slot_data.inventory_item.name == grabbed_slot_data.inventory_item.target_item_combine :
		# Reduce/destroy both items.
		remove_slot_data(slot_data)
		grabbed_slot_data.quantity -= 1
		
		# Add resulting item to inventory:
		pick_up_slot_data(grabbed_slot_data.inventory_item.resulting_item)
		
	inventory_updated.emit(self)
	
	if grabbed_slot_data.quantity > 0:
		# Swapping items
		return grabbed_slot_data
	else:
		# Placing items
		return null


func pick_up_slot_data(slot_data: InventorySlotPD) -> bool:
	for index in inventory_slots.size():
		if inventory_slots[index] and inventory_slots[index].can_fully_merge_with(slot_data) :
			inventory_slots[index].fully_merge_with(slot_data)
			inventory_updated.emit(self)
			
			return true
	
	for index in inventory_slots.size():
		if not inventory_slots[index]:
			inventory_slots[index] = slot_data
			inventory_updated.emit(self)
			return true
		
	return false


func force_inventory_update():
	print("Forced inventory update: ", self)
	inventory_updated.emit(self)
