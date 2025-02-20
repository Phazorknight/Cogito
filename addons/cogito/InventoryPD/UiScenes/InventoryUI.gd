extends PanelContainer

const Slot = preload("./Slot.tscn")

@export var inventory_name : String = ""

@export var color_can_swap : Color = Color.YELLOW
@export var color_can_not_place : Color = Color.DARK_RED
@export var color_can_place : Color = Color.LIME_GREEN

@onready var grid_container = $MarginContainer/VBoxContainer/GridContainer
@onready var label = $MarginContainer/VBoxContainer/Label
@onready var button_take_all: Button = $MarginContainer/VBoxContainer/Button_TakeAll

var slot_array = []
var first_slot : InventorySlotPD
var grabbed_slot : SlotPanel
var loaded_inventory_data : CogitoInventory
var currently_focused_slot : SlotPanel

func _ready():
	label.text = inventory_name
	button_take_all.hide()


func set_inventory_data(inventory_data : CogitoInventory):
	if !inventory_data.inventory_updated.is_connected(populate_item_grid):
		inventory_data.inventory_updated.connect(populate_item_grid)
	label.text = inventory_name
	loaded_inventory_data = inventory_data
	populate_item_grid(inventory_data)


func clear_inventory_data(inventory_data : CogitoInventory):
	inventory_data.inventory_updated.disconnect(populate_item_grid)
	slot_array.clear()


func populate_item_grid(inventory_data : CogitoInventory) -> void:
	CogitoGlobals.debug_log(true,"InventoryUI.gd", "Populate_item_grid called." )
	
	for child in grid_container.get_children():
		child.queue_free()
	
	# Clearing array for gamepad navigation.
	slot_array.clear()
	
	if inventory_data.grid:
		# set grid container columns to the width (x) of the inventory
		grid_container.columns = inventory_data.inventory_size.x
	
	var index = 0
	for slot_data in inventory_data.inventory_slots:
		var slot = Slot.instantiate()
		grid_container.add_child(slot)
		# Filling array for gamepad navigation.
		slot_array.append(slot)
	
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		slot.slot_pressed.connect(inventory_data.on_slot_button_pressed)
		slot.highlight_slot.connect(highlight_slots)
		slot.using_grid(inventory_data.grid)
	
		if slot_data:
			slot.set_slot_data(slot_data, index, false, grid_container.columns)
			slot.set_hotbar_icon()
			
		index += 1
	
	override_slot_focus_neighbors()
	
	if inventory_data.grid:
		apply_slot_icon_regions()


func override_slot_focus_neighbors():
	var index = 0
	for slot in slot_array:
		# SETTING LEFT NEIGHBOR
		if index != 0:
			slot.set_focus_neighbor(SIDE_LEFT, slot_array[index-1].get_path())
		
		# SETTING RIGHT NEIGHBOR
		if index != slot_array.size() - 1:
			slot.set_focus_neighbor(SIDE_RIGHT, slot_array[index+1].get_path())
			
		# SETTING UP NEIGHBOR:
		if (index - loaded_inventory_data.inventory_size.x) >= 0: #This checks if the selected slot is NOT already in the top row.
			slot.set_focus_neighbor(SIDE_TOP, slot_array[index - loaded_inventory_data.inventory_size.x].get_path())

		# SETTING UP DOWN NEIGHOR:
		if (index + loaded_inventory_data.inventory_size.x) < slot_array.size(): #This checks that the slot is NOT already in the bottom row.
			slot.set_focus_neighbor(SIDE_BOTTOM, slot_array[index + loaded_inventory_data.inventory_size.x].get_path() )

		index += 1



func apply_slot_icon_regions():
	var added_items = []
	for slot in slot_array:
		if slot.item_data and not added_items.has(slot.origin_index):
			added_items.append(slot.origin_index)
			apply_item_icons(slot.item_data, slot.origin_index)
		else:
			continue


func apply_item_icons(item_data : InventoryItemPD, origin_index: int):
	var icon_slot_size = item_data.item_size
	for x in icon_slot_size.x:
		for y in icon_slot_size.y:
			CogitoGlobals.debug_log(true,"InventoryUI.gd","apply_item_icons: item_data=" + item_data.name + " set_icon_region(" + str(x) + "," + str(y) + ")")
			slot_array[origin_index + x + (y*grid_container.columns)].set_icon_region(x, y)


func detach_grabbed_slot():
	for slot in slot_array:
		slot.selection_panel.hide()
	grabbed_slot = null


func highlight_slots(index: int, highlight: bool):
	if !grabbed_slot or !grabbed_slot.item_data or !grabbed_slot.grid:
		return
	
	var highlight_size : Vector2i = grabbed_slot.item_data.item_size if grabbed_slot.grid else Vector2i(1,1)
	var item_intersections = count_intersecting_items(index, highlight_size)
	for x in highlight_size.x:
		for y in highlight_size.y:
			if out_of_bounds(index, x, y):
				continue
			var selection = slot_array[index + x + (y*grid_container.columns)].selection_panel
			if highlight:
				selection.show()
			else:
				selection.hide()
	change_slot_colours(highlight_size, index, item_intersections)


func change_slot_colours(slot_group: Vector2i, index, item_intersections):
	for x in slot_group.x:
		for y in slot_group.y:
			if out_of_bounds(index, x, y):
				continue
			var selection = slot_array[index + x + (y*grid_container.columns)].selection_panel
			selection.modulate = set_colour(item_intersections)


# count intersections to check if item can be swapped out
func count_intersecting_items(index: int, intersect_size: Vector2i):
	var intersecting_origins = []
	for x in intersect_size.x:
		for y in intersect_size.y:
			if out_of_bounds(index, x, y):
				return -1
			var adj_item = slot_array[index + x + (y*grid_container.columns)]
			if not adj_item:
				continue
			if adj_item.origin_index != -1 and not intersecting_origins.has(adj_item.origin_index):
				intersecting_origins.append(adj_item.origin_index)
	return intersecting_origins.size()


func set_colour(item_intersections):
	if item_intersections == -1 or item_intersections > 1:
		return color_can_not_place
	elif item_intersections == 1:
		return color_can_swap
	else:
		return color_can_place


func out_of_bounds(index: int, x, y):
	# check outside of y bounds
	if (index + x + (y*grid_container.columns)) >= slot_array.size():
		return true
	var right_edge: int = index + x
	# check row does not shift
	if (int(index / grid_container.columns) != int(right_edge / grid_container.columns)):
		return true
	return false


func _on_visibility_changed():
	# This is here because to prevent a dead end signal error in the inspector.
	pass
