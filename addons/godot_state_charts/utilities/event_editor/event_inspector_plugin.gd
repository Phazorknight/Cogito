@tool
extends EditorInspectorPlugin

const EventEditor = preload("event_editor.gd")

var _undo_redo:EditorUndoRedoManager


func setup(undo_redo:EditorUndoRedoManager):
	_undo_redo = undo_redo


func _can_handle(_object):
	# We support all objects in this example.
	return true


func _parse_property(object, type, name, _hint_type, _hint_string, _usage_flags, _wide):
	# We handle properties of type integer.
	if object is Transition and name == "event" and type == TYPE_STRING_NAME:
		# Create an instance of the custom property editor and register
		# it to a specific property path.
		var editor = EventEditor.new(object as Transition, _undo_redo)
		add_property_editor(name, editor)
		# Inform the editor to remove the default property editor for
		# this property type.
		return true
	else:
		return false
