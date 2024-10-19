extends InteractionComponent

@onready var parent_node = get_parent() #Grabbing reference to parent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if parent_node.has_signal("lock_state_updated"):
		parent_node.lock_state_updated.connect(_lock_state_updated)

func interact(_player_interaction_component):
	if check_for_item(_player_interaction_component, parent_node.key):
		if parent_node.has_method("interact2"):
			parent_node.interact2(_player_interaction_component)
		was_interacted_with.emit(interaction_text, input_map_action)
	elif check_for_item(_player_interaction_component, parent_node.lockpick):
			if parent_node.has_method("interact2"):
				parent_node.interact2(_player_interaction_component)
			was_interacted_with.emit(interaction_text, input_map_action)
			#start_lockpick(_player_interaction_component)
	else:
		_player_interaction_component.send_hint(null, parent_node.key_hint)
		
func _lock_state_updated(lock_interaction_text: String):
	interaction_text = lock_interaction_text

func check_for_item(interactor, item) -> bool:
	var inventory = interactor.get_parent().inventory_data
	for slot_data in inventory.inventory_slots:
		if slot_data != null and slot_data.inventory_item == item:
			if slot_data.inventory_item.has_method("discard_after_use"):
				if slot_data.inventory_item.discard_after_use:
					inventory.remove_item_from_stack(slot_data)
			return true
	return false

#func start_lockpick(_player_interaction_component):
	#Lockpick UI/Minigame can be initiated here
	#pass
	
##Used for dual interaction component. This function checks keys presence before allowing a hold to start.
func start_hold_check(interactor) -> bool:
	var keyResult: bool = check_for_item(interactor, parent_node.key)#
	var lockpickResult: bool = check_for_item(interactor, parent_node.lockpick)
	
	if keyResult or lockpickResult == true:
		return true
	else:
		return false
