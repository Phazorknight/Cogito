@icon("state_chart_debugger.svg")
extends Control

const DebuggerHistory = preload("debugger_history.gd")

## Whether or not the debugger is enabled.
@export var enabled:bool = true:
	set(value):
		enabled = value
		if not Engine.is_editor_hint():
			_setup_processing(enabled)


## The initial node that should be watched. Optional, if not set
## then no node will be watched. You can set the node that should
## be watched at runtime by calling debug_node().
@export var initial_node_to_watch:NodePath

## Maximum lines to display in the history. Keep at 300 or below
## for best performance.
@export var maximum_lines:int = 300

## If set to true, events will not be printed in the history panel.
## If you send a large amount of events then this may clutter the
## output so you can disable it here.
@export var ignore_events:bool = false

## If set to true, state changes will not be printed in the history 
## panel. If you have a large amount of state changes, this may clutter
## the output so you can disable it here.
@export var ignore_state_changes:bool = false

## If set to true, transitions will not be printed in the history.
@export var ignore_transitions:bool = false

## The tree that shows the state chart.
@onready var _tree:Tree = %Tree
## The text field with the history.
@onready var _history_edit:TextEdit = %HistoryEdit

# the state chart we track
var _state_chart:StateChart
var _root:Node

# the states we are currently connected to
var _connected_states:Array[StateChartState] = []

# the transitions we are currently connected to
# key is the transition, value is the callable
var _connected_transitions:Dictionary = {}

# the debugger history in text form
var _history:DebuggerHistory = null

func _ready():
	# always run, even if the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS	
	
	# initialize the buffer
	_history = DebuggerHistory.new(maximum_lines)

	%CopyToClipboardButton.pressed.connect(func (): DisplayServer.clipboard_set(_history_edit.text))
	%ClearButton.pressed.connect(_clear_history)

	var to_watch = get_node_or_null(initial_node_to_watch)
	if is_instance_valid(to_watch):
		debug_node(to_watch)
	
	# mirror the editor settings
	%IgnoreEventsCheckbox.set_pressed_no_signal(ignore_events)
	%IgnoreStateChangesCheckbox.set_pressed_no_signal(ignore_state_changes)
	%IgnoreTransitionsCheckbox.set_pressed_no_signal(ignore_transitions)
		
	

## Adds an item to the history list.
func add_history_entry(text:String):
	_history.add_history_entry(Engine.get_process_frames(), text)

## Sets up the debugger to track the given state chart. If the given node is not 
## a state chart, it will search the children for a state chart. If no state chart
## is found, the debugger will be disabled.
func debug_node(root:Node) -> bool:
	# if we are not enabled, we do nothing
	if not enabled:
		return false
	
	_root = root
	
	# disconnect all existing signals
	_disconnect_all_signals()

	var success = _debug_node(root)
	

	# if we have no success, we disable the debugger
	if not success:
		push_warning("No state chart found. Disabling debugger.")
		_setup_processing(false)
		_state_chart = null
	else:
		# find all state nodes below the state chart and connect their signals
		_connect_all_signals()
		_clear_history()
		_setup_processing(true)

	return success


func _debug_node(root:Node) -> bool:
	# if we have no root, we use the scene root
	if not is_instance_valid(root):
		return false

	if root is StateChart:
		_state_chart = root
		return true

	# no luck, search the children
	for child in root.get_children():
		if _debug_node(child):
			# found one, return			
			return true

	# no luck, return false
	return false


func _setup_processing(enabled:bool):
	process_mode = Node.PROCESS_MODE_ALWAYS if enabled else Node.PROCESS_MODE_DISABLED
	visible = enabled


