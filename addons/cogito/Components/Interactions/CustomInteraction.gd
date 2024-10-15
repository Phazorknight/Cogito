extends InteractionComponent

## String name of the function that will be called when interacted. The player interaction component will be passed.
@export var function_to_call : String = "interact"
@onready var parent_node = get_parent()

func interact(_player_interaction_component):	
	var callable = Callable(parent_node, function_to_call)
	callable.call(_player_interaction_component)
