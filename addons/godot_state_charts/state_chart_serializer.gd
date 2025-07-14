## Helper class for serializing and deserializing state charts.
class_name StateChartSerializer

## Serializes the given state chart and returns a serialized object that
## can be stored as part of a saved game.
static func serialize(state_chart: StateChart) -> SerializedStateChart:
	state_chart.freeze()
	var result := _serialize_chart(state_chart)
	state_chart.thaw()
	return result


## Deserializes the given serialized state chart into the given state chart. Returns a set of
## error messages. If the serialized state chart was no longer compatible with the current state
## chart, nothing will happen. The operation is successful when the returned array is emtpy.
static func deserialize(serialized_state_chart: SerializedStateChart, state_chart: StateChart) -> PackedStringArray:
	var error_messages: PackedStringArray = []
	_verify_chart_compatibility(serialized_state_chart, state_chart, error_messages)
	if not error_messages.is_empty():
		return error_messages

	state_chart.freeze()
	_deserialize_chart(serialized_state_chart, state_chart)
	state_chart.thaw()

	state_chart._run_queued_transitions()
	state_chart._run_changes()

	return error_messages


## Recursively builds a Resource representation of this state chart and it's children.
## This function is intended to be used for serializing into the desired format (such as a file or JSON)
## as needed for game saves or network transmission.
## This method assumes that the StateChart will be constructed and added to the tree prior
## to loading the resource. As such, it does not store data, such as Transitions, which will be
## created in the Node Tree.
static func _serialize_chart(state_chart: StateChart) -> SerializedStateChart:
	assert(state_chart != null, "tried to serialize a null chart.")

	var result: SerializedStateChart = SerializedStateChart.new()
	result.name = state_chart.name
	result.expression_properties = state_chart._expression_properties
	result.queued_events = state_chart._queued_events
	result.property_change_pending = state_chart._property_change_pending
	result.state_change_pending = state_chart._state_change_pending
	result.locked_down = state_chart._locked_down
	result.queued_transitions = state_chart._queued_transitions
	result.transitions_processing_active = state_chart._transitions_processing_active
	result.state = _serialize_state(state_chart._state)

	return result


## Loads a state chart from a resource. This will replace the current state chart's internal state with the one in the resource.
## Events and transitions will not be processed or queued during the load process.
## Loading assumes that the state chart states have already been instantiated into your node tree. This will
## update existing nodes in the tree, but not create new nodes that do not yet exist. Data for non-existent nodes
## will be discarded. If you want to create new nodes, you need to do so manually from the resource objects prior
## to calling this method.
static func _deserialize_chart(serialized_chart: SerializedStateChart, target: StateChart) -> void:
	assert(serialized_chart != null, "tried to deserialize a null serialized state chart.")
	assert(target != null, "tried to deserialize into a null state chart.")

	# load the state chart data
	target._expression_properties = serialized_chart.expression_properties
	target._queued_events = serialized_chart.queued_events
	target._property_change_pending = serialized_chart.property_change_pending
	target._state_change_pending = serialized_chart.state_change_pending
	target._locked_down = serialized_chart.locked_down
	target._queued_transitions = serialized_chart.queued_transitions
	target._transitions_processing_active = serialized_chart.transitions_processing_active

	# and all the states
	_deserialize_state(serialized_chart.state, target._state)


## Serializes the given state chart state into a serialized state chart state.
static func _serialize_state(state: StateChartState) -> SerializedStateChartState:
	assert(state != null, "tried to serialize a null state.")
	var result := SerializedStateChartState.new()
	result.name = state.name
	result.state_type = _type_for_state(state)
	result.active = state._state_active
	result.pending_transition_name = state._pending_transition.name if state._pending_transition != null else ""
	result.pending_transition_remaining_delay = state._pending_transition_remaining_delay
	result.pending_transition_initial_delay = state._pending_transition_initial_delay
	if state is HistoryState:
		result.history = state.history

	result.children = []

	for child in state.get_children():
		if child is StateChartState:
			result.children.append(_serialize_state(child))
	return result


