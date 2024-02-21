extends Resource
class_name InventorySlotPD

const MAX_STACK_SIZE : int = 99

@export var inventory_item : InventoryItemPD
#@export_range(1, MAX_STACK_SIZE) var quantity : int = 1: set = set_quantity
@export var quantity : int = 1

func set_quantity(value: int):
	quantity = value
	
	if quantity > 1 and not inventory_item.is_stackable:
		quantity = 1
		push_error("%s is not stackable, setting quantity to 1" % inventory_item.name )

func can_merge_with(other_slot_data: InventorySlotPD) -> bool:
	print("can_merge_with")
	return inventory_item == other_slot_data.inventory_item \
			and inventory_item.is_stackable \
			and quantity < inventory_item.stack_size

func can_fully_merge_with(other_slot_data: InventorySlotPD) -> bool:
	print("can_fully_merge_with")
	return inventory_item == other_slot_data.inventory_item \
			and inventory_item.is_stackable \
			and quantity + other_slot_data.quantity <= inventory_item.stack_size

func fully_merge_with(other_slot_data: InventorySlotPD):
	quantity += other_slot_data.quantity
	
func create_single_slot_data() -> InventorySlotPD:
	var new_slot_data = duplicate()
	new_slot_data.quantity = 1
	quantity -= 1
	return new_slot_data
