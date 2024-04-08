extends PanelContainer

signal hot_bar_use(index: int)

const Slot = preload("res://COGITO/InventoryPD/UiScenes/Slot.tscn")
@onready var h_box_container = $MarginContainer/VBoxContainer/TopRow

## The amount of slots displayed in the hotbar. WARNING: This is not properly tested. Will cause errors if it's bigger than the player's inventory. Also gamepad only supports 4 slots.
@export_range(1,8) var hotbar_slot_amount : int = 4


func _unhandled_input(event):
	# Handles Gamepad Hotbar input
	if not visible:
		return
		
	if event.is_action_released("quickslot_1"):
		hot_bar_use.emit(0)
	
	if event.is_action_released("quickslot_2"):
		hot_bar_use.emit(1)
		
	if event.is_action_released("quickslot_3"):
		hot_bar_use.emit(2)
	
	if event.is_action_released("quickslot_4"):
		hot_bar_use.emit(3)


func set_inventory_data(inventory_data : InventoryPD) -> void:
	if !inventory_data.inventory_updated.is_connected(populate_hotbar):
		inventory_data.inventory_updated.connect(populate_hotbar)
	populate_hotbar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)

func populate_hotbar(inventory_data : InventoryPD) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
		
	for slot_data in inventory_data.inventory_slots.slice(0,hotbar_slot_amount):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		
		if slot_data:
			slot.set_slot_data(slot_data)
