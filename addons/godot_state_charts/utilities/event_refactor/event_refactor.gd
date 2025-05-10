@tool

extends ConfirmationDialog

const StateChartUtil = preload("../state_chart_util.gd")

@onready var _event_list:ItemList = %EventList
@onready var _event_name_edit:LineEdit = %EventNameEdit

var _chart:StateChart
var _undo_redo:EditorUndoRedoManager
var _current_event_name:StringName = ""

func open(chart:StateChart, undo_redo:EditorUndoRedoManager):
	title = "Events of " + chart.name
	_chart = chart
	_refresh_events()
	_undo_redo = undo_redo


func _refresh_events():
	_event_list.clear()
	for item in StateChartUtil.events_of(_chart):
		_event_list.add_item(item)

func _close():
	hide()
	queue_free()


func _on_event_list_item_selected(index:int):
	_current_event_name = _event_list.get_item_text(index)
	_event_name_edit.text = _current_event_name
	_on_event_name_edit_text_changed(_current_event_name)

	
func _on_event_name_edit_text_changed(new_text):
	# disable rename button if the event name is the same as the 
	# currently selected event
	get_ok_button().disabled = new_text == _current_event_name		


func _on_confirmed():
	var new_event_name = _event_name_edit.text
	var transitions = StateChartUtil.transitions_of(_chart)
	_undo_redo.create_action("Rename state chart event")
	for transition in transitions:
		if transition.event == _current_event_name:
			_undo_redo.add_do_property(transition, "event", new_event_name)
			_undo_redo.add_undo_property(transition, "event", _current_event_name)
	_undo_redo.commit_action()
	_close()
