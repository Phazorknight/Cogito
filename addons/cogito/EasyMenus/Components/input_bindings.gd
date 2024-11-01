extends Node

@export var action_items: Array[String]
@export var remap_entry: PackedScene

@onready var bindings_container: VBoxContainer = %BindingsContainer

func _ready() -> void:
	create_action_remap_items()
	
	
func create_action_remap_items() -> void:
	for index in range(action_items.size()):
		var action = action_items[index]		
		var input_entry = remap_entry.instantiate()
		input_entry.action = action
		bindings_container.add_child(input_entry)
