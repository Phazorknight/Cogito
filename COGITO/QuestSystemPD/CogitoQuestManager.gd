extends Node

signal quest_activated(quest: CogitoQuest) #Emitted when a quest gets added to the active quests group
signal quest_updated(quest: CogitoQuest) #Emitted when a quests gets updated (used for the quest counter)
signal quest_completed(quest: CogitoQuest) #Emitted when a quest gets completed / moved to the completed quests group.
signal quest_failed(quest: CogitoQuest) #Emitted when a quest gets moved to the failed quests group.

const AvailableQuests = preload("./QuestGroups/available_quests_group.gd")
const ActiveQuests = preload("./QuestGroups/active_quests_group.gd")
const CompletedQuests = preload("./QuestGroups/completed_quests_group.gd")
const FailedQuests = preload("./QuestGroups/failed_quests_group.gd")

# AUDIO REFERENCES
const COGITO_QUEST_COMPLETE = preload("res://COGITO/Assets/Audio/Phazorknight/Cogito_QuestComplete.wav")
const COGITO_QUEST_FAILED = preload("res://COGITO/Assets/Audio/Phazorknight/Cogito_QuestFailed.wav")
const COGITO_QUEST_START = preload("res://COGITO/Assets/Audio/Phazorknight/Cogito_QuestStart.wav")

var available: AvailableQuests = AvailableQuests.new("Available")
var active: ActiveQuests = ActiveQuests.new("Active")
var completed: CompletedQuests = CompletedQuests.new("Completed")
var failed: FailedQuests = FailedQuests.new("Failed")

var quest_audio_volume_db : float = -9

func _init() -> void:
	# Adding quest groups
	add_child(available)
	add_child(active)
	add_child(completed)
	add_child(failed)


## Starts a given quest by calling its start() method and moving it to the active group
func start_quest(quest: CogitoQuest) -> CogitoQuest:
	assert(quest != null)

	if active.is_quest_inside(quest):
		print("Quest ", quest, " is already active.")
		return quest
	if completed.is_quest_inside(quest):
		print("Quest ", quest, " is already completed.")
		return quest
	if failed.is_quest_inside(quest):
		print("Quest ", quest, " was already failed.")
		return quest	
	

	#Add the quest to the actives quests group
	available.remove_quest(quest)
	active.add_quest(quest)
	quest_activated.emit(quest)

	quest.start()
	Audio.play_sound(COGITO_QUEST_START).volume_db = quest_audio_volume_db
	print("Quest ", quest.quest_name, " has been started.")
	return quest


## Moves a quest to the completed group. Quest needs to be active to be completed.
func complete_quest(quest: CogitoQuest) -> CogitoQuest:
	if not active.is_quest_inside(quest):
		return quest

	if quest.quest_completed == false:
		return quest

	quest.complete()

	active.remove_quest(quest)
	completed.add_quest(quest)

	quest_completed.emit(quest)
	Audio.play_sound(COGITO_QUEST_COMPLETE).volume_db = quest_audio_volume_db
	return quest


## Moves a quest to the completed group. Quest needs to be active to be completed.
func fail_quest(quest: CogitoQuest) -> CogitoQuest:
	if not active.is_quest_inside(quest):
		return quest

	quest.failed()

	active.remove_quest(quest)
	failed.add_quest(quest)

	quest_failed.emit(quest)
	Audio.play_sound(COGITO_QUEST_FAILED).volume_db = quest_audio_volume_db
	return quest


## Changes quest counter value. Quest needs to be active.
func change_quest_counter(quest: CogitoQuest, value_change:int) -> CogitoQuest:
	if not active.is_quest_inside(quest):
		return quest
	
	quest.quest_counter_current += value_change
	quest_updated.emit(quest)
	
	# Checks if counter goal is reached:
	if quest.quest_counter_current == quest.quest_counter_goal:
		print(quest.quest_name, ": Quest coal reached!")
		quest.update()
		complete_quest(quest)
	
	return quest


## Functions to get a list of quests from each group
func get_available_quests() -> Array[CogitoQuest]:
	return available.quests


func get_active_quests() -> Array[CogitoQuest]:
	return active.quests


func get_completed_quests() -> Array[CogitoQuest]:
	return completed.quests


func get_failed_quests() -> Array[CogitoQuest]:
	return failed.quests


