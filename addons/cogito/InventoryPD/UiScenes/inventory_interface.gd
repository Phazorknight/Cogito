extends Control

signal drop_slot_data(slot_data : InventorySlotPD)
signal inventory_open(is_true: bool)

@export var inventory_ui : Control
@onready var grabbed_slot_node = $GrabbedSlot
@onready var external_inventory_ui = $ExternalInventoryUI
@onready var hot_bar_inventory = $HotBarInventory
@onready var quick_slots : CogitoQuickslots = $QuickSlots
@onready var info_panel = $InfoPanel
@onready var item_name = $InfoPanel/MarginContainer/VBoxContainer/ItemName
@onready var item_description: Control = $InfoPanel/MarginContainer/VBoxContainer/ItemDescription
@onready var drop_prompt: Control = $InfoPanel/MarginContainer/VBoxContainer/HBoxDrop
@onready var assign_prompt: Control = $InfoPanel/MarginContainer/VBoxContainer/HBoxAssign
@onready var use_prompt: Control = $InfoPanel/MarginContainer/VBoxContainer/HBoxUse


## Sound that plays as a generic error.
@export var sound_error : AudioStream
@export var is_using_hotbar: bool = true

@export_group("Inventory Screen")
@export var nodes_to_show : Array[Node]
@export var nodes_to_hide : Array[Node]

var is_inventory_open : bool:
	set(value):
		is_inventory_open = value
		inventory_open.emit(is_inventory_open)
var grabbed_slot_data: InventorySlotPD
var external_inventory_owner : Node
var control_in_focus


func _ready():
	# Connect to signal that detects change of input device
	InputHelper.device_changed.connect(_on_input_device_change)
	# Calling this function once to set proper input icons
	_on_input_device_change(InputHelper.device,InputHelper.device_index)
	
	is_inventory_open = false
	info_panel.hide()
	
	grabbed_slot_node.set_mouse_filter(2) # Setting mouse filter to ignore.
	grabbed_slot_node.set_focus_mode(0) # Setting focus mode to none.
	grabbed_slot_node.visibility_changed.connect(update_grabbed_slot_position)


func _on_input_device_change(_device, _device_index):
	if _device == "keyboard":
		drop_prompt.hide()
		assign_prompt.hide()
	else:
		drop_prompt.show()
		assign_prompt.show()


func open_inventory():
	if !is_inventory_open:
		is_inventory_open = true
		info_panel.hide()
		get_viewport().gui_focus_changed.connect(_on_focus_changed)
		#inventory_ui.show()
		#player_currencies_ui.show()
		
		for node in nodes_to_show:
			node.show()
		
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
		if control_in_focus:
			control_in_focus.release_focus()
		
		# Clearing out UI grabbed slot
		if inventory_ui.grabbed_slot:
			inventory_ui.detach_grabbed_slot()
		
		for node in nodes_to_show:
			node.hide()
		#inventory_ui.hide()
		#player_currencies_ui.hide()
		
		if external_inventory_owner:
			external_inventory_owner.close()

		grabbed_slot_node.hide()
		info_panel.hide()
		external_inventory_ui.hide()

		if is_using_hotbar:
			hot_bar_inventory.show()


func _on_focus_changed(control: Control):
	if !control.has_method("set_slot_data"):
		CogitoGlobals.debug_log(true,"inventory_interface.gd", "_on_focus_changed: Not a slot. returning.")
		return
	
	if control != null:
		control_in_focus = control
	
	# Quick check to see if this is a quickslot
	if control_in_focus.has_method("update_quickslot_data"):
		return
	
	if control_in_focus.item_data and !grabbed_slot_node.visible:
		item_name.text = control_in_focus.item_data.name
		item_description.text = control_in_focus.item_data.description
		info_panel.global_position = control_in_focus.global_position + Vector2(0,control_in_focus.size.y)
		
		if control_in_focus.item_data.is_droppable:
			drop_prompt.show()
		else: drop_prompt.hide()
		
		if !control_in_focus.item_data.has_method("use"):
			use_prompt.hide()
		else:
			use_prompt.show()

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
	
	inventory_data.owner = external_inventory_owner # Setting reference to external inventory owner node
#	inventory_data.inventory_interact.connect(on_inventory_interact)
	inventory_data.inventory_button_press.connect(on_inventory_button_press)
	external_inventory_ui.inventory_name = external_inventory_owner.display_name
	external_inventory_ui.set_inventory_data(inventory_data)
	
	external_inventory_ui.show()
	external_inventory_ui.button_take_all.show()
	if !external_inventory_ui.button_take_all.pressed.is_connected(_on_take_all_pressed):
		external_inventory_ui.button_take_all.pressed.connect(_on_take_all_pressed)