## Disconnects all signals from the currently connected states.
func _disconnect_all_signals():
	if is_instance_valid(_state_chart):
		if not ignore_events:
			_state_chart.event_received.disconnect(_on_event_received)
	
	for state in _connected_states:
		# in case the state has been destroyed meanwhile
		if is_instance_valid(state):
			state.state_entered.disconnect(_on_state_entered)
			state.state_exited.disconnect(_on_state_exited)

	for transition in _connected_transitions.keys():
		# in case the transition has been destroyed meanwhile
		if is_instance_valid(transition):
			transition.taken.disconnect(_connected_transitions.get(transition))



## Connects all signals from the currently processing state chart
func _connect_all_signals():
	_connected_states.clear()
	_connected_transitions.clear()

	if not is_instance_valid(_state_chart):
		return

	_state_chart.event_received.connect(_on_event_received)

	# find all state nodes below the state chart and connect their signals
	for child in _state_chart.get_children():
		if child is StateChartState:
			_connect_signals(child)


func _connect_signals(state:StateChartState):
	state.state_entered.connect(_on_state_entered.bind(state))
	state.state_exited.connect(_on_state_exited.bind(state))
	_connected_states.append(state)

	# recurse into children
	for child in state.get_children():
		if child is StateChartState:
			_connect_signals(child)
		if child is Transition:
			var callable = _on_before_transition.bind(child, state)
			child.taken.connect(callable)
			_connected_transitions[child] = callable


func _process(delta):
	# Clear contents
	_tree.clear()

	if not is_instance_valid(_state_chart):
		return

	var root = _tree.create_item()
	root.set_text(0, _root.name)

	# walk over the state chart and find all active states
	_collect_active_states(_state_chart, root )
	
	# also show the values of all variables
	var items = _state_chart._expression_properties.keys()
	
	if items.size() <= 0:
		return # nothing to show
	
	# sort by name so it doesn't flicker all the time
	items.sort()
	
	var properties_root = root.create_child()
	properties_root.set_text(0, "< Expression properties >")
	
	for item in items:
		var value = str(_state_chart._expression_properties.get(item))
		
		var property_line = properties_root.create_child()
		property_line.set_text(0, "%s = %s" % [item, value])
	

func _collect_active_states(root:Node, parent:TreeItem):
	for child in root.get_children():
		if child is StateChartState:
			if child.active:
				var state_item:TreeItem = _tree.create_item(parent)
				state_item.set_text(0, child.name)

				if is_instance_valid(child._pending_transition):
					var transition_item: TreeItem = state_item.create_child()
					transition_item.set_text(0, ">> %s (%.2f)" % [child._pending_transition.name, child._pending_transition_remaining_delay])

				_collect_active_states(child, state_item)


func _clear_history():
	_history_edit.text = ""
	_history.clear()

func _on_before_transition(transition:Transition, source:StateChartState):
	if ignore_transitions:
		return

	_history.add_transition(Engine.get_process_frames(), transition.name, _state_chart.get_path_to(source), _state_chart.get_path_to(transition.resolve_target()))


func _on_event_received(event:StringName):
	if ignore_events:
		return

	_history.add_event(Engine.get_process_frames(), event)	

	
func _on_state_entered(state:StateChartState):
	if ignore_state_changes:
		return
		
	_history.add_state_entered(Engine.get_process_frames(), state.name)


func _on_state_exited(state:StateChartState):
	if ignore_state_changes:
		return
		
	_history.add_state_exited(Engine.get_process_frames(), state.name)


func _on_timer_timeout():
	# ignore the timer if the history edit isn't visible
	if not _history_edit.visible or not _history.dirty:
		return 
	
	# fill the history field
	_history_edit.text = _history.get_history_text()
	_history_edit.scroll_vertical = _history_edit.get_line_count() - 1


func _on_ignore_events_checkbox_toggled(button_pressed):
	ignore_events = button_pressed


func _on_ignore_state_changes_checkbox_toggled(button_pressed):
	ignore_state_changes = button_pressed

func _on_ignore_transitions_checkbox_toggled(button_pressed):
	ignore_transitions = button_pressed
