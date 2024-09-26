extends InteractionComponent

@onready var parent_node = get_parent() #Grabbing reference to parent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if parent_node.has_signal("lock_state_updated"):
		parent_node.lock_state_updated.connect(_lock_state_updated)

func interact(_player_interaction_component):
	if parent_node.has_method("interact2"):
		parent_node.interact2(_player_interaction_component)
	
	was_interacted_with.emit(interaction_text,input_map_action)


func _lock_state_updated(lock_interaction_text: String):
	interaction_text = lock_interaction_text
