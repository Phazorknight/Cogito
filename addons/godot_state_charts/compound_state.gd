@tool
@icon("compound_state.svg")
## A compound state is a state that has multiple sub-states of which exactly one can
## be active at any given time.
class_name CompoundState
extends StateChartState

## Called when a child state is entered.
signal child_state_entered()

## Called when a child state is exited.
signal child_state_exited()

## The initial state which should be activated when this state is activated.
@export_node_path("StateChartState") var initial_state:NodePath:
	get:
		return initial_state
	set(value):
		initial_state = value
		update_configuration_warnings() 


## The currently active substate.
var _active_state:StateChartState = null

## The initial state
@onready var _initial_state:StateChartState = get_node_or_null(initial_state)

## The history states of this compound state.
var _history_states:Array[HistoryState] = []
## Whether any of the history states needs a deep history.
var _needs_deep_history:bool = false

func _init() -> void:
	# subscribe to the child_entered_tree signal in edit mode so we can
	# automatically set the initial state when a new sub-state is added
	if Engine.is_editor_hint():
		child_entered_tree.connect(
			func(child:Node):
			# when a child is added in the editor and the child is a state
			# and we don't have an initial state yet, set the initial state 
			# to the newly added child
			if child is StateChartState and initial_state.is_empty():
				# the newly added node may have a random name now, 
				# so we need to defer the call to build a node path
				# to the next frame, so the editor has time to rename
				# the node to its final name
				(func(): initial_state = get_path_to(child)).call_deferred()
		)

	
func _state_init():
	super._state_init()

	# check if we have any history states
	for child in get_children():
		if child is HistoryState:
			var child_as_history_state:HistoryState = child as HistoryState
			_history_states.append(child_as_history_state)
			# remember if any of the history states needs a deep history
			_needs_deep_history = _needs_deep_history or child_as_history_state.deep

	# initialize all substates. find all children of type State and call _state_init on them.
	for child in get_children():
		if child is StateChartState:
			var child_as_state:StateChartState = child as StateChartState
			child_as_state._state_init()
			child_as_state.state_entered.connect(func(): child_state_entered.emit())
			child_as_state.state_exited.connect(func(): child_state_exited.emit())

func _state_enter(transition_target:StateChartState):
	super._state_enter(transition_target)

	# activate the initial state _unless_ one of these are true 
	# - the transition target is a descendant of this state
	# - we already have an active state because entering the state triggered an immediate transition to a child state
	# - we are no longer active becasue entering the state triggered an immediate transition to some other state
	var target_is_descendant := false
	if transition_target != null and is_ancestor_of(transition_target):
		target_is_descendant = true
	
	if not target_is_descendant and not is_instance_valid(_active_state) and _state_active:
		if _initial_state != null:
			if _initial_state is HistoryState:
				_restore_history_state(_initial_state)
			else:
				_active_state = _initial_state
				_active_state._state_enter(null)
		else:
			push_error("No initial state set for state '" + name + "'.")

func _state_step():
	super._state_step()
	if _active_state != null:
		_active_state._state_step()

func _state_save(saved_state:SavedState, child_levels:int = -1):
	super._state_save(saved_state, child_levels)

	# in addition save all history states, as they are never active and normally would not be saved
	var parent = saved_state.get_substate_or_null(self)
	if parent == null:
		push_error("Probably a bug: The state of '" + name + "' was not saved.")
		return

	for history_state in _history_states:
		history_state._state_save(parent, child_levels)

func _state_restore(saved_state:SavedState, child_levels:int = -1):
	super._state_restore(saved_state, child_levels)

	# in addition check if we are now active and if so determine the current active state
	if active:
		# find the currently active child
		for child in get_children():
			if child is StateChartState and child.active:
				_active_state = child
				break

func _state_exit():
	# if we have any history states, we need to save the current active state
	if _history_states.size() > 0:
		var saved_state = SavedState.new()
		# we save the entire hierarchy if any of the history states needs a deep history
		# otherwise we only save this level. This way we can save memory and processing time
		_state_save(saved_state, -1 if _needs_deep_history else 1)

		# now save the saved state in all history states
		for history_state in _history_states:
			# when saving history it's ok when we save deep history in a history state that doesn't need it
			# because at restore time we will use the state's deep flag to determine if we need to restore
			# the entire hierarchy or just this level. This way we don't need multiple copies of the same
			# state hierarchy.
			history_state.history = saved_state

	# deactivate the current state
	if _active_state != null:
		_active_state._state_exit()
		_active_state = null
	super._state_exit()


