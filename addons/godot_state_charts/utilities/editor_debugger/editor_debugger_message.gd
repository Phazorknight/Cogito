@tool

const MESSAGE_PREFIX = "gds"
const STATE_CHART_ADDED_MESSAGE = MESSAGE_PREFIX + ":sca"
const STATE_CHART_REMOVED_MESSAGE = MESSAGE_PREFIX + ":scr"
const STATE_UPDATED_MESSAGE = MESSAGE_PREFIX + ":stu"
const STATE_ENTERED_MESSAGE = MESSAGE_PREFIX + ":sten"
const STATE_EXITED_MESSAGE = MESSAGE_PREFIX + ":stex"
const TRANSITION_PENDING_MESSAGE = MESSAGE_PREFIX + ":trp"
const TRANSITION_TAKEN_MESSAGE = MESSAGE_PREFIX + ":trf"
const STATE_CHART_EVENT_RECEIVED_MESSAGE = MESSAGE_PREFIX + ":scev"

const DebuggerStateInfo = preload("editor_debugger_state_info.gd")

## Whether we can currently send debugger messages.
static func _can_send() -> bool:
	return not Engine.is_editor_hint() and OS.has_feature("editor")
	
	
## Sends a state_chart_added message.
static func state_chart_added(chart:StateChart) -> void:
	if not _can_send():
		return
	
	if not chart.is_inside_tree():
		return
		
	EngineDebugger.send_message(STATE_CHART_ADDED_MESSAGE, [chart.get_path()])
		
## Sends a state_chart_removed message.		
static func state_chart_removed(chart:StateChart) -> void:
	if not _can_send():
		return
	
	if not chart.is_inside_tree():
		return
		
	EngineDebugger.send_message(STATE_CHART_REMOVED_MESSAGE, [chart.get_path()])
		
		
## Sends a state_updated message
static func state_updated(chart:StateChart, state:StateChartState) -> void:
	if not _can_send():
		return
	
	if not state.is_inside_tree() or not chart.is_inside_tree():
		return

	var transition_path:NodePath = NodePath()
	if is_instance_valid(state._pending_transition) and state._pending_transition.is_inside_tree():
		transition_path = chart.get_path_to(state._pending_transition)
		
	EngineDebugger.send_message(STATE_UPDATED_MESSAGE, [Engine.get_process_frames(), DebuggerStateInfo.make_array( \
		chart.get_path(), \
		chart.get_path_to(state), \
		state.active, \
		is_instance_valid(state._pending_transition), \
		transition_path, \
		state._pending_transition_remaining_delay, \
		state)]
	)
	

## Sends a state_entered message
static func state_entered(chart:StateChart, state:StateChartState) -> void:
	if not _can_send():
		return
	
	if not state.is_inside_tree() or not chart.is_inside_tree():
		return
		
	EngineDebugger.send_message(STATE_ENTERED_MESSAGE,[Engine.get_process_frames(), chart.get_path(), chart.get_path_to(state)])

## Sends a state_exited message
static func state_exited(chart:StateChart, state:StateChartState) -> void:
	if not _can_send():
		return
	
	if not state.is_inside_tree() or not chart.is_inside_tree():
		return
		
	EngineDebugger.send_message(STATE_EXITED_MESSAGE,[Engine.get_process_frames(), chart.get_path(), chart.get_path_to(state)])

## Sends a transition taken message
static func transition_taken(chart:StateChart, source:StateChartState, transition:Transition) -> void:
	if not _can_send():
		return
	
	var target:StateChartState = transition.resolve_target()
	if not source.is_inside_tree() or not chart.is_inside_tree() or not transition.is_inside_tree() or target == null or not target.is_inside_tree():
		return
		
	EngineDebugger.send_message(TRANSITION_TAKEN_MESSAGE,[Engine.get_process_frames(), chart.get_path(), chart.get_path_to(transition), chart.get_path_to(source), chart.get_path_to(target)])


## Sends an event received message
static func event_received(chart:StateChart, event_name:StringName) -> void:
	if not _can_send():
		return
	
	if not chart.is_inside_tree():
		return
		
	EngineDebugger.send_message(STATE_CHART_EVENT_RECEIVED_MESSAGE, [Engine.get_process_frames(), chart.get_path(), event_name])

## Sends a transition pending message
static func transition_pending(chart:StateChart, source:StateChartState, transition:Transition, pending_transition_remaining_delay:float) -> void:
	if not _can_send():
		return
	
	if not source.is_inside_tree() or not chart.is_inside_tree() or not transition.is_inside_tree():
		return
		
	EngineDebugger.send_message(TRANSITION_PENDING_MESSAGE, [Engine.get_process_frames(), chart.get_path(), chart.get_path_to(source),  chart.get_path_to(transition), pending_transition_remaining_delay])


	