## Loot Component added
func get_external_inventory():
	return external_inventory_owner

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
	inventory_data.owner = CogitoSceneManager._current_player_node  # Setting player inventory owner reference to player node
	
#	inventory_data.inventory_interact.connect(on_inventory_interact)
	if !inventory_data.inventory_button_press.is_connected(on_inventory_button_press):
		inventory_data.inventory_button_press.connect(on_inventory_button_press)
	inventory_ui.set_inventory_data(inventory_data)
	if !is_using_hotbar:
		quick_slots.show()
		# Quickslots need reference to inventory when quickslot buttons are pressed
		quick_slots.inventory_reference = inventory_data
	else:
		quick_slots.hide()
	if !inventory_open.is_connected(quick_slots.update_inventory_status):
		inventory_open.connect(quick_slots.update_inventory_status)
	grabbed_slot_node.using_grid(inventory_data.grid)


# Inventory handling on gamepad buttons
func on_inventory_button_press(inventory_data: CogitoInventory, index: int, action: String):
	match [grabbed_slot_data, action]:
		[null, "inventory_move_item"]:
			# Check if item is being wielded before grabbing it.
			var temp_slot_data = inventory_data.get_slot_data(index)
			if temp_slot_data and temp_slot_data.inventory_item and temp_slot_data.inventory_item.is_being_wielded:
					Audio.play_sound(sound_error)
					CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't move item while its being wielded.")
			else:
				grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, "inventory_move_item"]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[null, "inventory_use_item"]:
			inventory_data.use_slot_data(index)
		[_, "inventory_use_item"]:
			print("Inventory_interface.gd: Gamepad use_item pressed while grabbed_slot_data. Calling drop_single_slot_data...")
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
		[null, "inventory_drop_item"]:
			grabbed_slot_data = inventory_data.get_slot_data(index)
			if grabbed_slot_data:
				if !grabbed_slot_data.inventory_item.is_droppable:
					CogitoGlobals.debug_log(true, "inventory_interface.gd", "Item is not droppable.")
					Audio.play_sound(sound_error)
					grabbed_slot_data = null
					return
				if grabbed_slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.is_being_wielded:
				#if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
					Audio.play_sound(sound_error)
					CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop while wielding this item.")
					grabbed_slot_data = null
				else:
					CogitoGlobals.debug_log(true, "inventory_interface.gd", "Dropping slot data via gamepad ")
					grabbed_slot_data = inventory_data.grab_single_slot_data(index)
					if not _drop_item(grabbed_slot_data):
						Audio.play_sound(sound_error)
						get_parent().player.player_interaction_component.send_hint(null, "Not enough space to drop item.")
						CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop because there isn't enough space.")
					else:
						grabbed_slot_data.create_single_slot_data(grabbed_slot_data.origin_index)
						grabbed_slot_data = null
		
		[null, "inventory_assign_item"]: # Pressing "Assign quickslot" on gamepad
			CogitoGlobals.debug_log(true, "inventory_interface.gd", "Grabbing focus of quickslots.")
			grabbed_slot_data = inventory_data.grab_slot_data(index)
			quick_slots.quickslot_containers[0].grab_focus.call_deferred()
			
		[_, "inventory_assign_item"]: # When player cancels out assigning a quickslot on gamepad
			get_parent().player.inventory_data.pick_up_slot_data(grabbed_slot_data)
			grabbed_slot_data = null
			update_grabbed_slot()
		
		[_, "inventory_drop_item"]:
			Audio.play_sound(sound_error)
			CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop while moving an item.")


	var amount_of_inventory_slots = inventory_ui.slot_array.size()
	var element : int
	if index < amount_of_inventory_slots:
		element = index
	else:
		element = amount_of_inventory_slots-1
	# Should fix issues where an external inventory is bigger than the players
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


func _on_bind_grabbed_slot_to_quickslot(quickslotcontainer: CogitoQuickslotContainer):
	if grabbed_slot_data:
		CogitoGlobals.debug_log(true, "inventory_interface.gd", "Binding to quickslot container: " + str(grabbed_slot_data) + " -> " + str(quickslotcontainer) )
		#get_parent().player.inventory_data.pick_up_slot_data(grabbed_slot_data) #Swapped with line below
		quick_slots.bind_to_quickslot(grabbed_slot_data, quickslotcontainer)
		
		#inventory_ui.detach_grabbed_slot()
		#grabbed_slot_data = null
		#update_grabbed_slot()
	else:
		CogitoGlobals.debug_log(true, "inventory_interface.gd", "No grabbed slot data.")


