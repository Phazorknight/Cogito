extends Resource
class_name CogitoInventory

signal inventory_interact(inventory_data: CogitoInventory, index: int, mouse_button: int)
signal inventory_button_press(inventory_data: CogitoInventory, index: int, action: String)
signal inventory_updated(inventory_data: CogitoInventory)

## Enables grid inventory. If using, make sure player and ALL interactables have this set to true.
@export var grid: bool
## Injects items from this into the inventory slots
@export var starter_inventory : Array[InventorySlotPD]
@export var inventory_size : Vector2i = Vector2i(4,1)
@export var inventory_slots : Array[InventorySlotPD]
@export var first_slot : InventorySlotPD


func _init():
	if inventory_slots.size() > 0:
		first_slot = inventory_slots[0]


# Call this in your initial scene
func apply_initial_inventory():
	inventory_slots.resize(inventory_size.x * inventory_size.y)
	for item in starter_inventory:
		pick_up_slot_data(item)
	if inventory_slots.size() > 0:
		first_slot = inventory_slots[0]


func on_slot_clicked(index: int, mouse_button: int):
	inventory_interact.emit(self, index, mouse_button)


func on_slot_button_pressed(index: int, action: String):
	inventory_button_press.emit(self, index, action)


func null_out_slots(slot_data):
	if not slot_data:
		return
	var size = slot_data.inventory_item.item_size if grid else Vector2i(1,1)
	for x in size.x:
		for y in size.y:
			inventory_slots[slot_data.origin_index + x + (y*inventory_size.x)] = null


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
		null_out_slots(slot_data)
		inventory_updated.emit(self)
		return slot_data
	else:
		return null

