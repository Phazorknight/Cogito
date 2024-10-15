extends Area3D

@export var spawn_area : CollisionShape3D

@export_range(1,100) var spawn_amount : int

@export var object_to_spawn : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !spawn_area.shape.is_class("BoxShape3D"):
		print("spawn area is not a BoxShape3D!")
	pass # Replace with function body.


func spawn_objects():
	var left_to_spawn = spawn_amount
	var spawn_point : Vector3 = Vector3.ZERO
	while left_to_spawn > 0:
		spawn_point.x = randf_range(spawn_area.global_position.x - spawn_area.shape.size.x, spawn_area.global_position.x + spawn_area.shape.size.x )
		spawn_point.y = randf_range(spawn_area.global_position.y - spawn_area.shape.size.y, spawn_area.global_position.y + spawn_area.shape.size.y )
		spawn_point.z = randf_range(spawn_area.global_position.z - spawn_area.shape.size.z, spawn_area.global_position.z + spawn_area.shape.size.z )
		
		var spawned_object = object_to_spawn.instantiate()
		spawned_object.position = spawn_point
		get_tree().current_scene.add_child(spawned_object)
		
		left_to_spawn -= 1


func _on_generic_button_pressed() -> void:
	spawn_objects()
