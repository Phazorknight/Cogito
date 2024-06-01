extends InteractionComponent
# Interaction to use with Nagi's Dialogue Nodes Addon for Godot Engine 4 (look for Dialogue Nodes on the AssetLib)
# Installation Instructions:
# 1. Install Dialogue Nodes from the AssetLib
# 2. Uncomment everything below the dotted lines (Ctrl + K)
# 3. Add the $DialogueBubble node to the DialogueNodesInteraction.tscn
# ............................................................................

#@export var dialogue_data : DialogueData
#@onready var dialogue_bubble: DialogueBubble = $DialogueBubble
#
#var player_interaction_component : PlayerInteractionComponent
#
#
#func _ready() -> void:
	#dialogue_bubble.data = dialogue_data
#
#
#func interact(_player_interaction_component: PlayerInteractionComponent):
	#player_interaction_component = _player_interaction_component
	#start_dialogue()
#
#
#func start_dialogue():
	#player_interaction_component.get_parent().toggled_interface.emit(true)
	#if !player_interaction_component.get_parent().menu_pressed.is_connected(abort_dialogue):
		#player_interaction_component.get_parent().menu_pressed.connect(abort_dialogue) #Connecting input action menu to close function.
	#if !dialogue_bubble.dialogue_ended.is_connected(stop_dialogue):
		#dialogue_bubble.dialogue_ended.connect(stop_dialogue)
	#dialogue_bubble.start("START")
#
#
#func stop_dialogue():
	#player_interaction_component.get_parent().toggled_interface.emit(false)
#
#
#func abort_dialogue():
	#dialogue_bubble.stop()
	#stop_dialogue()
