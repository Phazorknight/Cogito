@tool
@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoObject.svg")
extends Node3D
class_name CogitoObject

signal damage_received(damage_value:float)
signal object_exits_tree()

signal entered_to_fluid(Vector3)
signal exited_to_fluid(Vector3)

@export var cogito_name : String = self.name
## Name that will displayed when interacting. Leave blank to hide
@export var display_name : String

@export_group("Object Size and Shape")
## Set a custom shape used for calculating object size when dropping.
@export var custom_aabb : AABB = AABB():
	set(new_aabb):
		custom_aabb = new_aabb
		if show_aabb_debug_shape:
			CogitoGlobals.draw_box_aabb(get_aabb(), Color.AQUA)

## Shows the objects AABB debug shape in Editor.
@export var show_aabb_debug_shape : bool = false:
	set(new_show_debug_shape):
		show_aabb_debug_shape = new_show_debug_shape
		if Engine.is_editor_hint() and show_aabb_debug_shape:
			CogitoGlobals.draw_box_aabb(get_aabb(), Color.AQUA)
		else:
			CogitoGlobals.clear_debug_shape()

@export_group("Fluid Floating Parameters")
@export var fluid_influence_enabled := true
@export var use_collision_shapes := true
@export var fluid_damp := 4.0
@onready var fluid_interactor := FluidInteractor3D.new()

var rigid_body : RigidBody3D

var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null
var properties : int
var spawned_loot_item: bool = false


func _ready():
	self.add_to_group("interactable")
	self.add_to_group("Persist") #Adding object to group for persistence
	find_interaction_nodes()
	find_cogito_properties()

	if not fluid_influence_enabled:
		return
	
	rigid_body = find_rigid_body()
	if not rigid_body:
		return
	
	if use_collision_shapes:
		for owner_id in rigid_body.get_shape_owners():
			var collision = rigid_body.shape_owner_get_owner(owner_id)
			if collision is CollisionShape3D:
				fluid_interactor.add_collision_shape(collision)


func get_aabb():
	if custom_aabb:
		return custom_aabb
		
	var aabb : AABB = AABB()
	
	for child in find_children("*", "MeshInstance3D", true, false):
		if child.visible:
			aabb = aabb.merge(child.transform * child.get_aabb())
	
	return aabb


# Future method to set object state when a scene state file is loaded.
func set_state():	
	#TODO: Find a way to possibly save health of health attribute.
	find_cogito_properties()
	
	if spawned_loot_item:
		add_to_group("spawned_loot_items")
		
	pass


func find_interaction_nodes():
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components


func find_cogito_properties():
	var property_nodes = find_children("","CogitoProperties",true) #Grabs all attached property components
	if property_nodes:
		cogito_properties = property_nodes[0]


# Function to handle persistence and saving
func save():
	if self.is_in_group("spawned_loot_items"):
		spawned_loot_item = true
		
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
		"spawned_loot_item" : spawned_loot_item,
	}

	# If the node is a RigidBody3D, then save the physics properties of it
	var rigid_body = find_rigid_body()
	if rigid_body:
		node_data["linear_velocity_x"] = rigid_body.linear_velocity.x
		node_data["linear_velocity_y"] = rigid_body.linear_velocity.y
		node_data["linear_velocity_z"] = rigid_body.linear_velocity.z
		node_data["angular_velocity_x"] = rigid_body.angular_velocity.x
		node_data["angular_velocity_y"] = rigid_body.angular_velocity.y
		node_data["angular_velocity_z"] = rigid_body.angular_velocity.z
	return node_data


func find_rigid_body() -> RigidBody3D:
	var current = self
	while current:
		if current is RigidBody3D:
			return current as RigidBody3D
		current = current.get_parent()
	return null


func _physics_process(delta: float) -> void:
	if fluid_influence_enabled and rigid_body:
		fluid_interactor.process(rigid_body.global_transform, rigid_body.mass, rigid_body.gravity_scale)
		
		for floater in fluid_interactor.get_floaters():
			if floater.is_just_entered_to_fluid():
				entered_to_fluid.emit(floater.position)
			if floater.is_just_exited_from_fluid():
				exited_to_fluid.emit(floater.position)

		if not fluid_interactor.float_force.is_zero_approx():
			# Bouyancy
			rigid_body.apply_force(fluid_interactor.float_force * delta, fluid_interactor.float_position)
			# Damping
			rigid_body.linear_damp = fluid_damp
			rigid_body.angular_damp = fluid_damp
		else:
			rigid_body.linear_damp = 0.0
			rigid_body.angular_damp = 0.0


func fluid_area_enter(area: FluidArea3D) -> void:
	fluid_interactor.fluid_area_enter(area)


func fluid_area_exit(area: FluidArea3D) -> void:
	fluid_interactor.fluid_area_exit(area)


func _on_body_entered(body: Node) -> void:
	# Using this check to only call interactions on other Cogito Objects. #TODO: could be a better check...
	if body.has_method("save") and cogito_properties:
		cogito_properties.start_reaction_threshold_timer(body)


func _on_body_exited(body: Node) -> void:
	# Using this check to only call interactions on other Cogito Objects. #TODO: could be a better check...
	if body.has_method("save") and cogito_properties:
		cogito_properties.check_for_reaction_timer_interrupt(body)


func _exit_tree() -> void:
	object_exits_tree.emit()
