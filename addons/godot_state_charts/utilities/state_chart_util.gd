@tool

## Finds the first ancestor of the given node which is a state
## chart. Returns null when none is found.
static func find_parent_state_chart(node:Node) -> StateChart:
	if node is StateChart:
		return node
	
	var parent = node.get_parent()
	while parent != null:
		if parent is StateChart:
			return parent
	
		parent = parent.get_parent()
	return null	
	
	
## Returns an array with all event names currently used in the given
## state chart.
static func events_of(chart:StateChart) -> Array[StringName]:
	var result:Array[StringName] = []
	# now collect all events below the state chart
	_collect_events(chart, result)
	result.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	return result

	
static func _collect_events(node:Node, events:Array[StringName]):
	if node is Transition:
		if node.event != "" and not events.has(node.event):
			events.append(node.event)
	
	for child in node.get_children():
		_collect_events(child, events)


## Returns all transitions of the given state chart.
static func transitions_of(chart:StateChart) -> Array[Transition]:
	var result:Array[Transition] = []
	_collect_transitions(chart, result)
	return result
	
	
static func _collect_transitions(node:Node, result:Array[Transition]):
	if node is Transition:
		result.append(node)
		
	for child in node.get_children():
		_collect_transitions(child, result)
