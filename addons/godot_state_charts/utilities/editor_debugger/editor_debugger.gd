## UI for the in-editor state debugger
@tool
extends Control

## Utility class for holding state info
const DebuggerStateInfo = preload("editor_debugger_state_info.gd")
## Debugger history wrapper. Shared with in-game debugger.
const DebuggerHistory = preload("../debugger_history.gd")
## The debugger message
const DebuggerMessage = preload("editor_debugger_message.gd")
## The settings propapagor
const SettingsPropagator = preload("editor_debugger_settings_propagator.gd")

## Constants for the settings
const SETTINGS_ROOT:String = "godot_state_charts/debugger/"
const SETTINGS_IGNORE_EVENTS:String = SETTINGS_ROOT + "ignore_events"
const SETTINGS_IGNORE_STATE_CHANGES:String = SETTINGS_ROOT + "ignore_state_changes"
const SETTINGS_IGNORE_TRANSITIONS:String = SETTINGS_ROOT + "ignore_transitions"
const SETTINGS_MAXIMUM_LINES:String = SETTINGS_ROOT + "maximum_lines"
const SETTINGS_SPLIT_OFFSET:String = SETTINGS_ROOT + "split_offset"


## The tree that shows all state charts
@onready var _all_state_charts_tree:Tree = %AllStateChartsTree
## The tree that shows the current state chart
@onready var _current_state_chart_tree:Tree = %CurrentStateChartTree
## The history edit
@onready var _history_edit:TextEdit = %HistoryEdit
## The settings UI
@onready var _ignore_events_checkbox:CheckBox = %IgnoreEventsCheckbox
@onready var _ignore_state_changes_checkbox:CheckBox = %IgnoreStateChangesCheckbox
@onready var _ignore_transitions_checkbox:CheckBox = %IgnoreTransitionsCheckbox
@onready var _maximum_lines_spin_box:SpinBox = %MaximumLinesSpinBox
@onready var _split_container:HSplitContainer = %SplitContainer

## The actual settings
var _ignore_events:bool = true
var _ignore_state_changes:bool = false
var _ignore_transitions:bool = true


## The editor settings for storing all the settings across sessions
var _settings:EditorSettings = null

## The current session (EditorDebuggerSession)
## this does not exist in exported games, so this is deliberately not 
## typed, to avoid compile errors after exporting
var _session = null

## Dictionary of all state charts and their states. Key is the path to the
## state chart, value is a dictionary of states. Key is the path to the state,
## value is the state info (an array).
var _state_infos:Dictionary = {}
## Dictionary of all state charts and their histories. Key is the path to the
## state chart, value is the history.
var _chart_histories:Dictionary = {}
## Path to the currently selected state chart.
var _current_chart:NodePath = ""

## Helper variable for debouncing the maximum lines setting. When
## the value is -1, the setting hasn't been changed yet. When it's
## >= 0, the setting has been changed and the timer is waiting for
## the next timeout to update the setting. The debouncing is done
## in the same function that updates the text edit.
var _debounced_maximum_lines:int = -1

## Initializes the debugger UI using the editor settings.
func initialize(settings:EditorSettings, session:EditorDebuggerSession):
	clear()
	_settings = settings
	_session = session
	
	# restore editor settings
	_ignore_events = _get_setting_or_default(SETTINGS_IGNORE_EVENTS, true)
	_ignore_state_changes = _get_setting_or_default(SETTINGS_IGNORE_STATE_CHANGES, false)
	_ignore_transitions = _get_setting_or_default(SETTINGS_IGNORE_TRANSITIONS, true)

	# initialize UI elements, so they match the settings
	_ignore_events_checkbox.set_pressed_no_signal(_ignore_events)
	_ignore_state_changes_checkbox.set_pressed_no_signal(_ignore_state_changes)
	_ignore_transitions_checkbox.set_pressed_no_signal(_ignore_transitions)
	_maximum_lines_spin_box.value = _get_setting_or_default(SETTINGS_MAXIMUM_LINES, 300)
	_split_container.split_offset =  _get_setting_or_default(SETTINGS_SPLIT_OFFSET, 0)
	
## Returns the given setting or the default value if the setting is not set.
## No clue, why this isn't a built-in function.
func _get_setting_or_default(key, default) -> Variant :
	if _settings == null:
		return default
	
	if not _settings.has_setting(key):
		return default
	
	return _settings.get_setting(key)

## Sets the given setting and marks it as changed.
func _set_setting(key, value) -> void:
	if _settings == null:
		return
	_settings.set_setting(key, value)
	_settings.mark_setting_changed(key)


## Clears all state charts and state trees.
func clear():
	_clear_all()
	

