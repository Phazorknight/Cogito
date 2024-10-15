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
@export var rich_text : bool
var is_open : bool


func _ready():
	readable_ui.hide()
	is_open = false
	label_title.text = readable_title
	if rich_text:
		label_content.bbcode_enabled = true
		label_content.bbcode_text = readable_content
	else: 
		label_content.text = readable_content
	

func interact(_player_interaction_component: PlayerInteractionComponent):
	Audio.play_sound_3d(interact_sound).global_position = self.global_position
	
	if is_open:
		close(_player_interaction_component)
	else:
		open(_player_interaction_component)


func open(_player_interaction_component: PlayerInteractionComponent):
	_player_interaction_component.get_parent().toggled_interface.emit(true)
	_player_interaction_component.get_parent().menu_pressed.connect(close) #Connecting input action menu to close function.
	readable_ui.show()
	has_been_read.emit()
	is_open = true


func close(_player_interaction_component: PlayerInteractionComponent):
	readable_ui.hide()
	_player_interaction_component.get_parent().menu_pressed.disconnect(close)
	is_open = false
	_player_interaction_component.get_parent().toggled_interface.emit(false)
