extends Control
class_name QuestEntry

@onready var quest_name_label: Label = $VBoxContainer/QuestName
@onready var quest_description_label: Label = $VBoxContainer/QuestDescription
@onready var quest_counter_label: Label = $VBoxContainer/QuestCounter

func set_quest_info(_passed_quest_name:String, _passed_quest_description:String, _passed_quest_counter:String):
	quest_name_label.text = _passed_quest_name
	quest_description_label.text = _passed_quest_description
	
	if _passed_quest_counter == "0/0":
		quest_counter_label.text = ""
	else:
		quest_counter_label.text = _passed_quest_counter
	
	
