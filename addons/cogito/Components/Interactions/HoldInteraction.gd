class_name HoldInteraction
extends InteractionComponent

signal is_being_held(time_left:float)

@export var hold_time : float = 3.0

@onready var parent_node = get_parent() #Grabbing reference to door

var player_interaction_component

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if parent_node.has_signal("object_state_updated"):
		parent_node.object_state_updated.connect(_on_object_state_change)


func interact(_player_interaction_component):
	was_interacted_with.emit(interaction_text, input_map_action)
	player_interaction_component = _player_interaction_component
	
	var hud_path := NodePath(_player_interaction_component.player.player_hud)
	var hud = _player_interaction_component.player.get_node(hud_path) as CogitoPlayerHudManager
	if !hud.hold_ui.is_holding:
		hud.hold_ui.start_holding(self)


func _on_object_state_change(_interaction_text: String):
	interaction_text = _interaction_text
