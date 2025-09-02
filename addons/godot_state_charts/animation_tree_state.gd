@tool
@icon("animation_tree_state.svg")
class_name AnimationTreeState
extends AtomicState


## Animation tree that this state will use.
@export_node_path("AnimationTree") var animation_tree:NodePath:
	set(value):
		animation_tree = value
		update_configuration_warnings()

## The name of the state that should be activated in the animation tree
## when this state is entered. If this is empty, the name of this state
## will be used.
@export var state_name:StringName = ""


var _animation_tree_state_machine:AnimationNodeStateMachinePlayback

func _ready():
	if Engine.is_editor_hint():
		return
		
	super._ready()
	
	_animation_tree_state_machine = null
	var the_tree = get_node_or_null(animation_tree)

	if is_instance_valid(the_tree):
		var state_machine = the_tree.get("parameters/playback") 
		if state_machine is AnimationNodeStateMachinePlayback:
			_animation_tree_state_machine = state_machine
		else:
			push_error("The animation tree does not have a state machine as root node. This node will not work.")
	else:
		push_error("The animation tree is invalid. This node will not work.")


func _state_enter(transition_target:StateChartState):
	super._state_enter(transition_target)

	if not is_instance_valid(_animation_tree_state_machine):
		return

	var target_state = state_name
	if target_state == "":
		target_state = get_name()

	# mirror this state to the animation tree
	_animation_tree_state_machine.travel(target_state)


func _get_configuration_warnings():
	var warnings = super._get_configuration_warnings()
	warnings.append("This node is deprecated and will be removed in a future version.")

	if animation_tree.is_empty():
		warnings.append("No animation tree is set.")
	elif get_node_or_null(animation_tree) == null:
		warnings.append("The animation tree path is invalid.")

	return warnings
