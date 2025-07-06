@icon("state_chart.svg")
@tool
## This is statechart. It contains a root state (commonly a compound or parallel state) and is the entry point for 
## the state machine.
class_name StateChart 
extends Node

## The the remote debugger
const DebuggerRemote = preload("utilities/editor_debugger/editor_debugger_remote.gd")

## The state chart utility class.
const StateChartUtil = preload("utilities/state_chart_util.gd")

## Emitted when the state chart receives an event. This will be 
## emitted no matter which state is currently active and can be 
## useful to trigger additional logic elsewhere in the game 
## without having to create a custom event bus. It is also used
## by the state chart debugger. Note that this will emit the 
## events in the order in which they are processed, which may 
## be different from the order in which they were received. This is
## because the state chart will always finish processing one event
## fully before processing the next. If an event is received
## while another is still processing, it will be enqueued.
signal event_received(event:StringName)

@export_group("Debugging")
## Flag indicating if this state chart should be tracked by the 
## state chart debugger in the editor.
@export var track_in_editor:bool = false

## If set, the state chart will issue a warning when trying to
## send an event that is not configured for any transition of 
## the state chart. It is usually a good idea to leave this
## enabled, but in certain cases this may get in the way so
## you can disable it here.
@export var warn_on_sending_unknown_events:bool = true

@export_group("")
## Initial values for the expression properties. These properties can be used in expressions, e.g
## for guards or transition delays. It is recommended to set an initial value for each property
## you use in an expression to ensure that this expression is always valid. If you don't set
## an initial value, some expressions may fail to be evaluated if they use a property that has
## not been set yet.
@export var initial_expression_properties:Dictionary = {}

## The root state of the state chart.
var _state:StateChartState = null

## This dictonary contains known properties used in expression guards. Use the 
## [method set_expression_property] to add properties to this dictionary.
var _expression_properties:Dictionary = {
}

## A list of pending events 
var _queued_events:Array[StringName] = []

## Whether or not a property change is pending.
var _property_change_pending:bool = false

## Whether or not a state change occured during processing and we need to re-run 
## automatic transitions that may have been triggered by the state change.
var _state_change_pending:bool = false

## Flag indicating if the state chart is currently processing. 
## Until a change is fully processed, no further changes can
## be introduced from the outside.
var _locked_down:bool = false

## Flag indicating if the state chart is frozen.
## If the state chart is frozen, new events and transitions will be discarded.
var _frozen:bool = false

var _queued_transitions:Array[Dictionary] = []
var _transitions_processing_active:bool = false

var _debugger_remote:DebuggerRemote = null
var _valid_event_names:Array[StringName] = []

## A trigger type that defines events that can trigger a transition.
enum TriggerType {
	## No trigger type. This usually should not happen and is used as a default value.
	NONE = 0,
	## The transition will be triggered by an event.
	EVENT = 1,
	## The transition is automatic and thus will be triggered when the state is entered.
	STATE_ENTER = 2,
	## The transition is automatic and will be triggered by a property change.
	PROPERTY_CHANGE = 4,
	## The transition is automatic and will be triggered by a state change.
	STATE_CHANGE = 8,
}

func _ready() -> void:
	if Engine.is_editor_hint():
		return 

	# check if we have exactly one child that is a state
	if get_child_count() != 1:
		push_error("StateChart must have exactly one child")
		return

	# check if the child is a state
	var child:Node = get_child(0)
	if not child is StateChartState:
		push_error("StateMachine's child must be a State")
		return
		
	# in debug builds, collect a list of valid event names
	# to warn the developer when using an event that doesn't
	# exist.
	if OS.is_debug_build():
		_valid_event_names = StateChartUtil.events_of(self)
	
	# set the initial expression properties
	if initial_expression_properties != null:
		for key in initial_expression_properties.keys():
			if not key is String and not key is StringName:
				push_error("Expression property names must be strings. Ignoring initial expression property with key ", key)
				continue
			_expression_properties[key] = initial_expression_properties[key]

	# initialize the state machine
	_state = child as StateChartState
	_state._state_init()

	# We wait one frame before entering initial state, so
	# parents of the state chart have a chance to run their
	# _ready methods first and not get events from the state
	# chart while they have not yet been initialized
	_enter_initial_state.call_deferred()

	# if we are in an editor build and this chart should be tracked 
	# by the debugger, create a debugger remote
	if track_in_editor and OS.has_feature("editor") and not Engine.is_editor_hint():
		_debugger_remote = DebuggerRemote.new(self)
		# add the remote as a child, so it gets cleaned up when the state
		# chart is deleted
		add_child(_debugger_remote)


