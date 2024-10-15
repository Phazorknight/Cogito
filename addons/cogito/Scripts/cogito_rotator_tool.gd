extends Node3D

## Define the axis the object will rotate.
@export var rotation_axis : Vector3 = Vector3(1,0,0)
## Rotation speed.
@export var rotation_speed : float = 1

@export var is_rotating : bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_rotating:
		self.rotate(rotation_axis, rotation_speed * delta)
