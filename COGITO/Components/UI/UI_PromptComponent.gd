extends Control
class_name UiPromptComponent

@onready var interaction_button: Node = $HBoxContainer/Container/InteractionButton
@onready var interaction_text: Label = $HBoxContainer/InteractionText

func set_prompt(interaction_name:String,input_map_name:String):
	interaction_button.action_name = input_map_name
	interaction_text.text = interaction_name
	interaction_button.update_input_icon()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(interaction_button.action_name):
		self_modulate = Color(0.059, 0.533, 0.482, 1.0)
	if event.is_action_released(interaction_button.action_name):
		self_modulate = Color.WHITE

func discard_prompt():
	#await get_tree().create_timer(.1).timeout
	queue_free()