func _enter_initial_state():
	# https://github.com/derkork/godot-statecharts/issues/143
	# make sure that transitions resulting from state_enter handlers still 
	# adhere our transactional processing
	_transitions_processing_active = true
	_locked_down = true

	# enter the state
	_state._state_enter(null)
	
	# run any queued transitions that may have come up during the enter
	_run_queued_transitions()
	
	# run any queued external events that may have come up during the enter
	_run_changes()


## Sends an event to this state chart. The event will be passed to the innermost active state first and
## is then moving up in the tree until it is consumed. Events will trigger transitions and actions via emitted
## signals. There is no guarantee when the event will be processed. The state chart
## will process the event as soon as possible but there is no guarantee that the 
## event will be fully processed when this method returns.
func send_event(event:StringName) -> void:
	if _frozen:
		push_error("The state chart is currently frozen. Cannot set send events.")

		return

	if not is_node_ready():
		push_error("State chart is not yet ready. If you call `send_event` in _ready, please call it deferred, e.g. `state_chart.send_event.call_deferred(\"my_event\").")
		return
		
	if not is_instance_valid(_state):
		push_error("State chart has no root state. Ignoring call to `send_event`.")
		return
		
	if warn_on_sending_unknown_events and event != "" and OS.is_debug_build() and not _valid_event_names.has(event):
		push_warning("State chart does not have an event '", event , "' defined. Sending this event will do nothing.")
	
	_queued_events.append(event)
	if _locked_down:
		return
		
	_run_changes()
		
		
## Sets a property that can be used in expression guards. The property will be available as a global variable
## with the same name. E.g. if you set the property "foo" to 42, you can use the expression "foo == 42" in
## an expression guard.
func set_expression_property(name:StringName, value) -> void:
	if _frozen:
		push_error("The state chart is currently frozen. Cannot set expression properties.")
		return

	if not is_node_ready():
		push_error("State chart is not yet ready. If you call `set_expression_property` in `_ready`, please call it deferred, e.g. `state_chart.set_expression_property.call_deferred(\"my_property\", 5).")
		return
		
	if not is_instance_valid(_state):
		push_error("State chart has no root state. Ignoring call to `set_expression_property`.")
		return
	
	_expression_properties[name] = value
	_property_change_pending = true
	
	if not _locked_down:
		_run_changes()
		

## Returns the value of a previously set expression property. If the property does not exist, the default value
## will be returned.
func get_expression_property(name:StringName, default:Variant = null) -> Variant:
	return _expression_properties.get(name, default)


func _run_changes() -> void:
	# enable the reentrance lock
	_locked_down = true
	
	while (not _queued_events.is_empty()) or _property_change_pending or _state_change_pending:
		# We process stuff in this order:
		# 1. State changes
		if _state_change_pending:		
			_state_change_pending = false
			_state._process_transitions(TriggerType.STATE_CHANGE)

		# 2. Property changes
		if _property_change_pending:
			_property_change_pending = false
			_state._process_transitions(TriggerType.PROPERTY_CHANGE)

		# 3. Events
		if not _queued_events.is_empty():
			# process the next event	
			var next_event = _queued_events.pop_front()
			event_received.emit(next_event)
			_state._process_transitions(TriggerType.EVENT, next_event)
	
	_locked_down = false


