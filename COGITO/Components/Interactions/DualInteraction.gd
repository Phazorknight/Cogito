class_name DualInteraction
extends InteractionComponent

signal is_being_held(time_left:float)

signal on_quick_press(player_interaction_component:PlayerInteractionComponent)
signal on_hold_complete(player_interaction_component:PlayerInteractionComponent)

##Time for hold to complete
@export var hold_time : float = 3.0
## Buffer time until the hold is first registered, prevents showing Hold UI for presses
@export var buffer_time : float = 0.1  
##Should a key check run before hold interaction begins? 
@export var hold_key_check : bool = false

@onready var press_interaction_text: String
@onready var hold_interaction_text: String
##Text that joins Press and Hold interaction text, for example:   " | (HOLD) " in  "Open | (HOLD) Unlock"
@export var interaction_text_joiner: String = " | (HOLD) "

@onready var parent_node = get_parent() #Grabbing reference to door
@onready var hold_timer: Timer = $HoldTimer
@onready var hold_ui: Control = $HoldUi
@onready var progress_bar: ProgressBar = $HoldUi/ProgressBar


var is_holding : bool = false
var player_interaction_component



func _ready() -> void:
	if parent_node.has_signal("object_state_updated"):
		parent_node.object_state_updated.connect(_on_object_state_change)
	if parent_node.has_signal("lock_state_updated"):
		parent_node.lock_state_updated.connect(_lock_state_updated)
	
	hold_ui.hide()
	hold_timer.timeout.connect(_on_hold_complete)
	hold_timer.wait_time = hold_time
	progress_bar.value = hold_timer.time_left / hold_time * 100


func interact(_player_interaction_component):
	was_interacted_with.emit(interaction_text,input_map_action)
	player_interaction_component = _player_interaction_component
	check_before_hold_start(_player_interaction_component)

#Runs check before allowing hold to start, currently used to stop lock/unlock interaction if key not present.
func check_before_hold_start(_player_interaction_component):
	if !hold_key_check:
		if !is_holding:
			is_holding = true
			hold_timer.start()
	elif check_for_key(_player_interaction_component):
		if !is_holding:
			is_holding = true
			hold_timer.start()
	else:
		parent_node.door_rattle(_player_interaction_component)

func _on_object_state_change(_interaction_text: String):
	press_interaction_text = _interaction_text
	update_interaction_text()
	
func _lock_state_updated(lock_interaction_text: String):
	hold_interaction_text = lock_interaction_text
	update_interaction_text()

func update_interaction_text():
	interaction_text = press_interaction_text + interaction_text_joiner + hold_interaction_text
	
func _process(_delta: float) -> void:
	if is_holding:
		if hold_timer.time_left  < hold_timer.wait_time-buffer_time:
			hold_ui.show()
		is_being_held.emit(hold_timer.time_left)
		progress_bar.value = hold_timer.time_left / hold_time * 100
		
		var interaction_distance = (parent_node.global_position - player_interaction_component.global_position).length()
		if interaction_distance >= player_interaction_component.interaction_raycast.target_position.length() :
			hold_timer.stop()
			hold_ui.hide()
			is_holding = false

func _input(event):
	if is_holding and event.is_action_released(input_map_action):
		hold_timer.stop()
		hold_ui.hide()
		is_holding = false
		on_quick_press.emit(player_interaction_component)
		
func check_for_key(interactor) -> bool:
	var inventory = interactor.get_parent().inventory_data
	for slot_data in inventory.inventory_slots:
		if slot_data != null and slot_data.inventory_item == parent_node.key:
			return true
	return false

func _on_hold_complete():
	hold_timer.stop()
	hold_ui.hide()
	is_holding = false
	on_hold_complete.emit(player_interaction_component)