## Gets a quest that's neither in the active, completed or failed groups
func is_quest_available(quest: CogitoQuest) -> bool:
	if not (active.is_quest_inside(quest) or completed.is_quest_inside(quest) or failed.is_quest_inside(quest)):
		return true
	return false


## Checks if a quest is currently in the active group.
func is_quest_active(quest: CogitoQuest) -> bool:
	if active.is_quest_inside(quest):
		return true
	return false


## Checks if a quest is currently in the completed group.
func is_quest_completed(quest: CogitoQuest) -> bool:
	if completed.is_quest_inside(quest):
		return true
	return false


## Checks if a quest is in a given group. Given group name string needs to match child node name (as added in _ready)
func is_quest_in_group(quest: CogitoQuest, group_name: String) -> bool:
	if group_name.is_empty():
		for group in get_children():
			if group.is_quest_inside(quest): return true
		return false

	var group := get_node(group_name)
	if group.is_quest_inside(quest): return true
	return false


func call_quest_method(quest_id: int, method: String, args: Array) -> void:
	var quest: CogitoQuest = null

	# Find the quest if present
	for pools in get_children():
		if pools.get_quest_from_id(quest_id) != null:
			quest = pools.get_quest_from_id(quest_id)
			break

	# Make sure we've got the quest
	if quest == null: return

	if quest.has_method(method):
		quest.callv(method, args)


func set_quest_property(quest_id: int, property: String, value: Variant) -> void:
	var quest: CogitoQuest = null

	# Find the quest
	for groups in get_children():
		if groups.get_quest_from_id(quest_id) != null:
			quest = groups.get_quest_from_id(quest_id)

	if quest == null: return

	# Now check if the quest has the property

	# First if the property is null -> we return
	if property == null: return

	var was_property_found: bool = false
	# Then we check if the property is present
	for p in quest.get_property_list():
		if p.name == property:
			was_property_found = true
			break

	# Return if the property was not found
	if not was_property_found: return

	# Finally we set the value
	quest.set(property, value)


## Force moves a quest to a group.
func move_quest_to_group(quest: CogitoQuest, old_group: String, new_group: String) -> CogitoQuest:
	if old_group == new_group: return

	var old_group_instance: CogitoQuestGroup = get_node_or_null(old_group)
	var new_group_instance: CogitoQuestGroup = get_node_or_null(new_group)

	assert(old_group_instance != null or new_group_instance != null)

	old_group_instance.quests.erase(quest)
	new_group_instance.quests.append(quest)

	return quest


## Clears a group. Given group name string needs to match child node name (as added in _ready)
func reset_group(group_name: String) -> void:
	if group_name.is_empty():
		for group in get_children():
			group.reset()
		return

	var group := get_node(group_name)
	group.clear_group()
	return


## Extra QuestManager methods that are currently not really needed.
#func quests_as_dict() -> Dictionary:
	#var quest_dict: Dictionary = {}
#
	#for group in get_children():
		#quest_dict[group.name.to_lower()] = group.get_ids_from_quests()
#
	#return quest_dict
#
#
#func dict_to_quests(dict: Dictionary, quests: Array[CogitoQuest]) -> void:
	#for group in get_children():
#
		## Make sure to iterate only for available pools
		#if !dict.has(group.name.to_lower()): continue
#
		## Match quest with their ids and insert them into the quest pool
		#var quest_with_id: Dictionary = {}
		#var group_ids: Array[int]
		#group_ids.append_array(dict[group.name.to_lower()])
		#for quest in quests:
			#if quest.id in group_ids:
				#group.add_quest(quest)
				#quests.erase(quest)
#
#
#func serialize_quests(group: String) -> Dictionary:
	#var group_node: CogitoQuestGroup = get_node_or_null(group)
#
	#if group_node == null: return {}
#
	#var quest_dictionary: Dictionary = {}
	#for quests in group_node.quests:
		#var quest_data: Dictionary
		#for name in quests.get_script().get_script_property_list():
#
			## Filter only defined properties
			#if name.usage & PROPERTY_USAGE_STORAGE or name.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				#quest_data[name["name"]] = quests.get(name["name"])
#
		#quest_data.erase("id")
		#quest_dictionary[quests.id] = quest_data
#
	#return quest_dictionary
