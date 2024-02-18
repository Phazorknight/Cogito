extends Resource
class_name CogitoQuest

@export var id: int
@export var quest_name: String
@export var quest_title : String
@export_multiline var quest_description: String
@export var quest_counter_current : int = 0
@export var quest_counter_goal : int

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
	pass


func update() -> void:
	quest_completed = true


func complete():
	pass
	

func failed():
	pass
