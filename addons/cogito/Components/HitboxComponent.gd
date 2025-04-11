extends Node
class_name HitboxComponent

signal got_hit

@export var health_attribute : CogitoHealthAttribute
## PackedScene that will get spawned on global hit position
@export var spawn_at_global_collision: PackedScene
## PackedScene that will get spawned on parents local hit position
@export var spawn_at_local_collision: PackedScene
## Apply force to Rigidbodies on hit
@export var apply_force_on_hit : bool
## Multiplier of force applied to rigidbody, if force apply is true
@export var applied_force_multipler : int

@onready var parent = get_parent()

func _ready() -> void:
	if get_parent().has_signal("damage_received"):
		if !get_parent().damage_received.is_connected(damage):
			get_parent().damage_received.connect(damage)
	else:
		CogitoGlobals.debug_log(true, "HitboxComponent", "Parent " + get_parent().name + " is missing a damage_received() signal.")


func damage(damage_amount: float, _hit_direction:= Vector3.ZERO, _hit_position:= Vector3.ZERO):
	if health_attribute:
		health_attribute.subtract(damage_amount)
	
	if spawn_at_global_collision != null:
		var spawned_object = spawn_at_global_collision.instantiate()
		spawned_object.position = _hit_position
		get_tree().current_scene.add_child(spawned_object)
		
	if spawn_at_local_collision != null:
		var local_hit_position = parent.to_local(_hit_position)
		var spawned_object = spawn_at_local_collision.instantiate()
		spawned_object.position = local_hit_position
		parent.add_child(spawned_object)
		
	if apply_force_on_hit:
		##TODO Handle CharacterBody3D for NPC knockback
		if parent is RigidBody3D:
			parent.apply_impulse(_hit_direction * damage_amount * applied_force_multipler, _hit_position)
		if parent is CharacterBody3D:
			parent.apply_knockback(_hit_direction * damage_amount * applied_force_multipler)
			
	got_hit.emit()