func _process_transitions(trigger_type:StateChart.TriggerType, event:StringName = "") -> bool:
	if not active:
		return false

	# forward to the active state
	if is_instance_valid(_active_state):
		if _active_state._process_transitions(trigger_type, event):
			# emit the event_received signal when the trigger type is event
			if trigger_type == StateChart.TriggerType.EVENT:
				self.event_received.emit(event)
			return true

	# if the event was not handled by the active state, we handle it here
	# base class will also emit the event_received signal
	return super._process_transitions(trigger_type, event)


func _handle_transition(transition:Transition, source:StateChartState):
	# print("CompoundState._handle_transition: " + name + " from " + source.name + " to " + str(transition.to))
	# resolve the target state
	var target = transition.resolve_target()
	if not target is StateChartState:
		push_error("The target state '" + str(transition.to) + "' of the transition from '" + source.name + "' is not a state.")
		return
	
	# the target state can be
	# 0. this state. in this case exit this state and re-enter it. This can happen when
	#    a child state transfers to its parent state.
	# 1. a direct child of this state. this is the easy case in which
	#    we will deactivate the current _active_state and activate the target
	# 2. a descendant of this state. in this case we find the direct child which
	#    is the ancestor of the target state, activate it and then ask it to perform
	#    the transition.
	# 3. no descendant of this state. in this case, we ask our parent state to
	#    perform the transition

	if target == self:
		# exit this state and re-enter it
		_state_exit()
		_state_enter(target)
		return

	if target in get_children():
		# all good, now first deactivate the current state
		if is_instance_valid(_active_state):
			_active_state._state_exit()
		
		# now check if the target is a history state, if this is the 
		# case, we need to restore the saved state
		if target is HistoryState:
			_restore_history_state(target)
			return

		# else, just activate the target state
		_active_state = target
		_active_state._state_enter(target)
		return
		
	if self.is_ancestor_of(target):
		# find the child which is the ancestor of the new target.
		for child in get_children():
			if child is StateChartState and child.is_ancestor_of(target):
				# found it. 
				# change active state if necessary
				if _active_state != child:
					if is_instance_valid(_active_state):
						_active_state._state_exit()

					_active_state = child
					# give the transition target because we will send
					# the transition to the child state right after we activate it.
					# this avoids the child needlessly entering the initial state
					_active_state._state_enter(target)
					
				# ask child to handle the transition
				child._handle_transition(transition, source)
				return
		return
	
	# ask the parent
	get_parent()._handle_transition(transition, source)


func _restore_history_state(target:HistoryState):
	# print("Target is history state, restoring saved state.")
	var saved_state = target.history
	if saved_state != null:
		# restore the saved state
		_state_restore(saved_state, -1 if target.deep else 1)
		return
	# print("No history saved so far, activating default state.")
	# if we don't have history, we just activate the default state
	var default_state = target.get_node_or_null(target.default_state)
	if is_instance_valid(default_state):
		_active_state = default_state
		_active_state._state_enter(null)
		return
	else:
		push_error("The default state '" + str(target.default_state) + "' of the history state '" + target.name + "' cannot be found.")
		return


func _get_configuration_warnings() -> PackedStringArray:
	var warnings = super._get_configuration_warnings()
	
	# count the amount of child states
	var child_count = 0
	for child in get_children():
		if child is StateChartState:
			child_count += 1

	if child_count < 1:
		warnings.append("Compound states should have at least one child state.")
	
	elif child_count < 2:
		warnings.append("Compound states with only one child state are not very useful. Consider adding more child states or removing this compound state.")
		
	var the_initial_state = get_node_or_null(initial_state)
	
	if not is_instance_valid(the_initial_state):
		warnings.append("Initial state could not be resolved, is the path correct?")
		
	elif the_initial_state.get_parent() != self:
		warnings.append("Initial state must be a direct child of this compound state.")
	
	return warnings
