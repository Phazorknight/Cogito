## This is the remote part of the editor debugger. It attaches to a state
## chart similar to the in-game debugger and forwards signals and debug
## information to the editor. 
extends Node


const DebuggerMessage = preload("editor_debugger_message.gd")
const SettingsPropagator = preload("editor_debugger_settings_propagator.gd")

# The scene tree, needed to interface with the settings propagator
var _tree:SceneTree

# the state chart we track
var _state_chart:StateChart 

# whether to send transitions to the editor
var _ignore_transitions:bool = true
# whether to send events to the editor
var _ignore_events:bool = true


## Sets up the debugger remote to track the given state chart.
func _init(state_chart:StateChart):
	if not is_instance_valid(state_chart):
		push_error("Probable bug: State chart is not valid. Please report this bug.")
		return

	if not state_chart.is_inside_tree():
		push_error("Probably bug: State chart is not in tree. Please report this bug.")
		return
		
	_state_chart = state_chart


func _ready():
	# subscribe to settings changes coming from the editor debugger
	# will auto-unsubscribe when the chart goes away. We do this before
	# sending state_chart_added, so we get the initial settings update delivered
	SettingsPropagator.get_instance(get_tree()).settings_updated.connect(_on_settings_updated)

	# send initial state chart
	DebuggerMessage.state_chart_added(_state_chart)
	
	# prepare signals and send initial state of all states
	_prepare()


func _on_settings_updated(chart:NodePath, ignore_events:bool, ignore_transitions:bool):
	if _state_chart.get_path() != chart:
		return # doesn't affect this chart
		
	_ignore_events = ignore_events
	_ignore_transitions = ignore_transitions


## Connects all signals from the currently processing state chart
func _prepare():
	_state_chart.event_received.connect(_on_event_received)

	# find all state nodes below the state chart and connect their signals
	for child in _state_chart.get_children():
		if child is StateChartState:
			_prepare_state(child)


func _prepare_state(state:StateChartState):
	state.state_entered.connect(_on_state_entered.bind(state))
	state.state_exited.connect(_on_state_exited.bind(state))
	state.transition_pending.connect(_on_transition_pending.bind(state))

	# send initial state
	DebuggerMessage.state_updated(_state_chart, state)

	# recurse into children
	for child in state.get_children():
		if child is StateChartState:
			_prepare_state(child)
		if child is Transition:
			child.taken.connect(_on_transition_taken.bind(state, child))


func _on_transition_taken(source:StateChartState, transition:Transition):
	if _ignore_transitions:
		return
	DebuggerMessage.transition_taken(_state_chart, source, transition)


func _on_event_received(event:StringName):
	if _ignore_events:
		return
	DebuggerMessage.event_received(_state_chart, event)
	
func _on_state_entered(state:StateChartState):
	DebuggerMessage.state_entered(_state_chart, state)		

func _on_state_exited(state:StateChartState):
	DebuggerMessage.state_exited(_state_chart, state)

func _on_transition_pending(num1, remaining, state:StateChartState):
	DebuggerMessage.transition_pending(_state_chart, state, state._pending_transition, remaining)
		