## Clears all state charts and state trees.
func _clear_all():
	_state_infos.clear()
	_chart_histories.clear()
	_all_state_charts_tree.clear()
	
	var root := _all_state_charts_tree.create_item()
	root.set_text(0, "State Charts")
	root.set_selectable(0, false)
	
	_clear_current()

## Clears all data about the current chart from the ui	
func _clear_current():
	_current_chart = ""
	_current_state_chart_tree.clear()
	_history_edit.clear()
	var root := _current_state_chart_tree.create_item()
	root.set_text(0, "States")
	root.set_selectable(0, false)

## Adds a new state chart to the debugger.
func add_chart(path:NodePath):
	_state_infos[path] = {}
	_chart_histories[path] = DebuggerHistory.new()
	
	_repaint_charts()

	# push the settings to the new chart remote
	SettingsPropagator.send_settings_update(_session, path, _ignore_events, _ignore_transitions)

	if _current_chart.is_empty():
		_current_chart = path
		_select_current_chart()


## Removes a state chart from the debugger.
func remove_chart(path:NodePath):
	_state_infos.erase(path)
	if _current_chart == path:
		_clear_current()
	_repaint_charts()
	
## Updates state information for a state chart.
func update_state(_frame:int, state_info:Array) -> void:
	var chart := DebuggerStateInfo.get_chart(state_info)
	var path := DebuggerStateInfo.get_state(state_info)
	
	if not _state_infos.has(chart):
		push_error("Probable bug: Received state info for unknown chart %s" % [chart])
		return
	
	_state_infos[chart][path] = state_info

## Called when a state is entered.
func state_entered(frame:int, chart:NodePath, state:NodePath) -> void:
	if not _state_infos.has(chart):
		return

	if not _ignore_state_changes:
		var history:DebuggerHistory = _chart_histories[chart]
		history.add_state_entered(frame, _get_node_name(state))

	var state_info = _state_infos[chart][state]
	DebuggerStateInfo.set_active(state_info, true)

## Called when a state is exited.
func state_exited(frame:int, chart:NodePath, state:NodePath) -> void:
	if not _state_infos.has(chart):
		return

	if not _ignore_state_changes:
		var history:DebuggerHistory = _chart_histories[chart]
		history.add_state_exited(frame, _get_node_name(state))

	var state_info = _state_infos[chart][state]
	DebuggerStateInfo.set_active(state_info, false)


## Called when an event is received.
func event_received(frame:int, chart:NodePath, event:StringName) -> void:
	var history:DebuggerHistory = _chart_histories.get(chart, null)
	history.add_event(frame, event)

## Called when a transition is pending
func transition_pending(_frame:int, chart:NodePath, state:NodePath, transition:NodePath, pending_time:float) -> void:
	var state_info = _state_infos[chart][state]
	DebuggerStateInfo.set_transition_pending(state_info, transition, pending_time)


func transition_taken(frame:int, chart:NodePath, transition:NodePath, source:NodePath, destination:NodePath) -> void:
	var history:DebuggerHistory = _chart_histories.get(chart, null)
	history.add_transition(frame, _get_node_name(transition), _get_node_name(source), _get_node_name(destination))


## Repaints the tree of all state charts.
func _repaint_charts() -> void:
	for chart in _state_infos.keys():
		_add_to_tree(_all_state_charts_tree, chart, preload("../../state_chart.svg"))
	_clear_unused_items(_all_state_charts_tree.get_root())

	
## Selects the current chart in the main tree.
func _select_current_chart(item:TreeItem = _all_state_charts_tree.get_root()) -> void:
	if item.has_meta("__path") and item.get_meta("__path") == _current_chart:
		_all_state_charts_tree.set_selected(item, 0)
		return
	
	var first_child := item.get_first_child()
	if first_child != null:
		_select_current_chart(first_child)
		
	var next := item.get_next()
	while next != null:
		_select_current_chart(next)
		next = next.get_next()

			
		
## Repaints the tree of the currently selected state chart.
func _repaint_current_chart(force:bool = false) -> void:
	if _current_chart.is_empty():
		return

	# get the history for this chart and update the history text edit
	var history:DebuggerHistory = _chart_histories[_current_chart]
	if history != null and (history.dirty or force):
		_history_edit.text = history.get_history_text()
		_history_edit.scroll_vertical = _history_edit.get_line_count() - 1
	
	# update the tree
	for state_info in _state_infos[_current_chart].values():
		if DebuggerStateInfo.get_active(state_info):
			_add_to_tree(_current_state_chart_tree, DebuggerStateInfo.get_state(state_info), DebuggerStateInfo.get_state_icon(state_info))
		if DebuggerStateInfo.get_transition_pending(state_info):
			var transition_path := DebuggerStateInfo.get_transition_path(state_info)
			var transition_delay := DebuggerStateInfo.get_transition_delay(state_info)
			var name := _get_node_name(transition_path)
			_add_to_tree(_current_state_chart_tree, DebuggerStateInfo.get_transition_path(state_info), preload("../../transition.svg"), "%s (%.1fs)" % [name, transition_delay])	
	_clear_unused_items(_current_state_chart_tree.get_root())


