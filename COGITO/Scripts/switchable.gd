extends Node3D

@onready var audio_stream_player_3d = $AudioStreamPlayer3D

## Sets if object starts as on or off.
@export var is_on : bool = false
@export var interaction_text_when_on : String = "Switch off"
@export var interaction_text_when_off : String = "Switch on"
## Sound that plays when switched.
@export var switch_sound : AudioStream
## Typed Array of NodePaths. Drag the objects you want switched in here from your scene hierarchy. Their visibility will be flipped when switched. This means you have to set them to the correct starting visibility.
@export var objects_to_switch : Array[NodePath]

var interaction_text : String 

func _ready():
	audio_stream_player_3d.stream = switch_sound
	
	if is_on:
		interaction_text = interaction_text_when_on
	else:
		interaction_text = interaction_text_when_off

func interact(_player):
	audio_stream_player_3d.play()
	switch()

func switch():
	is_on = !is_on
	
	for nodepath in objects_to_switch:
		if nodepath != null:
			var object = get_node(nodepath)
			object.visible = !object.visible
	
	if is_on:
		interaction_text = interaction_text_when_on
	else:
		interaction_text = interaction_text_when_off
