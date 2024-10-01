extends InteractionComponent

@onready var parent_node = get_parent() #Grabbing reference to parent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if parent_node.has_signal("lock_state_updated"):
		parent_node.lock_state_updated.connect(_lock_state_updated)

func interact(_player_interaction_component):
	if check_for_key(_player_interaction_component):
		if parent_node.has_method("interact2"):
			parent_node.interact2(_player_interaction_component)
		
		was_interacted_with.emit(interaction_text,input_map_action)
	else:
		_player_interaction_component.send_hint(null,parent_node.key_hint)

func _lock_state_updated(lock_interaction_text: String):
	interaction_text = lock_interaction_text

func check_for_key(interactor) -> bool:
	var inventory = interactor.get_parent().inventory_data
	for slot_data in inventory.inventory_slots:
		if slot_data != null and slot_data.inventory_item == parent_node.key:
			return true
	return false

##Used for dual interaction component. This function checks keys presence before allowing a hold to start.
func start_hold_check(interactor) -> bool:
	var keyResult: bool = check_for_key(interactor)
	return keyResult
