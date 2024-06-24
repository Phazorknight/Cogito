extends Control

signal drop_slot_data(slot_data : InventorySlotPD)

@onready var inventory_ui = $InventoryUI
@onready var grabbed_slot_node = $GrabbedSlot
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
	
	grabbed_slot_node.set_mouse_filter(2) # Setting mouse filter to ignore.
	grabbed_slot_node.set_focus_mode(0) # Setting focus mode to none.
	grabbed_slot_node.visibility_changed.connect(update_grabbed_slot_position)
	

func open_inventory():
	if !is_inventory_open:
		is_inventory_open = true
		info_panel.hide()
		get_viewport().gui_focus_changed.connect(_on_focus_changed)
		inventory_ui.show()
		if InputHelper.device_index != -1: # Check if gamepad is used
			inventory_ui.slot_array[0].grab_focus() # Grab focus of inventory slot for gamepad users.
#		inventory_interface.grabbed_slot_node.show()
#		inventory_interface.external_inventory_ui.show()

		for slot_panel in inventory_ui.slot_array:
			if !slot_panel.mouse_exited.is_connected(_slot_on_mouse_exit):
				slot_panel.mouse_exited.connect(_slot_on_mouse_exit)
	hot_bar_inventory.hide()


func close_inventory():
	if is_inventory_open:
		if grabbed_slot_data != null: # If the player was holding/moving items, these will be added back to the inventory.
			get_parent().player.inventory_data.pick_up_slot_data(grabbed_slot_data)
			grabbed_slot_data = null
		is_inventory_open = false
		get_viewport().gui_focus_changed.disconnect(_on_focus_changed)
		inventory_ui.hide()
		if external_inventory_owner:
			external_inventory_owner.close()
		grabbed_slot_node.hide()
		info_panel.hide()
		external_inventory_ui.hide()
		hot_bar_inventory.show()


func _on_focus_changed(control: Control):
	if !control.has_method("set_slot_data"):
		print("Not a slot. returning.")
		return
	
	if control != null:
		control_in_focus = control
		
	if control_in_focus.item_data and !grabbed_slot_node.visible:
		item_name.text = control_in_focus.item_data.name
		item_description.text = control_in_focus.item_data.description
		info_panel.global_position = control_in_focus.global_position + Vector2(0,control_in_focus.size.y)
		#if InputHelper.device_index != -1: # Only showing info panel when using a controller.
		info_panel.show()
		if !control.mouse_exited.is_connected(_slot_on_mouse_exit):
			control.mouse_exited.connect(_slot_on_mouse_exit)
		
	else:
		info_panel.hide()
	
	# Updating the currently focused slot in the inventory_ui
	inventory_ui.currently_focused_slot = control_in_focus
	
	# How a grabbed item gets displayed.
	if grabbed_slot_node.visible:
		grabbed_slot_node.set_mouse_filter(2) # Setting mouse filter to ignore.
		grabbed_slot_node.set_focus_mode(0) # Setting focus mode to none.
		if InputHelper.device_index != -1: # Updating grabbed item position if using gamepad
			update_grabbed_slot_position()


func _slot_on_mouse_exit():
	info_panel.hide()


func update_grabbed_slot_position():
	#print("Inventory interface: update grabbed slot position to ", control_in_focus, " at ", control_in_focus.global_position)
	grabbed_slot_node.global_position = control_in_focus.global_position + (control_in_focus.size / 2)


func _physics_process(_delta):
	if InputHelper.device_index == -1: #Checking for keyboard/mouse control.
		if grabbed_slot_node.visible:
			grabbed_slot_node.global_position = get_global_mouse_position() + Vector2(5, 5)
			return

		if info_panel.visible:
			info_panel.global_position = get_global_mouse_position() + Vector2(5, 5)


func set_external_inventory(_external_inventory_owner):
	external_inventory_owner = _external_inventory_owner
	var inventory_data = external_inventory_owner.inventory_data
	
