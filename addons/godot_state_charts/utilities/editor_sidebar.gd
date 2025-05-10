@tool
extends Control

## Emitted when the user requests to toggle the sidebar.
signal sidebar_toggle_requested()

## The currently selected node or null
var _selected_node:Node
## The editor interface
var _editor_interface:EditorInterface
## The undo/redo facility
var _undo_redo:EditorUndoRedoManager

@onready var _add_section:Control = %AddSection
@onready var _no_options_label:Control = %NoOptionsLabel
@onready var _add_node_name_line_edit:LineEdit = %AddNodeNameLineEdit
@onready var _add_grid_container:Control = %AddGridContainer


func setup(editor_interface:EditorInterface, undo_redo:EditorUndoRedoManager):
	_editor_interface = editor_interface
	_undo_redo = undo_redo


func change_selected_node(node):
	_selected_node = node
	_repaint()

func _repaint():
	# we can add states to all composite states and to the 
	# root if the root has no child state yet.
	var can_add_states = \
		( _selected_node is StateChart and _selected_node.get_child_count() == 0 ) \
		or _selected_node is ParallelState \
		or _selected_node is CompoundState
		
	# we can add transitions to all states
	var can_add_transitions = \
		_selected_node is StateChartState
		
	_add_section.visible = can_add_states or can_add_transitions
	_no_options_label.visible = not (can_add_states or can_add_transitions)
	
	
	for btn in _add_grid_container.get_children():
		if btn.is_in_group("statebutton"):
			btn.visible = can_add_states
		else:
			btn.visible = can_add_transitions


func _create_node(type, name:StringName):
	
	var final_name = _add_node_name_line_edit.text.strip_edges()
	if final_name.length() == 0:
		final_name = name
	
	var new_node = type.new()
	_undo_redo.create_action("Add " + final_name)
	_undo_redo.add_do_method(_selected_node, "add_child", new_node)
	_undo_redo.add_undo_method(_selected_node, "remove_child", new_node)
	_undo_redo.add_do_reference(new_node)
	_undo_redo.add_do_method(new_node, "set_owner", _selected_node.get_tree().edited_scene_root)
	_undo_redo.add_do_property(new_node, "name", final_name)
	_undo_redo.commit_action()
		
	
	if Input.is_key_pressed(KEY_SHIFT):
		_editor_interface.get_selection().clear()
		_editor_interface.get_selection().add_node(new_node)

	_add_node_name_line_edit.grab_focus()
	_editor_interface.edit_node(new_node)
	_repaint()
		


func _on_atomic_state_pressed():
	_create_node(AtomicState, "AtomicState")


func _on_compound_state_pressed():
	_create_node(CompoundState, "CompoundState")


func _on_parallel_state_pressed():
	_create_node(ParallelState, "ParallelState")


func _on_history_state_pressed():
	_create_node(HistoryState, "HistoryState")


func _on_transition_pressed():
	_create_node(Transition, "Transition")


func _on_toggle_sidebar_button_pressed():
	sidebar_toggle_requested.emit()
