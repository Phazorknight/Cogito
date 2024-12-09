extends Node3D

## Define the axis the object will rotate.
@export var rotation_axis : Vector3 = Vector3(1,0,0)
## Rotation speed.
@export var rotation_speed : float = 1

@export var is_rotating : bool

@export var check_world_state: bool
@export var world_state_property: String = "lab_power"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if check_world_state:
		check_for_power.call_deferred()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_rotating:
		self.rotate(rotation_axis, rotation_speed * delta)


func check_for_power() -> void:
	await CogitoSceneManager.is_node_ready()
	var property_value = CogitoSceneManager._current_world_dict.get(world_state_property)
	CogitoGlobals.debug_log(true, "cogito_rotator_tool", "world_dict: " + str(world_state_property) + " = " + str(property_value) )

	if property_value == true:
		is_rotating = true
	else:
		is_rotating = false
