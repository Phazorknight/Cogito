# This class is used to serialize a state chart to a resource. It is intended 
# to make it easier to save and load state charts, as well as to transfer them
# over the network if needed.
#
# This class contains the state of the state chart, as well as the state of all
# its children.
class_name SerializedStateChart
extends Resource

## This is just in case we change the way this is serialized down the road,
## so we have a way of migrating.
@export var version:int = 1
@export var name: String = ""
@export var expression_properties: Dictionary = {}
@export var queued_events: Array[StringName] = []
@export var property_change_pending: bool = false
@export var state_change_pending: bool = false
@export var locked_down: bool = false
@export var queued_transitions: Array[Dictionary] = []
@export var transitions_processing_active: bool = false
@export var state: SerializedStateChartState = null

func _to_string() -> String:
	return """SerializedStateChart(
		version: %d
		name: %s
		expression_properties: %s
		queued_events: %s
		property_change_pending: %s
		state_change_pending: %s
		locked_down: %s
		queued_transitions: %s
		transitions_processing_active: %s
		state: %s
	)""" % [
		version,
		name,
		JSON.stringify(expression_properties, "\t"),
		JSON.stringify(queued_events, "\t"), 
		property_change_pending,
		state_change_pending,
		locked_down,
		JSON.stringify(queued_transitions, "\t"),
		transitions_processing_active,
		state.debug_string() if state != null else "null"
	]
