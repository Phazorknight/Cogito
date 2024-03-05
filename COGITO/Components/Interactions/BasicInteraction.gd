extends InteractionComponent

@onready var parent_node = get_parent() #Grabbing reference to door

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent_node.object_state_updated.connect(_on_object_state_change)


func interact(_player_interaction_component):
	parent_node.interact(_player_interaction_component)


func _on_object_state_change(_interaction_text: String):
	interaction_text = _interaction_text
