extends Resource
class_name CogitoQuest

@export var id: int
@export var quest_name: String
@export var quest_title: String
@export_multiline var quest_description_active: String
@export_multiline var quest_description_completed: String = "You completed this quest."
@export_multiline var quest_description_failed: String = "You failed this quest."

@export var quest_counter_current: int = 0
@export var quest_counter_goal: int

@export_group("Quest Audio")
@export var audio_on_start: AudioStream
@export var audio_on_complete: AudioStream
@export var audio_on_fail: AudioStream

@export var quest_description: String


@export var quest_completed: bool = false
@export var quest_failed: bool = false

# Getter/Setter correto para quest_counter
var quest_counter: int:
	get:
		return quest_counter_current
	set(value):
		quest_counter_current = value
		
		if quest_counter_current >= quest_counter_goal:
			complete()

func start(_mute: bool = false) -> void:
	if audio_on_start and not _mute:
		Audio.play_sound(audio_on_start)
	quest_description = quest_description_active
	quest_completed = false
	quest_failed = false

func update() -> void:
	quest_completed = true 
	pass

func complete(_mute: bool = false) -> void:
	if audio_on_complete and not _mute:
		Audio.play_sound(audio_on_complete)
	quest_description = quest_description_completed
	quest_completed = true
	quest_failed = false

func failed(_mute: bool = false) -> void:
	if audio_on_fail and not _mute:
		Audio.play_sound(audio_on_fail)
	quest_description = quest_description_failed
	quest_failed = true
	quest_completed = false