func grab_single_slot_data(index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	if slot_data:
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			null_out_slots(slot_data)
		inventory_updated.emit(self)
		return slot_data
	else:
		return null

func use_slot_data(index: int):
	if index == -1: # No item assigned to hotbar
		return
	
	var slot_data = inventory_slots[index]
	
	if not slot_data:
		return

	# THIS USES RESOURCE LOCAL TO SCENE DATA. Local scene in this case is player. If player is persistent, this should work, but might break if not!?
	# This also throws an error when an item is used out of a container.
	var use_successful : bool = slot_data.inventory_item.use(get_local_scene())
	if slot_data.inventory_item.has_method("is_consumable") and use_successful:
		slot_data.quantity -= 1
		if slot_data.quantity < 1:
			null_out_slots(slot_data)
	
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
		null_out_slots(slot_data_to_remove)
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
			null_out_slots(slot_data)
		inventory_updated.emit(self)

func drop_slot_data(grabbed_slot_data: InventorySlotPD, index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	
	var return_slot_data : InventorySlotPD
	if slot_data and slot_data.can_fully_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data)
	elif is_enough_space(grabbed_slot_data, index, false):
		# Swap out item
		var item_to_swap = get_item_to_swap(grabbed_slot_data, index)
		null_out_slots(item_to_swap)
		grabbed_slot_data.origin_index = index
		inventory_slots[index] = grabbed_slot_data
		add_adjacent_slots(index)
		return_slot_data = item_to_swap
	else:
		# do nothing, the grabbed slot remains the same
		return grabbed_slot_data
		
	inventory_updated.emit(self)
	return return_slot_data


func drop_single_slot_data(grabbed_slot_data: InventorySlotPD, index: int) -> InventorySlotPD:
	var slot_data = inventory_slots[index]
	
	if not slot_data and is_enough_space(grabbed_slot_data, index, false):
		inventory_slots[index] = grabbed_slot_data.create_single_slot_data(index)
		add_adjacent_slots(index)
		print("cogito_inventory.gd: drop_single_slot_data(...): grabbed item placed in inventory.")
	elif not slot_data:
		return grabbed_slot_data
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.fully_merge_with(grabbed_slot_data.create_single_slot_data(slot_data.origin_index))
		print("cogito_inventory.gd: drop_single_slot_data(...): grabbed item fully merged with target.")
		#return null
	# Logic for ammo items
	elif slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.has_method("is_ammo_item") and slot_data.inventory_item.ammo_item_name == grabbed_slot_data.inventory_item.name:
		print("cogito_inventory.gd: drop_single_slot_data(...): AmmoItem detected. Attempting to reload target.")
		# Check if there's room for charge
		if slot_data.inventory_item.charge_max - slot_data.inventory_item.charge_current >= grabbed_slot_data.inventory_item.reload_amount:
			get_local_scene().player_interaction_component.send_hint(null,"Charging " + slot_data.inventory_item.name + " by " + str(grabbed_slot_data.inventory_item.reload_amount))
			slot_data.inventory_item.add(grabbed_slot_data.inventory_item.reload_amount)
			grabbed_slot_data.quantity -= 1
		else:
			print("cogito_inventory.gd: drop_single_slot_data(...): AmmoItem detected. Target charge is too high to be reloaded.")
	# Check if grabbed item is a combinable AND check if slot item is the target combine item:
	elif grabbed_slot_data.inventory_item.has_method("is_combinable") and slot_data.inventory_item.name == grabbed_slot_data.inventory_item.target_item_combine :
		# Reduce/destroy both items.
		remove_slot_data(slot_data)
		grabbed_slot_data.quantity -= 1
		# Add resulting item to inventory:
		pick_up_slot_data(grabbed_slot_data.inventory_item.resulting_item)
	
	inventory_updated.emit(self)
	
	if grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null
		
	#if grabbed_slot_data.quantity > 0:
		## Swapping items
		#var item_to_swap = get_item_to_swap(grabbed_slot_data, index)
		#null_out_slots(item_to_swap)
		#return grabbed_slot_data
	#else:
		## Placing items
		#print("cogito_inventory.gd: drop_single_slot_data( grabbed item name=", grabbed_slot_data.inventory_item.name, ", ", index, "): Placing items reached.")
		#return null


func pick_up_slot_data(slot_data: InventorySlotPD) -> bool:
	for index in inventory_slots.size():
		slot_data.origin_index = index
		if inventory_slots[index] and inventory_slots[index].can_fully_merge_with(slot_data):
			slot_data.origin_index = index
			inventory_slots[index].fully_merge_with(slot_data)
			inventory_updated.emit(self)
			return true
	
	for index in inventory_slots.size():
		slot_data.origin_index = index
		if not inventory_slots[index] and is_enough_space(slot_data, index, true):
			inventory_slots[index] = slot_data
			add_adjacent_slots(index)
			inventory_updated.emit(self)
			return true
	
	CogitoSceneManager._current_player_node.player_interaction_component.send_hint(null, "Unable to pick up item.")	
	return false


# Function to attempt to take all the items in a given inventory.
func take_all_items(target_inventory: CogitoInventory):
	for slot in inventory_slots:
		if slot != null:
			#grab item in slot and add it to target inventory
			if target_inventory.pick_up_slot_data(slot.duplicate()):
				print("Grabbed ", slot.inventory_item.name)
				remove_slot_data(slot) #Empty the slot
				force_inventory_update()


func force_inventory_update():
	print("Forced inventory update: ", self)
	inventory_updated.emit(self)


func add_adjacent_slots(index: int):
	if not grid:
		return
	var size = inventory_slots[index].inventory_item.item_size
	for x in size.x:
		for y in size.y:
			inventory_slots[index + x + (y*inventory_size.x)] = inventory_slots[index]


# check if an item either has free slots to occupy or can swap one item out
func is_enough_space(grabbed_slot_data: InventorySlotPD, to_place_index: int, pickup: bool):
	var swap_origin = -1
	var size = grabbed_slot_data.inventory_item.item_size if grid else Vector2i(1,1)
	# check outside of y bounds
	if (to_place_index + (size.x-1) + ((size.y-1)*inventory_size.x)) >= inventory_slots.size():
		return false
	var right_edge: int = to_place_index + size.x-1
	# check row does not shift
	if (int(to_place_index / inventory_size.x) != int(right_edge / inventory_size.x)):
		return false
	for x in size.x:
		for y in size.y:
			var adj_item = inventory_slots[to_place_index + x + (y*inventory_size.x)]
			if not adj_item:
				continue
			elif pickup: # if picking up an item, swap logic should not be invoked
				return false
			elif swap_origin == -1 and adj_item.origin_index != -1:
				swap_origin = adj_item.origin_index	
			elif adj_item.origin_index != swap_origin and adj_item.origin_index != -1:
				return false
	return true


func get_item_to_swap(grabbed_slot_data: InventorySlotPD, to_place_index: int):
	var size = grabbed_slot_data.inventory_item.item_size if grid else Vector2i(1,1)
	for x in size.x:
		for y in size.y:
			var adj_item = inventory_slots[to_place_index + x + (y*inventory_size.x)]
			if not adj_item:
				continue
			if adj_item.origin_index != -1:
				return adj_item
