extends Resource
class_name CogitoQuest

## ID number. Should be unique for each quest.
@export var id: int
## String name. Should have no spaces or special characters something like "level_quest01_a")
@export var quest_name: String
## Quest title as it will be displayed in game.
@export var quest_title : String
## Quest description when this quest is active.
@export_multiline var quest_description_active: String
## Quest description when this quest was completed successfully.
@export_multiline var quest_description_completed: String = "You completed this quest."
## Quest description when this quest was failed.
@export_multiline var quest_description_failed: String = "You failed this quest."
@export var quest_counter_current : int = 0
@export var quest_counter_goal : int

var quest_description : String

var quest_completed : bool = false:
	set(value):
		quest_completed = value
	get:
		return quest_completed


var quest_counter : int:
	set(value):
		quest_counter = value
	get:
		return quest_counter


func start():
	quest_description = quest_description_active


func update() -> void:
	quest_completed = true


func complete():
	quest_description = quest_description_completed
	

func failed():
	quest_description = quest_description_failed