#	inventory_data.inventory_interact.connect(on_inventory_interact)
	inventory_data.inventory_button_press.connect(on_inventory_button_press)
	external_inventory_ui.inventory_name = external_inventory_owner.inventory_name
	external_inventory_ui.set_inventory_data(inventory_data)
	
	external_inventory_ui.show()
	external_inventory_ui.button_take_all.show()
	if !external_inventory_ui.button_take_all.pressed.is_connected(_on_take_all_pressed):
		external_inventory_ui.button_take_all.pressed.connect(_on_take_all_pressed)


func _on_take_all_pressed():
	external_inventory_owner.inventory_data.take_all_items(get_parent().player.inventory_data)


func clear_external_inventory():
	if external_inventory_owner:
		var inventory_data = external_inventory_owner.inventory_data
		
#		inventory_data.inventory_interact.disconnect(on_inventory_interact)
		inventory_data.inventory_button_press.disconnect(on_inventory_button_press)
		external_inventory_ui.inventory_name = ""
		external_inventory_ui.clear_inventory_data(inventory_data)
		external_inventory_ui.hide()
		external_inventory_owner = null


func set_player_inventory_data(inventory_data : CogitoInventory):
#	inventory_data.inventory_interact.connect(on_inventory_interact)
	if !inventory_data.inventory_button_press.is_connected(on_inventory_button_press):
		inventory_data.inventory_button_press.connect(on_inventory_button_press)
	inventory_ui.set_inventory_data(inventory_data)
	grabbed_slot_node.using_grid(inventory_data.grid)


# Inventory handling on gamepad buttons
func on_inventory_button_press(inventory_data: CogitoInventory, index: int, action: String):
	match [grabbed_slot_data, action]:
		[null, "inventory_move_item"]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, "inventory_move_item"]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, "inventory_use_item"]:
			inventory_data.use_slot_data(index)
		[_, "inventory_use_item"]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
		[_, "inventory_drop_item"]:
			grabbed_slot_data = inventory_data.get_slot_data(index)
			if grabbed_slot_data:
				if grabbed_slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.is_being_wielded:
				#if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
					Audio.play_sound(sound_error)
					print("Can't drop while wielding this item.")
					grabbed_slot_data = null
				else:
					print("Dropping slot data via gamepad")
					grabbed_slot_data = inventory_data.grab_single_slot_data(index)
					drop_slot_data.emit(grabbed_slot_data.create_single_slot_data(index))
					grabbed_slot_data = null

	var amount_of_inventory_slots = inventory_ui.slot_array.size()
	var element : int
	if index < amount_of_inventory_slots:
		element = index
	else:
		element = amount_of_inventory_slots-1
	# Should fix issues where an external inventory is bigger than the players
	#print("Inventory_interface: grabbing focus for slot_array index = ", element)
	inventory_ui.slot_array[element].grab_focus()
	update_grabbed_slot()


func update_grabbed_slot():
	if grabbed_slot_data:
		grabbed_slot_node.show()
		grabbed_slot_node.set_slot_data(grabbed_slot_data, grabbed_slot_node.get_index(), true, 0)
		inventory_ui.grabbed_slot = grabbed_slot_node
		if external_inventory_ui.visible:
			external_inventory_ui.grabbed_slot = grabbed_slot_node
		grabbed_slot_node.set_grabbed_dimensions()
	else:
		grabbed_slot_node.hide()
		inventory_ui.detach_grabbed_slot()
		external_inventory_ui.detach_grabbed_slot()


# Grabbed slot data handling for mouse buttons
func _on_gui_input(event):
	if event is InputEventMouseButton \
		and event.is_pressed() \
		and grabbed_slot_data:
			
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if grabbed_slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.is_being_wielded:
					#if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
						Audio.play_sound(sound_error)
						print("Can't drop while wielding this item.")
					else:
						drop_slot_data.emit(grabbed_slot_data)
						print("Dropping ", grabbed_slot_data)
						grabbed_slot_data = null
					
				MOUSE_BUTTON_RIGHT:
					if grabbed_slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.is_being_wielded:
					#if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
						Audio.play_sound(sound_error)
						print("Can't drop while wielding this item.")
					else:
						drop_slot_data.emit(grabbed_slot_data.create_single_slot_data(grabbed_slot_data.origin_index))
						if grabbed_slot_data.quantity < 1:
							grabbed_slot_data = null
					
			update_grabbed_slot()


func _on_visibility_changed():
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()
