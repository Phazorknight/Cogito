extends Node

@export var quickslot_containers : Array[CogitoQuickslotContainer]
@export var inventory_reference : CogitoInventory

@export var assigned_quickslot_1: InventorySlotPD
@export var assigned_quickslot_2: InventorySlotPD
@export var assigned_quickslot_3: InventorySlotPD
@export var assigned_quickslot_4: InventorySlotPD

var inventory_is_open : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for quickslot in quickslot_containers:
		quickslot.quickslot_cleared.connect(unbind_quickslot)


func unbind_quickslot(quickslot_to_unbind: CogitoQuickslotContainer):
	match quickslot_to_unbind.input_action:
		"quickslot_1":
			assigned_quickslot_1 = null
		"quickslot_2":
			assigned_quickslot_2 = null
		"quickslot_3":
			assigned_quickslot_3 = null
		"quickslot_4":
			assigned_quickslot_4 = null
		_:
			print("Can't unbind quickslot for input map action ", quickslot_to_unbind.input_action, " as no assigned inventory slot was defined.")


func bind_to_quickslot(itemslot_to_bind: InventorySlotPD, quickslot_to_bind: CogitoQuickslotContainer):
	match quickslot_to_bind.input_action:
		"quickslot_1":
			assigned_quickslot_1 = itemslot_to_bind
			quickslot_to_bind.update_quickslot_data(itemslot_to_bind)
			print("CogitoQuickSlots.gd: Assigned quickslot_1 to ", itemslot_to_bind.inventory_item.name )
		"quickslot_2":
			assigned_quickslot_2 = itemslot_to_bind
			quickslot_to_bind.update_quickslot_data(itemslot_to_bind)
			print("CogitoQuickSlots.gd: Assigned quickslot_2 to ", itemslot_to_bind.inventory_item.name )
		"quickslot_3":
			assigned_quickslot_3 = itemslot_to_bind
			quickslot_to_bind.update_quickslot_data(itemslot_to_bind)
			print("CogitoQuickSlots.gd: Assigned quickslot_3 to ", itemslot_to_bind.inventory_item.name )
		"quickslot_4":
			assigned_quickslot_4 = itemslot_to_bind
			quickslot_to_bind.update_quickslot_data(itemslot_to_bind)
			print("CogitoQuickSlots.gd: Assigned quickslot_4 to ", itemslot_to_bind.inventory_item.name )


func _unhandled_input(event):
	if !self.visible:
		return
		
	if inventory_is_open:
		print("CogitoQuickSlots.gd: Inventory is open, no item used.")
		return
	
	if event.is_action_released("quickslot_1"):
		if assigned_quickslot_1:
			print("CogitoQuickSlots.gd: Using quickslot 1...")
			inventory_reference.use_slot_data(assigned_quickslot_1.origin_index)
		else:
			print("CogitoQuickSlots.gd: Nothing assigned in quickslot 1...")
			return
	
	if event.is_action_released("quickslot_2"):
		if assigned_quickslot_2:
			print("CogitoQuickSlots.gd: Using quickslot 2...")
			inventory_reference.use_slot_data(assigned_quickslot_2.origin_index)
		else:
			print("CogitoQuickSlots.gd: Nothing assigned in quickslot 2...")
			return
		
	if event.is_action_released("quickslot_3"):
		if assigned_quickslot_3:
			print("CogitoQuickSlots.gd: Using quickslot 3...")
			inventory_reference.use_slot_data(assigned_quickslot_3.origin_index)
		else:
			print("CogitoQuickSlots.gd: Nothing assigned in quickslot 1...")
			return

	if event.is_action_released("quickslot_4"):
		if assigned_quickslot_4:
			print("CogitoQuickSlots.gd: Using quickslot 4...")
			inventory_reference.use_slot_data(assigned_quickslot_4.origin_index)
		else:
			print("CogitoQuickSlots.gd: Nothing assigned in quickslot 2...")
			return



func update_inventory_status(is_open: bool):
	inventory_is_open = is_open


func set_inventory_data(inventory_data: CogitoInventory):
	inventory_reference = inventory_data
