extends Node

@export var action_items: Array[String]
@export var remap_button: PackedScene

@onready var bindings_grid_container: GridContainer = %BindingsGridContainer

func _ready() -> void:
	create_action_remap_items()
	
	
func create_action_remap_items() -> void:
	for index in range(action_items.size()):
		var action = action_items[index]		
		var label = Label.new()
		label.text = action
		bindings_grid_container.add_child(label)
		#var button = RemapButton.new()
		var button = remap_button.instantiate()
		button.action = action
		bindings_grid_container.add_child(button)
