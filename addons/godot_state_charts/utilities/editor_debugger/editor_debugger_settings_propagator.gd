@tool
## This node receives messages from the editor debugger and forwards them to the state chart. It
## the reverse of EditorDebuggerMessage.
extends Node

const DebuggerMessage = preload("editor_debugger_message.gd")
const SETTINGS_UPDATED_MESSAGE = DebuggerMessage.MESSAGE_PREFIX + ":scsu"
const NAME = "StateChartEditorRemoteControl"

signal settings_updated(chart:NodePath, ignore_events:bool, ignore_transitions:bool)

static func get_instance(tree:SceneTree):
	# because we add the node deferred, callers in the same frame would not see
	# the node. Therefore we put it as metadata on the tree root. If we set the 
	# minimum to Godot 4.2, we can use a static var for this which will
	# avoid this trickery.
	var result = tree.root.get_meta(NAME) if tree.root.has_meta(NAME) else null
	if not is_instance_valid(result):
		# we want to avoid using class_name to avoid polluting the namespace with
		# classes that are internals. we cannot use preload (cylic dependency)
		# so we have to do this abomination
		result = load("res://addons/godot_state_charts/utilities/editor_debugger/editor_debugger_settings_propagator.gd").new()
		result.name = NAME
		tree.root.set_meta(NAME, result)
		tree.root.add_child.call_deferred(result)
	
	return result

## Sends a settings updated message.
## session is an EditorDebuggerSession but this does not exist after export
## so its not statically typed here. This code won't run after export anyways.
static func send_settings_update(session, chart:NodePath, ignore_events:bool, ignore_transitions:bool) -> void:
	session.send_message(SETTINGS_UPDATED_MESSAGE, [chart, ignore_events, ignore_transitions])


func _enter_tree():	
	# When the node enters the tree, register a message capture to receive
	# settings updates from the editor.
	EngineDebugger.register_message_capture(DebuggerMessage.MESSAGE_PREFIX, _on_settings_updated)


func _exit_tree():
	# When the node exits the tree, shut down the message capture.
	EngineDebugger.unregister_message_capture(DebuggerMessage.MESSAGE_PREFIX)
	


func _on_settings_updated(key:String, data:Array) -> bool:
	# Inform interested parties that
	settings_updated.emit(data[0], data[1], data[2])
	# accept the message
	return true


