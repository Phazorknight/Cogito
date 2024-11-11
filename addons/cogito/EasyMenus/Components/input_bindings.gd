extends Node

@export var remap_entry: PackedScene

@onready var bindings_container: VBoxContainer = %BindingsContainer

var input_actions = {
	"forward": "Move forward",
	"back": "Move back",
	"left": "Move left",
	"right": "Move right",
	"jump": "Jump",
	"crouch": "Crouch",
	"interact": "Interact 1",
	"interact2": "Interact 2",
	"menu": "Pause",
	"inventory": "Inventory",
	"reload": "Reload",
	"quickslot_1": "Quickslot 1",
	"quickslot_2": "Quickslot 2",
	"quickslot_3": "Quickslot 3",
	"quickslot_4": "Quickslot 4",
	"inventory_drop_item": "Quick Drop Item",
	"inventory_move_item": "Move Item",
	"inventory_use_item": "Use Item",
}

func _ready() -> void:
	create_action_remap_items()
	
	
func create_action_remap_items() -> void:
	for action in input_actions:
		var input_entry = remap_entry.instantiate()
		input_entry.action = action
		bindings_container.add_child(input_entry)
		input_entry.label.text = input_actions[action]
