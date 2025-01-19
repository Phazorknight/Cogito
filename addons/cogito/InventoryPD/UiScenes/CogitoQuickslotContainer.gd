extends Control
class_name CogitoQuickslotContainer

signal quickslot_pressed(quickslot_container: CogitoQuickslotContainer)
signal quickslot_cleared(quickslot_container: CogitoQuickslotContainer)

var item_reference : InventoryItemPD
var iventory_slot_reference : InventorySlotPD

@export var input_action : String = "quickslot_1"

@onready var item_texture: TextureRect = $MarginContainer/ItemTexture
@onready var label_stack_amount: Label = $MarginContainer/LabelStackAmount
@onready var dynamic_input_icon: DynamicInputIcon = $MarginContainerInputIcon/DynamicInputIcon


func _ready() -> void:
	item_texture.hide()
	label_stack_amount.hide()
	dynamic_input_icon.action_name = input_action
	dynamic_input_icon.update_input_icon()


func _on_gui_input(event):
	# LEFT CLICK ON QUICKSLOT CONTAINER
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.is_pressed():
				print("Quickslot left clicked!")
				quickslot_pressed.emit(self)
	
	# RIGHT CLICK ON QUICKSLOT CONTAINER
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.is_pressed():
				print("Quickslot right clicked!")
				clear_this_quickslot()


func clear_this_quickslot():
	iventory_slot_reference = null
	item_reference = null
	item_texture.hide()
	label_stack_amount.hide()
	quickslot_cleared.emit(self)


func update_quickslot_stack():
	if iventory_slot_reference.quantity > 1:
		label_stack_amount.show()
		label_stack_amount.text = str(iventory_slot_reference.quantity)
	elif iventory_slot_reference.quantity == 1:
		label_stack_amount.hide()
	else:
		clear_this_quickslot()
	

func update_quickslot_data(slot_data: InventorySlotPD) -> void:
	if slot_data == null:
		iventory_slot_reference = null
		item_reference = null
		item_texture.hide()
		label_stack_amount.hide()
	else:
		iventory_slot_reference = slot_data
		item_reference = iventory_slot_reference.inventory_item
		
		item_texture.show()
		item_texture.texture = item_reference.icon
		iventory_slot_reference.stack_has_changed.connect(update_quickslot_stack)
		update_quickslot_stack()
