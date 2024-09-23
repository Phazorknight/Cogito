@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoVehicle.svg")
extends CogitoSittable
class_name CogitoVehicle

signal vehicle_moved()

#region Variables
@export var move_speed: float = 5
@export var rotation_speed: float = 0.5
@export var momentum_damping: float = 0.95
@export var vehicle_node: Node

var velocity: Vector3 = Vector3.ZERO
var rotation_momentum: float = 0.0
var acceleration: Vector3 = Vector3.ZERO
#endregion

func _ready():
	super._ready()
	physics_sittable = true

func _physics_process(delta):

	if player_node and player_node.is_sitting and CogitoSceneManager._current_sittable_node == self:
		handle_input(delta)
		apply_momentum(delta)

		if vehicle_node:
			vehicle_node.global_translate(velocity * delta)
			vehicle_node.rotate_y(rotation_momentum * delta)

		vehicle_moved.emit()

func handle_input(delta):

	var input_vector = Vector3.ZERO
	if Input.is_action_pressed("forward"):
		input_vector.z += 1
	elif Input.is_action_pressed("back"):
		input_vector.z -= 1

	var rotation_input = 0.0
	if Input.is_action_pressed("left"):
		rotation_input += 1
	elif Input.is_action_pressed("right"):
		rotation_input -= 1

	if vehicle_node:
		var local_direction = vehicle_node.global_transform.basis * input_vector
		acceleration = local_direction * move_speed * delta
	rotation_momentum += rotation_input * rotation_speed

func apply_momentum(delta):
	if rotation_momentum != 0:
		rotation_momentum *= momentum_damping
	velocity += acceleration
	velocity *= momentum_damping
	acceleration = Vector3.ZERO

func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"is_occupied" : is_occupied,
		"physics_sittable" : physics_sittable,
		"interaction_text" : interaction_text,
		"pos_x" : global_position.x,
		"pos_y" : global_position.y,
		"pos_z" : global_position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
