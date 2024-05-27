extends Node
class_name CogitoQuestGroup


var quests: Array[CogitoQuest] = []

func _init(pool_name: String):
	self.set_name(pool_name)


func add_quest(quest: CogitoQuest) -> CogitoQuest:
	assert(quest != null)
	quests.append(quest)
	return quest
	

func remove_quest(quest: CogitoQuest) -> CogitoQuest:
	assert(quest != null)
	quests.erase(quest)
	return quest 


func is_quest_inside(quest: CogitoQuest) -> bool:
	return quest in quests


func get_quest_from_id(id: int) -> CogitoQuest:
	for quest in quests:
		if quest.id == id:
			return quest
	return null
	

func get_ids_from_quests() -> Array[int]:
	var ids: Array[int] = []
	for quest in quests:
		ids.append(quest.id)
	return ids


func clear_group():
	quests.clear() 
