extends Node
class_name CogitoQuickslots

### This script directly references the player inventory a lot, so make sure that reference is set correctly before using.

@export var quickslot_containers : Array[CogitoQuickslotContainer]
# var assigned_quickslots : Array[InventorySlotPD]
@export var inventory_reference : CogitoInventory:
	set(passed_inventory):
		inventory_reference = passed_inventory
		CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Inventory reference (re)set!")
		set_inventory_quickslots(inventory_reference)
		
var inventory_is_open : bool


func _ready() -> void:
	# Connecting to unbind signal to enabling clearing of inventory slot reference on unbind.
	for quickslot in quickslot_containers:
		quickslot.quickslot_cleared.connect(unbind_quickslot)


# Using this to either set up new inventory or load quickslot of existing inventory
func set_inventory_quickslots(passed_inventory: CogitoInventory) -> void:
	if passed_inventory.assigned_quickslots.is_empty():
		CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "set_inventory_quickslots: assigned_quickslots were empty.")
		passed_inventory.assigned_quickslots.resize(quickslot_containers.size())
	else:
		CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "set_inventory_quickslots: assigned_quickslots were NOT empty, updating quickslot data...")
		on_inventory_updated(passed_inventory)


func on_inventory_updated(passed_inv: CogitoInventory) -> void:
	# Updating all quickslot containers using their assigned inventory slots.
	for i in quickslot_containers.size():
		quickslot_containers[i].update_quickslot_data(inventory_reference.assigned_quickslots[i])


func unbind_quickslot(quickslot_to_unbind: CogitoQuickslotContainer) -> void:
	# Finding the passed quickslot in the containers and saving it's index.
	var slot_index : int = quickslot_containers.find(quickslot_to_unbind, 0)
	
	if slot_index != -1:
		# Nulling out the inventory slot of the same index.
		inventory_reference.assigned_quickslots[slot_index] = null
	else:
		CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "quickslot wasn't found in the quickslot_container array.")


func bind_to_quickslot(itemslot_to_bind: InventorySlotPD, quickslot_to_bind: CogitoQuickslotContainer):
	var slot_index : int = quickslot_containers.find(quickslot_to_bind, 0)
	
	if slot_index != -1:
		inventory_reference.assigned_quickslots[slot_index] = itemslot_to_bind
		quickslot_to_bind.update_quickslot_data(itemslot_to_bind)
		CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Assigned quickslot " + str(slot_index) + " to " + itemslot_to_bind.inventory_item.name )
	else:
		CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "quickslot wasn't found in the quickslot_container array.")


func _unhandled_input(event):
	if !self.visible:
		return
		
	if inventory_is_open:
		CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Inventory is open, no item used.")
		return
	
	if event.is_action_released("quickslot_1"):
		if inventory_reference.assigned_quickslots[0]:
			CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Using quickslot 1...")
			inventory_reference.use_slot_data(inventory_reference.assigned_quickslots[0].origin_index)
		else:
			CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Nothing assigned in quickslot 1...")
			return
	
	if event.is_action_released("quickslot_2"):
		if inventory_reference.assigned_quickslots[1]:
			CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Using quickslot 2...")
			inventory_reference.use_slot_data(inventory_reference.assigned_quickslots[1].origin_index)
		else:
			CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Nothing assigned in quickslot 2...")
			return
		
	if event.is_action_released("quickslot_3"):
		if inventory_reference.assigned_quickslots[2]:
			CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Using quickslot 3...")
			inventory_reference.use_slot_data(inventory_reference.assigned_quickslots[2].origin_index)
		else:
			CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Nothing assigned in quickslot 3...")
			return

	if event.is_action_released("quickslot_4"):
		if inventory_reference.assigned_quickslots[3]:
			CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Using quickslot 4...")
			inventory_reference.use_slot_data(inventory_reference.assigned_quickslots[3].origin_index)
		else:
			CogitoGlobals.debug_log(true, "CogitoQuickSlots.gd", "Nothing assigned in quickslot 4...")
			return


func update_inventory_status(is_open: bool):
	inventory_is_open = is_open
	# Sets unhandled key input to the opposite of what is_open is.
	set_process_unhandled_input(!is_open)
