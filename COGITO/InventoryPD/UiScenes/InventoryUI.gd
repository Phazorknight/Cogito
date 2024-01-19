extends PanelContainer

const Slot = preload("res://COGITO/InventoryPD/UiScenes/Slot.tscn")

@export var inventory_name : String = ""
@onready var grid_container = $MarginContainer/VBoxContainer/GridContainer
@onready var label = $MarginContainer/VBoxContainer/Label
var slot_array = []
var first_slot


func _ready():
	label.text = inventory_name

func set_inventory_data(inventory_data : InventoryPD):
	inventory_data.inventory_updated.connect(populate_item_grid)
	label.text = inventory_name
	populate_item_grid(inventory_data)

func clear_inventory_data(inventory_data : InventoryPD):
	inventory_data.inventory_updated.disconnect(populate_item_grid)
	slot_array.clear()

func populate_item_grid(inventory_data : InventoryPD) -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	# Clearing array for gamepad navigation.
	slot_array.clear()
	
	for slot_data in inventory_data.inventory_slots:
		var slot = Slot.instantiate()
		grid_container.add_child(slot)
		# Filling array for gamepad navigation.
		slot_array.append(slot)
	
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		slot.slot_pressed.connect(inventory_data.on_slot_button_pressed)
		slot.set_focus_mode(FOCUS_ALL)
	
		if slot_data:
			slot.set_slot_data(slot_data)
	

func _on_visibility_changed():
	# This is here because to prevent a dead end signal error in the inspector.
	pass # Replace with function body.
