extends Control
class_name UiObjectNameComponent

@onready var object_name_text: RichTextLabel = $HBoxContainer/ObjectNameText

func set_object_name(object_name:String):
	object_name_text.text = object_name


func discard_prompt():
	#await get_tree().create_timer(.1).timeout
	queue_free()
