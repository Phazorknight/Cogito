# Main class for managing quests in the Cogito system
# Inherits from Resource to allow creation as a resource in Godot
extends Resource
class_name CogitoQuest

# Unique quest identifier (for internal reference)
#@export var id: int

# Internal quest name (used for game logic)
@export var quest_name: String

# Displayed quest title (for user interface)
@export var quest_title: String

# Quest description when it's in progress
@export_multiline var quest_description_active: String

# Quest description when it has been completed
@export_multiline var quest_description_completed: String = "You completed this quest."

# Quest description when it has been failed
@export_multiline var quest_description_failed: String = "You failed this quest."

# Editor group to organize audio settings
@export_group("Quest Audio")

# Audio played when the quest starts
@export var audio_on_start: AudioStream

# Audio played when the quest is completed
@export var audio_on_complete: AudioStream

# Audio played when the quest fails
@export var audio_on_fail: AudioStream

# Current quest description (dynamically updated based on state)
@export var quest_description: String

# Current progress counter for the quest
@export var quest_counter_current: int = 0

# Goal value for the counter to complete the quest
@export var quest_counter_goal: int

# Flag indicating whether the quest has been completed
@export var quest_completed: bool = false

# Flag indicating whether the quest has been failed
@export var quest_failed: bool = false

# Property getter/setter for quest counter
# When value is changed, automatically checks if quest is completed
var quest_counter: int:
	get:
		return quest_counter_current
	set(value):
		quest_counter_current = value
		
		# Check if goal has been reached or exceeded
		if quest_counter_current >= quest_counter_goal and !quest_completed:
			complete()

# Starts the quest
# Parameter _mute: if true, doesn't play start audio
func start(_mute: bool = false) -> void:
	# Play start audio if available and not muted
	if audio_on_start and not _mute:
		Audio.play_sound(audio_on_start)
	
	# Set description to active state
	quest_description = quest_description_active
	
	# Reset completion and failure states
	quest_completed = false
	quest_failed = false

# Updates the quest (placeholder method - needs implementation)
func update() -> void:
	# WARNING: This method is incomplete
	# Currently just marks as completed without additional logic
	quest_completed = true 
	pass  # Pending implementation

# Completes the quest
# Parameter _mute: if true, doesn't play completion audio
func complete(_mute: bool = false) -> void:
	# Play completion audio if available and not muted
	if audio_on_complete and not _mute:
		Audio.play_sound(audio_on_complete)
	
	# Update description to completed state
	quest_description = quest_description_completed
	
	# If progression quest, make sure the counter is set to goal.
	quest_counter_current = quest_counter_goal
	
	# Set state flags
	quest_completed = true
	quest_failed = false

# Marks the quest as failed
# Parameter _mute: if true, doesn't play failure audio
func failed(_mute: bool = false) -> void:
	# Play failure audio if available and not muted
	if audio_on_fail and not _mute:
		Audio.play_sound(audio_on_fail)
	
	# Update description to failed state
	quest_description = quest_description_failed
	
	# Set state flags
	quest_failed = true
	quest_completed = false
