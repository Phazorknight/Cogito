extends InteractionComponent
class_name ReadableComponent

signal has_been_read

@onready var label_title: Label = $ReadableUi/Bindings/ScrollContainer/VBoxContainer/ReadableTitle
@onready var label_content: RichTextLabel = $ReadableUi/Bindings/ScrollContainer/VBoxContainer/ReadableContent
@onready var readable_ui: Control = $ReadableUi

@export_group("Readable Settings")
@export var interact_sound : AudioStream
@export var readable_title : String
@export_multiline var readable_content : String

var is_open : bool

func _ready():
	readable_ui.hide()
	is_open = false
	label_title.text = readable_title
	label_content.text = readable_content
 

func interact(_player_interaction_component):
	
	Audio.play_sound_3d(interact_sound).global_position = self.global_position
	
	if is_open:
		readable_ui.hide()
		_player_interaction_component.get_parent()._on_resume_movement()
		is_open = false
	else:
		_player_interaction_component.get_parent()._on_pause_movement()
		readable_ui.show()
		has_been_read.emit()
		is_open = true