## Walks over the tree and removes all items that are not marked as in use
## removes the "in-use" marker from all remaining items
func _clear_unused_items(root:TreeItem) -> void:	
	if root == null:
		return

	for child in root.get_children():
		if not child.has_meta("__in_use"):
			root.remove_child(child)
			_free_all(child)
		else:
			child.remove_meta("__in_use")
			_clear_unused_items(child)


## Frees this tree item and all its children
func _free_all(root:TreeItem) -> void:
	if root == null:
		return

	for child in root.get_children():
		root.remove_child(child)
		_free_all(child)
		
	root.free()

## Adds an item to the tree. Will re-use existing items if possible.
## The node path will be used as structure for the tree. The created 
## leaf will have the given icon and text.
func _add_to_tree(tree:Tree, path:NodePath, icon:Texture2D, text:String = ""):
	var ref := tree.get_root()
	
	for i in path.get_name_count():
		var segment := path.get_name(i)
		# do we need to add a new child?
		var needs_new := true
		
		if ref != null:
			for child in ref.get_children():
				# re-use child if it exists
				if child.get_text(0) == segment:
					ref = child
					ref.set_meta("__in_use", true)
					needs_new = false
					break
		
		if needs_new:
			ref = tree.create_item(ref)
			ref.set_text(0, segment)
			ref.set_meta("__in_use", true)
			ref.set_selectable(0, false)
			
			
	ref.set_meta("__path", path)
	if text != "":
		ref.set_text(0, text)
	ref.set_icon(0, icon)
	ref.set_selectable(0, true)


## Called when a state chart is selected in the tree.
func _on_all_state_charts_tree_item_selected():
	var item := _all_state_charts_tree.get_selected()
	if item == null:
		return
		
	if not item.has_meta("__path"):
		return
		
	var path = item.get_meta("__path")
	_current_chart = path
	_repaint_current_chart(true)


## Called every 0.5 seconds to update the history text edit and the maximum lines setting.	
func _on_timer_timeout():
	# update the maximum lines setting if it has changed
	if _debounced_maximum_lines >= 0:
		_set_setting(SETTINGS_MAXIMUM_LINES, _debounced_maximum_lines)
		
		# walk over all histories and update their maximum lines
		for history in _chart_histories.values():
			history.set_maximum_lines(_debounced_maximum_lines)
		
		# and reset the debounced value
		_debounced_maximum_lines = -1

	# repaint the current chart
	_repaint_current_chart()

	

## Called when the ignore events checkbox is toggled.
func _on_ignore_events_checkbox_toggled(button_pressed:bool) -> void:
	_ignore_events = button_pressed
	_set_setting(SETTINGS_IGNORE_EVENTS, button_pressed)

	# push the new setting to all remote charts
	for chart in _state_infos.keys():
		SettingsPropagator.send_settings_update(_session, chart, _ignore_events, _ignore_transitions)

## Called when the ignore state changes checkbox is toggled.
func _on_ignore_state_changes_checkbox_toggled(button_pressed:bool) -> void:
	_ignore_state_changes = button_pressed
	_set_setting(SETTINGS_IGNORE_STATE_CHANGES, button_pressed)

## Called when the ignore transitions checkbox is toggled.
func _on_ignore_transitions_checkbox_toggled(button_pressed:bool) -> void:
	_ignore_transitions = button_pressed
	_set_setting(SETTINGS_IGNORE_TRANSITIONS, button_pressed)

	# push the new setting to all remote charts
	for chart in _state_infos.keys():
		SettingsPropagator.send_settings_update(_session, chart, _ignore_events, _ignore_transitions)

## Called when the maximum lines spin box value is changed.
func _on_maximum_lines_spin_box_value_changed(value:int) -> void:
	_debounced_maximum_lines = value

## Called when the split container is dragged.
func _on_split_container_dragged(offset:int) -> void:
	_set_setting(SETTINGS_SPLIT_OFFSET, offset)


## Helper to get the last element of a node path
func _get_node_name(path:NodePath) -> StringName:
	return path.get_name(path.get_name_count() - 1)

## Called when the clear button is pressed.
func _on_clear_button_pressed() -> void:
	_history_edit.text = ""
	if _chart_histories.has(_current_chart):
		var history:DebuggerHistory = _chart_histories[_current_chart]
		history.clear()

## Called when the copy to clipboard button is pressed.
func _on_copy_to_clipboard_button_pressed() -> void:
	DisplayServer.clipboard_set(_history_edit.text)
