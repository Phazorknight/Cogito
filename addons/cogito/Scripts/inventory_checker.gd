extends Node

signal item_found

@export var container_to_check : CogitoContainer
@export var item_to_check_for : InventoryItemPD

var container_inventory : CogitoInventory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	container_inventory = container_to_check.inventory_data


func is_item_in_inventory(sought_item:InventoryItemPD, inventory: CogitoInventory) -> bool:
	for slot in inventory.inventory_slots:
		if slot != null and slot.inventory_item == sought_item:
			return true
	
	return false


func update_inventory() -> void:
	container_inventory = container_to_check.inventory_data


func check_inventory() -> void:
	print("Inventory checker: Checking for ", item_to_check_for.name, " in ", container_inventory)
	if is_item_in_inventory(item_to_check_for, container_inventory):
		print("Inventory Checker: Item found: ", item_to_check_for)
		item_found.emit()
