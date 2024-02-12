extends Node3D
class_name ImpactSounds
# Attached to a RigidBody, this components will emit sounds when the RigidBody collides with something.
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var parent_node = get_parent()

## This is used to grab sounds to play.
@export var impact_sounds : AudioStreamRandomizer
## Forced delay between impact times (in seconds).
@export var next_impact_time : float = 0.3

var time_passed : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !parent_node.is_class("RigidBody3D"):
		print("ImpactSounds: ", parent_node, " needs to be RigidBody3D.")
	else:
		parent_node.body_entered.connect(_on_parent_node_collision)

	audio_stream_player_3d.stream = impact_sounds


func _on_parent_node_collision(_collided_node):
	if !audio_stream_player_3d.playing and time_passed == 0:
		audio_stream_player_3d.play()
		time_passed = next_impact_time


func _physics_process(delta: float) -> void:
	if time_passed > 0:
		time_passed -= delta
	else:
		time_passed = 0
