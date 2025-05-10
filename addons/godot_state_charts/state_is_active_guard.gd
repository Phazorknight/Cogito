@tool
@icon("state_is_active_guard.svg")
## A guard that checks if a certain state is active.
class_name StateIsActiveGuard
extends Guard

const DebugUtil = preload("debug_util.gd")

## The state to be checked. When null this guard will return false.
@export_node_path("StateChartState") var state: NodePath

func is_satisfied(context_transition:Transition, context_state:StateChartState) -> bool:
	## resolve the state, relative to the transition
	var actual_state := context_transition.get_node_or_null(state)
	
	if actual_state == null:
		push_warning("State ", state , " referenced in StateIsActiveGuard below ", DebugUtil.path_of(context_state), " could not be resolved. Verify that the node path is correct.")
		return false
	return actual_state.active
	
func get_supported_trigger_types() -> int:
	return StateChart.TriggerType.STATE_CHANGE
