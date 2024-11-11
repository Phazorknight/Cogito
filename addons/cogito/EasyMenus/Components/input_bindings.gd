extends Node

@export var remap_entry: PackedScene
@export var separator_entry: PackedScene

@onready var bindings_container: VBoxContainer = %BindingsContainer

var config = ConfigFile.new()


var input_actions = {
	"separator_movement": "MOVEMENT",
	"forward": "Move forward",
	"back": "Move back",
	"left": "Move left",
	"right": "Move right",
	"jump": "Jump",
	"crouch": "Crouch",
	"separator_actions": "ACTIONS",
	"action_primary": "Primary Action",
	"action_secondary": "Secondary Action",
	"interact": "Interact 1",
	"interact2": "Interact 2",
	"reload": "Reload",
	"quickslot_1": "Quickslot 1",
	"quickslot_2": "Quickslot 2",
	"quickslot_3": "Quickslot 3",
	"quickslot_4": "Quickslot 4",
	"separator_inventory": "MENUS",
	"menu": "Pause",
	"inventory": "Inventory",
	"inventory_drop_item": "Quick Drop Item",
	"inventory_move_item": "Move Item",
	"inventory_use_item": "Use Item",
}

func _ready() -> void:
	load_keybindings_from_config()
	create_action_remap_items()


func load_keybindings_from_config():
	var err = config.load(OptionsConstants.config_file_name)
	if err != 0:
		print("Keybindings: Loading options config failed.")
		#save_keybindings_to_config()
		
	var serialized_inputs = config.get_value(OptionsConstants.key_binds, OptionsConstants.input_helper_string)
	if serialized_inputs:
		InputHelper.deserialize_inputs_for_actions(serialized_inputs)
	else:
		print("Keybindings: No saved bindings found.")



func save_keybindings_to_config():
	var serialized_inputs = InputHelper.serialize_inputs_for_actions()
	config.set_value(OptionsConstants.key_binds, OptionsConstants.input_helper_string, serialized_inputs)
	config.save(OptionsConstants.config_file_name)

	
func create_action_remap_items() -> void:
	for action in input_actions:
		if action.contains("separator"):
			var separator = separator_entry.instantiate()
			bindings_container.add_child(separator)
			separator.separator_text = input_actions[action]
		else:
			var input_entry = remap_entry.instantiate()
			input_entry.action = action
			bindings_container.add_child(input_entry)
			input_entry.label.text = input_actions[action]
