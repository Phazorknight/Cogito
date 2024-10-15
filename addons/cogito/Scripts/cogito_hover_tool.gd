extends Node3D

@onready var neutral_position : Vector3 = global_position

## Define the axis the object will rotate.
@export var hover_amplitude: Vector3 = Vector3(0,.5,0)
## Time it takes to reach the return position.
@export var hover_speed : float = 1
## Activates/deactivates hover tweens.
@export var is_hovering : bool

var hover_tween : Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hover_tween = create_tween().set_loops()
	hover_tween.tween_property(self,"global_position", neutral_position + hover_amplitude, hover_speed).set_trans(Tween.TRANS_CUBIC)
	hover_tween.tween_property(self,"global_position", neutral_position - hover_amplitude, hover_speed).set_trans(Tween.TRANS_CUBIC)
