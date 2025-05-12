extends Control
class_name CogitoQuickslotContainer

signal quickslot_pressed(quickslot_container: CogitoQuickslotContainer)
signal quickslot_cleared(quickslot_container: CogitoQuickslotContainer)

var item_reference : InventoryItemPD
var inventory_slot_reference : InventorySlotPD

@export var input_action : String = "quickslot_1"

## AudioStream that plays when slot gets highlighted.
@export var sound_highlight : AudioStream

@onready var selection_panel = $Selected
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
				quickslot_pressed.emit(self)
	
	# RIGHT CLICK ON QUICKSLOT CONTAINER
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.is_pressed():
				clear_this_quickslot()
	
	# GAMEPAD ASSIGN HANDLING
	if event is InputEventJoypadButton and event.is_action_pressed("inventory_use_item"):
		quickslot_pressed.emit(self)
	
	# GAMEPAD ASSIGN HANDLING
	if event is InputEventJoypadButton and event.is_action_pressed("inventory_move_item"):
		clear_this_quickslot()


func clear_this_quickslot():
	inventory_slot_reference = null
	item_reference = null
	item_texture.hide()
	label_stack_amount.hide()
	quickslot_cleared.emit(self)


func update_quickslot_stack():
	if !inventory_slot_reference:
		return
	
	if inventory_slot_reference.quantity > 1:
		label_stack_amount.show()
		label_stack_amount.text = str(inventory_slot_reference.quantity)
	elif inventory_slot_reference.quantity == 1:
		label_stack_amount.hide()
	else:
		CogitoGlobals.debug_log(true,"COgitoQuickslotContainer", "quickslot stack cleared." )
		clear_this_quickslot()
	

func update_quickslot_data(slot_data: InventorySlotPD) -> void:
	if slot_data == null:
		CogitoGlobals.debug_log(true,"COgitoQuickslotContainer", "update_quickslot_data(): passed slot_data was null!" )
		inventory_slot_reference = null
		item_reference = null
		item_texture.hide()
		label_stack_amount.hide()
	else:
		CogitoGlobals.debug_log(true,"COgitoQuickslotContainer", "update_quickslot_data(): passed slot_data was " + str(slot_data) )
		inventory_slot_reference = slot_data
		item_reference = inventory_slot_reference.inventory_item
		
		item_texture.show()
		item_texture.texture = item_reference.icon
		
		#Setting stack once here.
		if inventory_slot_reference.quantity > 1:
			label_stack_amount.show()
			label_stack_amount.text = str(inventory_slot_reference.quantity)
		if !inventory_slot_reference.stack_has_changed.is_connected(update_quickslot_stack):
			inventory_slot_reference.stack_has_changed.connect(update_quickslot_stack)


func set_slot_data() -> void:
	# Adding this method so the control node focus management of inventory_interface.gd
	# will treat this like a regular inventory slot.
	pass

func _on_focus_entered() -> void:
	Audio.play_sound(sound_highlight)
	selection_panel.show()

func _on_focus_exited() -> void:
	selection_panel.hide()
