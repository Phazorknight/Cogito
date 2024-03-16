extends Node3D
class_name ImpactAttributeDamage
# Attached to a RigidBody, this components will will damage a CogitoAttribute when the rigidbody collides with something.
@onready var parent_node = get_parent()

## This is what will take damage
@export var attribute : CogitoAttribute
## The minimum velocity at time of impact to take damage. This prevents light hits from damageing the attribute
@export var minimum_velocity : float = 1.0
## How much damage to do to the attribute
@export var damage : float = 1.0
## Forced delay between impact times (in seconds).
@export var next_impact_time : float = 0.3

var is_delaying : bool

@onready var minimum_velocity_squared : float = minimum_velocity * minimum_velocity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !parent_node.is_class("RigidBody3D"):
		print("ImpactDamage: ", parent_node, " needs to be RigidBody3D.")
	else:
		parent_node.body_entered.connect(_on_parent_node_collision)


func _on_parent_node_collision(_collided_node):
	if  !is_delaying and parent_node.linear_velocity.length_squared() >= minimum_velocity_squared:
		attribute.subtract(damage)
		impact_time_delay()

func impact_time_delay():
	is_delaying = true
	await get_tree().create_timer(next_impact_time).timeout
	is_delaying = false
