extends Control
class_name UiPromptComponent

@onready var interaction_button: Node = $HBoxContainer/Container/InteractionButton
@onready var interaction_text: Label = $HBoxContainer/InteractionText

func set_prompt(interaction_name:String,input_map_name:String):
	interaction_button.action_name = input_map_name
	interaction_text.text = interaction_name
	interaction_button.update_input_icon()
