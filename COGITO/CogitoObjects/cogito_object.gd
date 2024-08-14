@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoObject.svg")
extends Node3D
class_name CogitoObject

signal damage_received(damage_value:float)

var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null
var properties : int

var submerged := false


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	self.add_to_group("interactable")
	self.add_to_group("Persist")  # Adding object to group for persistence

	find_interaction_nodes()
	find_cogito_properties()

	# hacky solution of getting the properties of a RigidBody3D when applicable.
	# this is necessary for object floating because of how the fluid_interactor handles checking if an object should float or not.
	if use_collision_shapes and self.has_method("get_shape_owners"):
		for owner_id in self.call("get_shape_owners"):
			var collision = self.call("shape_owner_get_owner", owner_id)
			# Ensure that the collision is of type CollisionShape3D
			if collision is CollisionShape3D:
				fluid_interactor.add_collision_shape(collision)



# Future method to set object state when a scene state file is loaded.
func set_state():	
	#TODO: Find a way to possibly save health of health attribute.
	find_cogito_properties()
	pass


func find_interaction_nodes():
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components


func find_cogito_properties():
	var property_nodes = find_children("","CogitoProperties",true) #Grabs all attached property components
	if property_nodes:
		cogito_properties = property_nodes[0]
		#print(name, ": cogito_properties set to ", cogito_properties)


# Function to handle persistence and saving
func save():
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		#"slot_data" : slot_data,
		#"item_charge" : slot_data.inventory_item.charge_current,
		"interaction_nodes" : interaction_nodes,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return node_data


func _on_body_entered(body: Node) -> void:
	# Using this check to only call interactions on other Cogito Objects. #TODO: could be a better check...
	if body.has_method("save") and cogito_properties:
		cogito_properties.start_reaction_threshold_timer(body)


func _on_body_exited(body: Node) -> void:
	# Using this check to only call interactions on other Cogito Objects. #TODO: could be a better check...
	if body.has_method("save") and cogito_properties:
		cogito_properties.check_for_reaction_timer_interrupt(body)

var in_fluid := false
@export var can_float : bool = false
signal entered_to_fluid(Vector3)
signal exited_to_fluid(Vector3)
@export var use_collision_shapes := true
@export var fluid_damp := 4.0
@onready var fluid_interactor := FluidInteractor3D.new()

func fluid_area_enter(fluid):
	self.linear_velocity = self.linear_velocity.lerp(Vector3.ZERO, 0.2)
	fluid_interactor.fluid_area_enter(fluid)
	in_fluid = true
	self.linear_velocity = self.linear_velocity / 4
	# Apply damping to reduce excessive movement
	self.linear_velocity = self.linear_velocity.lerp(Vector3.ZERO, 0.2)

func fluid_area_exit(fluid):
	fluid_interactor.fluid_area_exit(fluid)
	in_fluid = false

@export var fluid_damping_factor: float = 0.1  # Adjust for more gradual damping
var buoyancy_smooth_factor : float = 0.5

func _physics_process(delta: float) -> void:
	if !in_fluid:
		#if we're not in water, exit to prevent running unncessary code.
		return

	# Again, all of this is a very hacky solution to grab the functions and variables inherit to RigidBody3Ds that may not be present
	# in Node3D, which CogitoObject needs to be or it breaks stuff I learned (the fun way).
	if self.has_method("apply_force"): #we're just checking to see if it's a RigidBody3D, which apply_force() can be called in
		var linear_velocity = self.get("linear_velocity") #this is the strategy for getting RigidBody3D specific variables and functions.

		if !can_float:
			# this is another early exit.  If the object can't float, apply a sinking effect to it.
			# this line of code is honestly MAGIC.
			linear_velocity = linear_velocity.lerp(Vector3.ZERO, 0.2)
			self.set("linear_velocity", linear_velocity)
			return
		# if it can float, we do the floating calculations.  This stuff all uses the floatable_body addon because trying to figure out
		# how to code all that was killing me.
		# the first argument of process requires a Transform3D.  So if global_transform.basis isn't working, try just global_transform.
		# you can add some print statements into process to figure out what the problem is.  Usually it's the Transform3D is returning a position that's 
		# too high for the top of the "water"
		fluid_interactor.process(self.global_transform.basis, self.get("mass"), gravity)
		
		for floater in fluid_interactor.get_floaters():
			if floater.is_just_entered_to_fluid():
				entered_to_fluid.emit(floater.position)
			if floater.is_just_exited_from_fluid():
				exited_to_fluid.emit(floater.position)
		
		if not fluid_interactor.float_force.is_zero_approx():
			var current_force = self.get("linear_velocity")
			var desired_force = fluid_interactor.float_force
			var smoothed_force = current_force.lerp(desired_force, buoyancy_smooth_factor)
			self.call("apply_force", smoothed_force, fluid_interactor.float_position)
			
			# Apply gradual damping
			self.set("linear_damp", fluid_damping_factor)
			self.set("angular_damp", fluid_damping_factor)
		else:
			self.set("linear_damp", 0.0)
			self.set("angular_damp", 0.0)
