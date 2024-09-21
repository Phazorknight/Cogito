extends InteractionComponent
# Interaction to use with Dialogic Addon for Godot Engine 4
# Installation Instructions:
# 1. Install Dialogic
# 2. Uncomment everything below the dotted lines (Ctrl + K)
# 3. Add the DialogicInteraction component to your object and assing the correct dialogic timeline.
# ............................................................................

#@export var dialogic_timeline : DialogicTimeline
##@onready var dialogue_bubble: DialogueBubble = $DialogueBubble
#
#var player_interaction_component : PlayerInteractionComponent
#
#
#func _ready() -> void:
	##dialogue_bubble.data = dialogue_data
	#pass
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
	#if !Dialogic.timeline_ended.is_connected(stop_dialogue):
		#Dialogic.timeline_ended.connect(stop_dialogue)
	#Dialogic.start(dialogic_timeline)
#
#
#func stop_dialogue():
	#player_interaction_component.get_parent().toggled_interface.emit(false)
#
#
#func abort_dialogue():
	#Dialogic.end_timeline()
	#stop_dialogue()
