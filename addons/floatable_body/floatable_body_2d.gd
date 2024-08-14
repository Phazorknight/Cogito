extends RigidBody2D
class_name FloatableBody2D

signal entered_to_fluid(Vector2)
signal exited_to_fluid(Vector2)

@export var use_collision_shapes := true
@export var fluid_damp := 4.0
@onready var fluid_interactor := FluidInteractor2D.new()


func _ready():
	if use_collision_shapes:
		for owner_id in get_shape_owners():
			var collision = shape_owner_get_owner(owner_id)
			if collision is CollisionShape2D:
				fluid_interactor.add_collision_shape(collision)


func _physics_process(_delta: float) -> void:
	fluid_interactor.process(global_transform, mass, gravity_scale)
	
	for floater in fluid_interactor.get_floaters():
		if floater.is_just_entered_to_fluid():
			entered_to_fluid.emit(floater.position)
		if floater.is_just_exited_from_fluid():
			exited_to_fluid.emit(floater.position)

	if not fluid_interactor.float_force.is_zero_approx():
		# Bouyancy
		apply_force(fluid_interactor.float_force, fluid_interactor.float_position)
		# Damping
		linear_damp = fluid_damp
		angular_damp = fluid_damp
	else:
		linear_damp = 0.0
		angular_damp = 0.0

# Call from FluidArea2D
func fluid_area_enter(area: FluidArea2D) -> void:
	fluid_interactor.fluid_area_enter(area)

# Call from FluidArea2D
func fluid_area_exit(area: FluidArea2D) -> void:
	fluid_interactor.fluid_area_exit(area)
