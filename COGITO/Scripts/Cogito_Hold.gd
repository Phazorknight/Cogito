extends AnimatableBody3D

@onready var hold_timer = $HoldTimer
@onready var hold_ui = $HoldUi
@onready var progress_bar = $HoldUi/ProgressBar
@onready var audio_stream_player_3d = $AudioStreamPlayer3D

## Text that shows with the interaction prompt.
@export var interaction_text : String = "Hold to interact."
## Hold time in seconds
@export var hold_time : float = 3.0
## If checked, the object rotates while player holds the button. Used for wheels and cranks.
@export var rotate_while_holding : bool = false
## Define the axis the object will rotate.
@export var rotation_axis : Vector3 = Vector3(1,0,0)
## Rotation speed.
@export var rotation_speed : float = 1
## Drag the nodes you want to get triggered in here from your scene hierarchy. Their interact func will be called when hold is complete.
@export var nodes_to_trigger : Array[Node]
## AudioStream to play while holding.
@export var hold_audio_stream : AudioStream

var is_holding : bool = false


func _ready():
	hold_timer.timeout.connect(_on_hold_complete)
	hold_timer.wait_time = hold_time
	hold_ui.hide()
	progress_bar.value = hold_timer.time_left / hold_time * 100
	audio_stream_player_3d.stream = hold_audio_stream


func _physics_process(delta):
	if is_holding:
		if !audio_stream_player_3d.playing:
			audio_stream_player_3d.play()
		progress_bar.value = hold_timer.time_left / hold_time * 100
		if rotate_while_holding:
			rotate(rotation_axis, delta * rotation_speed)

func interact(_player):
	if !is_holding:
		is_holding = true
		hold_ui.show()
		hold_timer.start()
	

func _input(event):
	if is_holding and event.is_action_released("interact"):
		hold_timer.stop()
		hold_ui.hide()
		audio_stream_player_3d.stop()
		is_holding = false


func _on_hold_complete():
	hold_timer.stop()
	hold_ui.hide()
	is_holding = false
	
	audio_stream_player_3d.stop()
	
	for node in nodes_to_trigger:
		node.interact(null)
