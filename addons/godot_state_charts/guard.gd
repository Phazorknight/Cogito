@icon("guard.svg")
class_name Guard
extends Resource

## Returns true if the guard is satisfied, false otherwise.
func is_satisfied(context_transition:Transition, context_state:StateChartState) -> bool:
	push_error("Guard.is_satisfied() is not implemented. Did you forget to override it?")
	return false

## Returns the triggers which should trigger the guard's evaluation. This is a bit mask of [StateChart.TriggerType].
func get_supported_trigger_types() -> int:
	push_error("Guard._get_supported_trigger_types() is not implemented. Did you forget to override it?")
	return StateChart.TriggerType.NONE
