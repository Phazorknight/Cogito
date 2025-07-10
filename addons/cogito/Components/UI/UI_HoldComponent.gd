class_name UiHoldComponent
extends Control

## Buffer time until the hold is first registered, prevents showing Hold UI for presses
@export var buffer_time : float = 0.1  

@onready var progress_wheel: CogitoProgressWheel = $ProgressWheel
@onready var hold_timer: Timer = $HoldTimer

var hold_interaction: HoldInteraction
var is_holding : bool = false
var player_interaction_component


func _ready() -> void:
	hide()
	progress_wheel.current_value = 0.0
	hold_timer.timeout.connect(_on_hold_complete)
	await get_tree().process_frame
	player_interaction_component = (CogitoSceneManager._current_player_node as CogitoPlayer).player_interaction_component


func _process(_delta: float) -> void:
	if is_holding and hold_interaction:
		if hold_timer.time_left  < hold_timer.wait_time-buffer_time:
			show()
		hold_interaction.is_being_held.emit(hold_timer.time_left)
		progress_wheel.current_value = 1 - (hold_timer.time_left / hold_interaction.hold_time)
		
		var interaction_distance = (hold_interaction.parent_node.global_position - player_interaction_component.global_position).length()
		if interaction_distance >= player_interaction_component.interaction_raycast.target_position.length() :
			stop_holding()
	elif hold_interaction:
		stop_holding()


func _input(event):
	if is_holding and event.is_action_released(hold_interaction.input_map_action):
		if hold_interaction is DualInteraction:
			hold_interaction.on_quick_press.emit(player_interaction_component)
		if hold_interaction is ExtendedPickupInteraction:
			# Pick up the item on early release, using the PickupComponent
			hold_interaction.pickup.is_disabled = false
			hold_interaction.pickup.interact(player_interaction_component)
			if hold_interaction != null: # The pickup failed if it's components still exist
				hold_interaction.pickup.is_disabled = true
			
		stop_holding()


func _on_hold_complete():
	# Important for HoldInteraction to be a base HoldInteraction, not a subclass, to work
	if hold_interaction is not DualInteraction and hold_interaction is not ExtendedPickupInteraction:
		hold_interaction.parent_node.interact(player_interaction_component)
	elif hold_interaction is DualInteraction:
		hold_interaction.on_hold_complete.emit(player_interaction_component)
	elif hold_interaction is ExtendedPickupInteraction:
		hold_interaction.use()
	stop_holding()


func start_holding(_hold_interaction: HoldInteraction) -> void:
	if !is_holding:
		is_holding = true
		hold_interaction = _hold_interaction
		hold_timer.wait_time = hold_interaction.hold_time
		progress_wheel.current_value = 1 - (hold_timer.time_left / hold_interaction.hold_time)
		hold_timer.start()
		hold_interaction = _hold_interaction
		player_interaction_component.player.is_movement_paused = true


func stop_holding() -> void:
	hold_timer.stop()
	hide()
	is_holding = false
	hold_interaction = null
	progress_wheel.current_value = 0.0
	player_interaction_component.player.is_movement_paused = false
