extends CogitoQuestGroup
class_name ActiveQuestsGroup

func update_quest(quest_id: int) -> void:
	var quest: CogitoQuest = get_quest_from_id(quest_id)

	quest.update()
