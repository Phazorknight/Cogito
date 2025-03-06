class_name CogitoWorldPropertySetter
extends Node

## Properties to set when a TRUE bool signal is received. Also used when a void signal is received.
@export var properties_to_set_ON : Dictionary
## Properties to set when a FALSE bool signal is received
@export var properties_to_set_OFF : Dictionary

func on_bool_signal(is_on: bool):
	if is_on:
		set_properties(properties_to_set_ON)
	else:
		set_properties(properties_to_set_OFF)


func on_void_signal():
	set_properties(properties_to_set_ON)


func set_properties(properties_to_set: Dictionary) -> void:
	var world_dict = CogitoSceneManager._current_world_dict
	
	for property in properties_to_set:
		world_dict[property] = properties_to_set[property]
		CogitoGlobals.debug_log(true, "world_property_setter.gd", str(property) + " set to " + str(properties_to_set[property]) )
