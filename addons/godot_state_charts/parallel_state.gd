@tool
@icon("parallel_state.svg")
## A parallel state is a state which can have sub-states, all of which are active
## when the parallel state is active.
class_name ParallelState
extends StateChartState

# all children of the state
var _sub_states:Array[StateChartState] = []

func _state_init():
	super._state_init()
	# find all children of this state which are states
	for child in get_children():
		if child is StateChartState:
			_sub_states.append(child)
			child._state_init()

	# since there is no state transitions between parallel states, we don't need to
	# subscribe to events from our children


func _handle_transition(transition:Transition, source:StateChartState):
	# resolve the target state
	var target = transition.resolve_target()
	if not target is StateChartState:
		push_error("The target state '" + str(transition.to) + "' of the transition from '" + source.name + "' is not a state.")
		return
	
	# the target state can be
	# 0. this state. in this case just activate the state and all its children.
	#    this can happen when a child state transfers back to its parent state.
	# 1. a direct child of this state. this is the easy case in which
	#    we will do nothing, because our direct children are always active.
	# 2. a descendant of this state. in this case we find the direct child which
	#    is the ancestor of the target state and then ask it to perform
	#    the transition.
	# 3. no descendant of this state. in this case, we ask our parent state to
	#    perform the transition

	if target == self:
		# exit this state
		_state_exit()
		# then re-enter it
		_state_enter(target)
		return

	if target in get_children():
		# all good, nothing to do.
		return
		
	if self.is_ancestor_of(target):
		# find the child which is the ancestor of the new target.
		for child in get_children():
			if child is StateChartState and child.is_ancestor_of(target):
				# ask child to handle the transition
				child._handle_transition(transition, source)
				return
		return
	
	# ask the parent
	get_parent()._handle_transition(transition, source)

func _state_enter(transition_target:StateChartState):
	super._state_enter(transition_target)
	# enter all children
	for child in _sub_states:
		child._state_enter(transition_target)
	
func _state_exit():
	# exit all children
	for child in _sub_states:
		child._state_exit()
	
	super._state_exit()

func _state_step():
	super._state_step()
	for child in _sub_states:
		child._state_step()

func _process_transitions(trigger_type:StateChart.TriggerType, event:StringName = "") -> bool:
	if not active:
		return false

	# forward to all children
	var handled := false
	for child in _sub_states:
		var child_handled_it = child._process_transitions(trigger_type, event)
		handled = handled or child_handled_it

	# if any child handled this, we don't touch it anymore
	if handled:
		# emit the event_received signal for completeness
		# if the trigger type is event
		if trigger_type == StateChart.TriggerType.EVENT:
			self.event_received.emit(event)
		return true

	# otherwise handle it ourselves
	# defer to the base class
	return super._process_transitions(trigger_type, event)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = super._get_configuration_warnings()
	
	var child_count = 0
	for child in get_children():
		if child is StateChartState:
			child_count += 1
	
	if child_count < 2:
		warnings.append("Parallel states should have at least two child states.")
	
	
	return warnings
