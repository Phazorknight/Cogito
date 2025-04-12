extends Node

## If checked, the player will receive notifications when a quest status has changed.
@export var send_quest_notifications : bool
## Reference to how a single quest is displayed in the QuestHUD
@export var quest_entry : PackedScene

@onready var quest_display: PanelContainer = $QuestDisplay

# Quest groups:
@onready var active_group: VBoxContainer = $QuestDisplay/VBoxContainer/TabContainer/Active
@onready var completed_group: VBoxContainer = $QuestDisplay/VBoxContainer/TabContainer/Completed
@onready var failed_group: VBoxContainer = $QuestDisplay/VBoxContainer/TabContainer/Failed

#Reference of main Player HUD.
@export var player_hud  : CogitoPlayerHudManager

func _ready():
	CogitoQuestManager.quest_activated.connect(_on_quest_activated)
	CogitoQuestManager.quest_completed.connect(_on_quest_completed)
	CogitoQuestManager.quest_failed.connect(_on_quest_failed)
	CogitoQuestManager.quest_updated.connect(_on_quest_updated)
	#player_hud = get_parent()
	
	#Hooking up quest display to player inventory toggle.
	player_hud.show_inventory.connect(_show_quest_display)
	player_hud.hide_inventory.connect(_hide_quest_display)
	
	quest_display.hide()


func _show_quest_display():
	update_active_quests()
	update_completed_quests()
	update_failed_quests()
	quest_display.show()
	
func _hide_quest_display():
	quest_display.hide()


func update_active_quests():
	#Clearing out group entries:
	for node in active_group.get_children():
		node.queue_free()
	
	for quest in CogitoQuestManager.get_active_quests():
		var instanced_quest_entry = quest_entry.instantiate()
		active_group.add_child(instanced_quest_entry)
		instanced_quest_entry.set_quest_info(quest.quest_title,quest.quest_description,str(quest.quest_counter_current) + "/" + str(quest.quest_counter_goal))


func update_completed_quests():
	#Clearing out group entries:
	for node in completed_group.get_children():
		node.queue_free()
	
	for quest in CogitoQuestManager.get_completed_quests():
		var instanced_quest_entry = quest_entry.instantiate()
		completed_group.add_child(instanced_quest_entry)
		instanced_quest_entry.set_quest_info(quest.quest_title,quest.quest_description,str(quest.quest_counter_current) + "/" + str(quest.quest_counter_goal))


func update_failed_quests():
	#Clearing out group entries:
	for node in failed_group.get_children():
		node.queue_free()
	
	for quest in CogitoQuestManager.get_failed_quests():
		var instanced_quest_entry = quest_entry.instantiate()
		failed_group.add_child(instanced_quest_entry)
		instanced_quest_entry.set_quest_info(quest.quest_title,quest.quest_description,str(quest.quest_counter_current) + "/" + str(quest.quest_counter_goal))


# Called when the node enters the scene tree for the first time.
func _on_set_quest_notification(passed_quest_icon, passed_quest_text):
	if send_quest_notifications:
		player_hud._on_set_hint_prompt(passed_quest_icon,passed_quest_text)


func _on_quest_activated(_passed_quest:CogitoQuest):
	_on_set_quest_notification(null, str("Quest started: " + _passed_quest.quest_title))

func _on_quest_completed(_passed_quest:CogitoQuest):
	_on_set_quest_notification(null, str("Quest completed: " + _passed_quest.quest_title))

func _on_quest_failed(_passed_quest:CogitoQuest):
	_on_set_quest_notification(null, str("Quest failed: " + _passed_quest.quest_title))

func _on_quest_updated(_passed_quest:CogitoQuest):
	_on_set_quest_notification(null, str("Quest udpated: " + _passed_quest.quest_title))
