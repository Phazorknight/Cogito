extends PanelContainer

signal hot_bar_use(index: int)

const Slot = preload("res://COGITO/InventoryPD/UiScenes/Slot.tscn")
@onready var h_box_container = $MarginContainer/VBoxContainer/TopRow

## The amount of slots displayed in the hotbar. WARNING: This is not properly tested. Will cause errors if it's bigger than the player's inventory. Also gamepad only supports 4 slots.
@export_range(1,8) var hotbar_slot_amount : int = 4
var assigned_indexes = []

func _unhandled_input(event):
	# Handles Gamepad Hotbar input
	if not visible:
		return
		
	if event.is_action_released("quickslot_1"):
		hot_bar_use.emit(assigned_indexes[0])
	
	if event.is_action_released("quickslot_2"):
		hot_bar_use.emit(assigned_indexes[1])
		
	if event.is_action_released("quickslot_3"):
		hot_bar_use.emit(assigned_indexes[2])
	
	if event.is_action_released("quickslot_4"):
		hot_bar_use.emit(assigned_indexes[3])


func set_inventory_data(inventory_data : CogitoInventory) -> void:
	if !inventory_data.inventory_updated.is_connected(populate_hotbar):
		inventory_data.inventory_updated.connect(populate_hotbar)
	populate_hotbar(inventory_data)
	if !hot_bar_use.is_connected(inventory_data.use_slot_data):
		hot_bar_use.connect(inventory_data.use_slot_data)

func populate_hotbar(inventory_data : CogitoInventory) -> void:
	assigned_indexes.resize(hotbar_slot_amount)
	assigned_indexes.fill(-1)
	for child in h_box_container.get_children():
		child.queue_free()
	if inventory_data.grid:
		populate_grid(inventory_data)
	else:
		populate_non_grid(inventory_data)
		
func populate_non_grid(inventory_data : CogitoInventory):	
	for slot_data in inventory_data.inventory_slots.slice(0,hotbar_slot_amount):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		if slot_data:
			assigned_indexes[slot_data.origin_index] = slot_data.origin_index
			slot.set_slot_data(slot_data, slot_data.origin_index, false, 1)
			slot.set_hotbar_icon()
		
# For grid population, add only slots with the first unique instance of an origin_index
func populate_grid(inventory_data : CogitoInventory):
	var index = 0
	var origin_indexes = [-1]
	for slot_data in inventory_data.inventory_slots:
		if not slot_data or origin_indexes.has(slot_data.origin_index):
			continue
		assigned_indexes[index] = slot_data.origin_index
		origin_indexes.append(slot_data.origin_index)
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		slot.ammo_slot = true
		slot.set_slot_data(slot_data, slot_data.origin_index, false, 1)
		slot.set_hotbar_icon()
		index += 1
		if index == hotbar_slot_amount:
			return
	for leftover_slots in hotbar_slot_amount-index:
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
