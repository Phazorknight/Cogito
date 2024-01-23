extends Control

signal drop_slot_data(slot_data : InventorySlotPD)

@onready var inventory_ui = $InventoryUI
@onready var grabbed_slot = $GrabbedSlot
@onready var external_inventory_ui = $ExternalInventoryUI
@onready var hot_bar_inventory = $HotBarInventory
@onready var info_panel = $InfoPanel
@onready var item_name = $InfoPanel/MarginContainer/VBoxContainer/ItemName
@onready var item_description = $InfoPanel/MarginContainer/VBoxContainer/ItemDescription

## Sound that plays as a generic error.
@export var sound_error : AudioStream

var is_inventory_open : bool
var grabbed_slot_data: InventorySlotPD
var external_inventory_owner : Node
var control_in_focus

func _ready():
	is_inventory_open = false
	info_panel.hide()
	grabbed_slot.set_focus_mode(0)


func open_inventory():
	if !is_inventory_open:
		print("Inventory interface: Opening inventory.")
		is_inventory_open = true
		get_viewport().gui_focus_changed.connect(_on_focus_changed)
		inventory_ui.show()
		inventory_ui.slot_array[0].grab_focus()
#		inventory_interface.grabbed_slot.show()
#		inventory_interface.external_inventory_ui.show()

		for slot_panel in inventory_ui.slot_array:
			if !slot_panel.mouse_exited.is_connected(_slot_on_mouse_exit):
				slot_panel.mouse_exited.connect(_slot_on_mouse_exit)
	hot_bar_inventory.hide()
	
func close_inventory():
	if is_inventory_open:
		print("Inventory interface: Closing inventory.")
		if grabbed_slot_data != null: # If the player was holding/moving items, these will be added back to the inventory.
			get_parent().player.inventory_data.pick_up_slot_data(grabbed_slot_data)
			grabbed_slot_data = null
		is_inventory_open = false
		get_viewport().gui_focus_changed.disconnect(_on_focus_changed)
		inventory_ui.hide()
		grabbed_slot.hide()
		info_panel.hide()
		external_inventory_ui.hide()
		hot_bar_inventory.show()


func _on_focus_changed(control: Control):
	if control != null:
		control_in_focus = control
		
	if control_in_focus.item_data and !grabbed_slot.visible:
		item_name.text = control_in_focus.item_data.name
		item_description.text = control_in_focus.item_data.descpription
		info_panel.global_position = control_in_focus.global_position + Vector2(0,control_in_focus.size.y)
		info_panel.show()
	else:
		info_panel.hide()
	
	if grabbed_slot.visible:
		grabbed_slot.global_position = control_in_focus.global_position + control_in_focus.size


func _slot_on_mouse_exit():
	info_panel.hide()		

# DEPRECATED. Was used to move the grabbed slot icon with the mouse cursor.
# Could bring this back later and make it conditional to mouse/kb input.
func _physics_process(_delta):
	if grabbed_slot.visible:
		pass
#		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5, 5)
#		grabbed_slot.global_position = control_in_focus.global_position + Vector2(15,15)


func set_external_inventory(_external_inventory_owner):
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
#	inventory_data.inventory_interact.connect(on_inventory_interact)
	inventory_data.inventory_button_press.connect(on_inventory_button_press)
	external_inventory_ui.inventory_name = external_inventory_owner.inventory_name
	external_inventory_ui.set_inventory_data(inventory_data)
	
	external_inventory_ui.show()


func clear_external_inventory():
	if external_inventory_owner:
		var inventory_data = external_inventory_owner.inventory_data
		
#		inventory_data.inventory_interact.disconnect(on_inventory_interact)
		inventory_data.inventory_button_press.disconnect(on_inventory_button_press)
		external_inventory_ui.inventory_name = ""
		external_inventory_ui.clear_inventory_data(inventory_data)
		external_inventory_ui.hide()
		external_inventory_owner = null


func set_player_inventory_data(inventory_data : InventoryPD):
#	inventory_data.inventory_interact.connect(on_inventory_interact)
	inventory_data.inventory_button_press.connect(on_inventory_button_press)
	inventory_ui.set_inventory_data(inventory_data)

# Inventory handling on gamepad buttons
func on_inventory_button_press(inventory_data: InventoryPD, index: int, action: String):
	match [grabbed_slot_data, action]:
		[null, "inventory_move_item"]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
			grabbed_slot.global_position = control_in_focus.global_position + control_in_focus.size
		[_, "inventory_move_item"]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, "inventory_use_item"]:
			inventory_data.use_slot_data(index)
		[_, "inventory_use_item"]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
		[_, "inventory_drop_item"]:
			grabbed_slot_data = inventory_data.get_slot_data(index)
			if grabbed_slot_data:
				if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
					Audio.play_sound(sound_error)
					print("Can't drop while wielding this item.")
					grabbed_slot_data = null
				else:
					print("Dropping slot data via gamepad")
					grabbed_slot_data = inventory_data.grab_single_slot_data(index)
					drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
					grabbed_slot_data = null

	inventory_ui.slot_array[index].grab_focus()
	update_grabbed_slot()


func update_grabbed_slot():
	if grabbed_slot_data:
		grabbed_slot.show()
		grabbed_slot.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot.hide()

# Grabbed slot data handling for mouse buttons
func _on_gui_input(event):
	if event is InputEventMouseButton \
		and event.is_pressed() \
		and grabbed_slot_data:
			
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
						Audio.play_sound(sound_error)
						print("Can't drop while wielding this item.")
					else:
						drop_slot_data.emit(grabbed_slot_data)
						grabbed_slot_data = null
						print("Dropping ", grabbed_slot_data)
					
				MOUSE_BUTTON_RIGHT:
					if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
						Audio.play_sound(sound_error)
						print("Can't drop while wielding this item.")
					else:
						drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
						if grabbed_slot_data.quantity < 1:
							grabbed_slot_data = null
					
			update_grabbed_slot()


func _on_visibility_changed():
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()