## Allows states to queue a transition for running. This will eventually run the transition
## once all currently running transitions have finished. States should call this method
## when they want to transition away from themselves. 
func _run_transition(transition:Transition, source:StateChartState) -> void:
	# Queue up the transition for running
	_queued_transitions.append({transition : source})
	
	# if we are currently inside of a transition, finish processing the queue so we 
	# get a predictable order. Queing can happen a state has an automatic transition on enter, 
	# or when a transition is triggered as part of a signal handler. In these cases, we want to
	# finish the current transition before starting a new one because otherwise the transitions
	# see really unpredictable state changes. In a sense, every transition is also a
	# transaction that needs to be fully processed before the next one can start.
	if _transitions_processing_active:
		return
		
	_run_queued_transitions()
	

## Runs all queued transitions until none are left. This also checks for infinite loops in transitions and 
## ensures triggering guards on state changes.
func _run_queued_transitions() -> void:

	_transitions_processing_active = true

	var execution_count := 1
	
	# if we still have transitions
	while _queued_transitions.size() > 0:
		var next_transition_entry = _queued_transitions.pop_front()
		var next_transition = next_transition_entry.keys()[0]
		var next_transition_source = next_transition_entry[next_transition]
		_do_run_transition(next_transition, next_transition_source)
		execution_count += 1
	
		if execution_count > 100:
			push_error("Infinite loop detected in transitions. Aborting. The state chart is now in an invalid state and no longer usable.")
			break
	
	_transitions_processing_active = false
	
	# transitions trigger a state change which can in turn activate
	# other transitions, so we need to handle these
	if not _locked_down:
		_run_changes()


## Runs the transition. Used internally by the state chart, do not call this directly.	
func _do_run_transition(transition:Transition, source:StateChartState):
	if source.active:
		# Notify interested parties that the transition is about to be taken
		transition.taken.emit()
		source._handle_transition(transition, source)
		_state_change_pending = true
	else:
		_warn_not_active(transition, source)	


func _warn_not_active(transition:Transition, source:StateChartState):
	push_warning("Ignoring request for transitioning from ", source.name, " to ", transition.to, " as the source state is no longer active. Check whether your trigger multiple state changes within a single frame.")



## Calls the `step` function in all active states. Used for situations where `state_processing` and 
## `state_physics_processing` don't make sense (e.g. turn-based games, or games with a fixed timestep).
func step() -> void:
	if _frozen:
		push_error("The state chart is currently frozen. Cannot step.")
		return

	if not is_node_ready():
		push_error("State chart is not yet ready. If you call `step` in `_ready`, please call it deferred, e.g. `state_chart.step.call_deferred()`.")
		return
		
	if not is_instance_valid(_state):
		push_error("State chart has no root state. Ignoring call to `step`.")
		return
	_state._state_step()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray = []
	if get_child_count() != 1:
		warnings.append("StateChart must have exactly one child")
	else:
		var child:Node = get_child(0)
		if not child is StateChartState:
			warnings.append("StateChart's child must be a State")
	return warnings


## Freezes the state chart and all states. While frozen, no changes can be made to a state chart.
func freeze():
	_frozen = true
	var to_freeze:Array[StateChartState] = [_state]
	while not to_freeze.is_empty():
		var next := to_freeze.pop_back()
		next._toggle_processing(true)
		for child in next.get_children():
			if child is StateChartState:
				to_freeze.append(child)

## Thaws the state chart and all states. After being thawed, changes can again be made to the state chart.
func thaw():
	var to_thaw:Array[StateChartState] = [_state]
	while not to_thaw.is_empty():
		var next := to_thaw.pop_back()
		next._toggle_processing(false)
		for child in next.get_children():
			if child is StateChartState:
				to_thaw.append(child)

	_frozen = false
