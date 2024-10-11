extends Node3D
class_name ImpactSounds
# Attached to a RigidBody, this components will emit sounds when the RigidBody collides with something.
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var parent_node = get_parent()

## This is used to grab sounds to play.
@export var impact_sounds : AudioStreamRandomizer
## Forced delay between impact times (in seconds).
@export var next_impact_time : float = 0.3

var is_delaying : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !parent_node.is_class("RigidBody3D"):
		print("ImpactSounds: ", parent_node, " needs to be RigidBody3D.")
	else:
		parent_node.body_entered.connect(_on_parent_node_collision)

	audio_stream_player_3d.stream = impact_sounds


func _on_parent_node_collision(_collided_node):
	if !audio_stream_player_3d.playing and !is_delaying:
		audio_stream_player_3d.play()
		impact_time_delay()


func impact_time_delay():
	is_delaying = true
	await get_tree().create_timer(next_impact_time).timeout
	is_delaying = false
