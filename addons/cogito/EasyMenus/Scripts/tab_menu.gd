class_name CogitoTabMenu
extends TabContainer
## This class can be extended to create a tab menu with controller support.

## Helper for controller input. Sets the node  to focus on for each tab.


@export var enable_focus_on_tabs : bool = true
## The array index corresponds to the tabs.
@export var nodes_to_focus: Array[Control]

@export_group("Inventory Settings")
## If one of the tabs is a Cogito Inventory, set the tab index here. This makes sure that gamepad focus is set on an inventory slot. Leave empty if no inventory is present.
@export var tab_index_of_inventory : int
@export var inventory_interface_reference : Control

var focus_currently_on_external_inventory : bool = false


func _input(event):
	if !is_visible_in_tree():
		return
	
	if !enable_focus_on_tabs:
		return
	
	if InputHelper.device_index != -1 and inventory_interface_reference and inventory_interface_reference.external_inventory_owner:
		process_input_for_external_inventory_screen(event)
		return
	
	#Tab navigation
	if (event.is_action_pressed("ui_next_tab")):
		if current_tab + 1 == get_tab_count():
			current_tab = 0
		else:
			current_tab += 1
		
		if InputHelper.device_index != -1 and inventory_interface_reference != null and current_tab == tab_index_of_inventory:
			inventory_interface_reference.inventory_ui.slot_array[0].grab_focus.call_deferred()
			return

		if nodes_to_focus[current_tab]:
			nodes_to_focus[current_tab].grab_focus.call_deferred()
		
	if (event.is_action_pressed("ui_prev_tab")):
		if current_tab  == 0:
			current_tab = get_tab_count()-1
		else:
			current_tab -= 1

		if InputHelper.device_index != -1 and inventory_interface_reference != null and current_tab == tab_index_of_inventory:
			inventory_interface_reference.inventory_ui.slot_array[0].grab_focus.call_deferred()
			return

		if nodes_to_focus[current_tab]:
			nodes_to_focus[current_tab].grab_focus.call_deferred()
	

# Processing gamepad inputo to switch back and forth between player inventory and external inventory focus
func process_input_for_external_inventory_screen(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_next_tab")) or (event.is_action_pressed("ui_prev_tab")):
		if focus_currently_on_external_inventory:
			inventory_interface_reference.inventory_ui.slot_array[0].grab_focus.call_deferred()
			focus_currently_on_external_inventory = false
		else:
			inventory_interface_reference.external_inventory_ui.slot_array[0].grab_focus.call_deferred()
			focus_currently_on_external_inventory = true