# Grabbed slot data handling for mouse buttons
func _on_gui_input(event):
	if event is InputEventMouseButton \
		and event.is_pressed() \
		and grabbed_slot_data:
			
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if !grabbed_slot_data.inventory_item.is_droppable:
						Audio.play_sound(sound_error)
						CogitoGlobals.debug_log(true, "inventory_interface.gd", "This item isn't droppable.")
						return
					if grabbed_slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.is_being_wielded:
					#if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
						Audio.play_sound(sound_error)
						CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop while wielding this item.")
					else:
						if not _drop_item(grabbed_slot_data):
							Audio.play_sound(sound_error)
							get_parent().player.player_interaction_component.send_hint(null, "Not enough space to drop item.")
							CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop because there isn't enough space.")
						else:
							grabbed_slot_data.create_single_slot_data(grabbed_slot_data.origin_index)
							if grabbed_slot_data.quantity < 1:
								grabbed_slot_data = null
					
				MOUSE_BUTTON_RIGHT:
					if !grabbed_slot_data.inventory_item.is_droppable:
						CogitoGlobals.debug_log(true, "inventory_interface.gd", "This item isn't droppable.")
						return
					if grabbed_slot_data.inventory_item.has_method("update_wieldable_data") and grabbed_slot_data.inventory_item.is_being_wielded:
					#if grabbed_slot_data.inventory_item.ItemType.WIELDABLE and grabbed_slot_data.inventory_item.is_being_wielded:
						Audio.play_sound(sound_error)
						CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop while wielding this item.")
					else:
						if not _drop_item(grabbed_slot_data):
							Audio.play_sound(sound_error)
							get_parent().player.player_interaction_component.send_hint(null, "Not enough space to drop item.")
							CogitoGlobals.debug_log(true, "inventory_interface.gd", "Can't drop because there isn't enough space.")
						else:
							grabbed_slot_data.create_single_slot_data(grabbed_slot_data.origin_index)
							if grabbed_slot_data.quantity < 1:
								grabbed_slot_data = null
					
			update_grabbed_slot()


func _on_visibility_changed():
	if not visible and grabbed_slot_data:
		drop_slot_data.emit(grabbed_slot_data)
		grabbed_slot_data = null
		update_grabbed_slot()


func _on_inventory_ui_hidden() -> void:
	# Hides item info panel if the inventory UI screen gets hidden.
	info_panel.hide()


func _drop_item(slot_data: InventorySlotPD) -> bool:
	var player = get_parent().player
	var player_radius = player.radius
	var shape_cast = player.item_drop_shapecast
	var item_drop_distance_offset = player.get_node(player.player_hud).item_drop_distance_offset
	var camera_basis_z = get_viewport().get_camera_3d().get_global_transform().basis.z
	
	var drop_distance = abs(shape_cast.target_position.z - item_drop_distance_offset)
	
	var scene_to_drop = load(slot_data.inventory_item.drop_scene)
	var dropped_item = scene_to_drop.instantiate()
	
	if dropped_item is not CogitoObject:
		return false
		
	var item_aabb = dropped_item.get_aabb()
	var item_length = item_aabb.size.z
	
	shape_cast.add_exception(player)
	
	shape_cast.shape.size = item_aabb.size
	
	var previous_target_position = shape_cast.target_position
	shape_cast.target_position = Vector3.ZERO
	
	shape_cast.force_shapecast_update()
	
	if shape_cast.is_colliding():
		shape_cast.target_position = previous_target_position
		return false
	
	shape_cast.target_position = previous_target_position
	
	shape_cast.force_shapecast_update()
	
	var collision_safe_fraction = shape_cast.get_closest_collision_safe_fraction()
	var safe_drop_distance = drop_distance * collision_safe_fraction
	
	if item_length < player_radius:
		if safe_drop_distance < player_radius:
			return false
	else:
		if safe_drop_distance < item_length:
			return false
			
	CogitoSceneManager._current_scene_root_node.add_child(dropped_item)
	dropped_item.global_rotation = player.body.global_rotation
	dropped_item.position = shape_cast.global_position + (safe_drop_distance - item_length / 2) * -camera_basis_z
		
	Audio.play_sound(slot_data.inventory_item.sound_drop)
	
	if item_length < player_radius:
		dropped_item.position = shape_cast.global_position + (safe_drop_distance - item_length / 2) * -camera_basis_z
	else:
		dropped_item.position = shape_cast.global_position + (safe_drop_distance - item_length / 2 + player_radius) * -camera_basis_z
		
	dropped_item.find_interaction_nodes()
	for node in dropped_item.interaction_nodes:
		if node.has_method("get_item_type"):
			node.slot_data = slot_data

	return true