## Deserializes a serialized state chart state into	a state chart state.
static func _deserialize_state(serialized_state: SerializedStateChartState, target: StateChartState) -> void:
	assert(serialized_state != null, "tried to deserialize a null serialized state.")
	assert(target != null, "tried to deserialize into a null state.")

	target._state_active = serialized_state.active

	if serialized_state.pending_transition_name != "":
		target._pending_transition = target.get_node(serialized_state.pending_transition_name)
	else:
		target._pending_transition = null

	target._pending_transition_remaining_delay = serialized_state.pending_transition_remaining_delay
	target._pending_transition_initial_delay = serialized_state.pending_transition_initial_delay
	if target is HistoryState:
		target.history = serialized_state.history

	for child_serialized_state in serialized_state.children:
		var child_state: StateChartState = target.get_node(NodePath(child_serialized_state.name))
		_deserialize_state(child_serialized_state, child_state)

	if target is CompoundState:
		# ensure _active_state is set to the currently active child
		if target._state_active:
			# find the currently active child
			for child in target.get_children():
				if child is StateChartState and child._state_active:
					target._active_state = child
					break


## Verify that the serialized state chart can actually be restored on the target state chart.
static func _verify_chart_compatibility(serialized_state_chart: SerializedStateChart, target: StateChart, error_messages: PackedStringArray) -> void:
	var message_prefix: String = "[%s]:" % [target.get_path()]
	if serialized_state_chart.version != 1:
		error_messages.append("%s Unsupported serialized state chart version %s != %s." % [message_prefix, serialized_state_chart.version, 1])

	_verify_state_compatiblity(serialized_state_chart.state, target._state, error_messages)


## Checks if the given serialized state can be restored on the given state.
static func _verify_state_compatiblity(serialized_state: SerializedStateChartState, target: StateChartState, error_messages: PackedStringArray) -> void:
	var message_prefix: String = "[%s]:" % [_get_state_path(target)]

	if serialized_state.name != target.name:
		error_messages.append("%s State name mismatch: %s != %s" % [message_prefix, target.name, serialized_state.name])

	if serialized_state.state_type != _type_for_state(target):
		error_messages.append("%s State type mismatch: %s != %s " % [message_prefix, _type_for_state(target), serialized_state.state_type])

	if not serialized_state.pending_transition_name.is_empty() \
	and target.get_node_or_null(serialized_state.pending_transition_name) == null:
		error_messages.append("%s Pending transition %s not found" % [message_prefix, serialized_state.pending_transition_name])

	var states_in_tree: Array[StringName] = []

	var states_in_serialized_version: Array[StringName] = []

	for child in target.get_children():
		if child is StateChartState:
			states_in_tree.append(child.name)

	for serialized_child in serialized_state.children:
		states_in_serialized_version.append(serialized_child.name)

		var child: Node = target.get_node_or_null(NodePath(serialized_child.name))
		if child == null:
			error_messages.append("%s Serialized state has child state %s but no such state exists in the tree." % [message_prefix, serialized_child.name])
		else:
			_verify_state_compatiblity(serialized_child, child, error_messages)

	var in_tree_but_missing_in_serialized: Array = states_in_tree.filter(func(it): return not states_in_serialized_version.has(it))
	for item in in_tree_but_missing_in_serialized:
		error_messages.append("%s Tree has child state %s but no such child state exists in the serialized state." % [message_prefix, str(item)])


## Returns an integer giving the state type.
static func _type_for_state(state: StateChartState) -> int:
	if state is AtomicState:
		return 0
	if state is CompoundState:
		return 1
	if state is ParallelState:
		return 2
	if state is HistoryState:
		return 3
	assert(false, "Unknown state type")
	return -1


## Returns the path from the state's chart to the state.
static func _get_state_path(state: StateChartState) -> String:
	if state == null or state._chart == null:
		return ""
	return str(state._chart.get_path_to(state))
