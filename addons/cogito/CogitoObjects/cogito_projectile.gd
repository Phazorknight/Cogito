@tool
@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_CogitoObject.svg")
extends CogitoObject
## Derived from CogitoObject, this class handles additional information for projectiles like lifespan, damage, destroy_on_impact. Some of these are inherited from the Wieldable that spawns this projectile.
class_name CogitoProjectile

# Lifespan is being set by the Lifespan timer.
@onready var lifespan = $Lifespan
# Damage is being set by the wieldable.
var damage_amount : int = 0

## Determine what happens if the projectile hits something. Keep this false for stuff like Arrows. True for stuff like bullets or rockets.
@export var destroy_on_impact : bool = false
## Sound that gets played when the projectile dies.
@export var sound_on_death : AudioStream
## Should the projectile stick to what it hits?
@export var stick_on_impact : bool = false
## Array of Scenes that will get spawned on parent position on death.
@export var spawn_on_death : Array[PackedScene] = []
## This prevents being able to auto pick up projectiles that have just been fired
@export_range(0.1, 3.0, 0.1, "or_greater") var pick_up_delay: float = 0.5
var can_pick_up: bool = false

var Direction

func _ready():
	add_to_group("interactable")
	self.add_to_group("Persist") #Adding object to group for persistence
	find_interaction_nodes()
	find_cogito_properties()
	
	if lifespan:
		lifespan.timeout.connect(on_timeout)
		
	_pick_up_timer()


func _pick_up_timer() -> void:
	if lifespan and (lifespan as Timer).wait_time < pick_up_delay:
		# The projectile cannot be picked up before it dies, so don't create the timer
		return
	await get_tree().create_timer(pick_up_delay).timeout
	can_pick_up = true


func on_timeout():
	die()


## Checking collision event for property tags.
func _on_body_entered(collider: Node):
	var collision_point = global_transform.origin
	var bullet_direction = (collision_point - CogitoSceneManager._current_player_node.get_global_transform().origin).normalized() ##This is hacky TODO needs to be fixed for Multiplayer support
	
	if stick_on_impact:
		self.linear_velocity = Vector3.ZERO
		self.angular_velocity = Vector3.ZERO
		stick_to_object(collider)
		
	if collider.has_signal("damage_received"):
		if( !collider.cogito_properties && !cogito_properties): # Case where neither projectile nor the object hit have properties defined.
			CogitoGlobals.debug_log(true, "CogitoProjectile", "Collider nor projectile have CogitoProperties, damaging as usual.")
			deal_damage(collider,bullet_direction, collision_point)
			return
		
		if( collider.cogito_properties && !cogito_properties): # Case were only collider has properties.
			CogitoGlobals.debug_log(true, "CogitoProjectile", "Collider has CogitoProperties, currently ignoring these and damaging as usual.")
			deal_damage(collider,bullet_direction, collision_point)

		if( !collider.cogito_properties && cogito_properties): # Case where only the projectile has properties defined.
			match cogito_properties.material_properties:
				CogitoProperties.MaterialProperties.SOFT:
					# Defining what happens if a soft projectile hits an object with no properties.
					CogitoGlobals.debug_log(true, "CogitoProjectile", "Soft projectile does no damage per default.")
					if destroy_on_impact:
						die()
					return
		
		if( collider.cogito_properties && cogito_properties): # Case where both projectile and the object hit have properties defined.
			if( cogito_properties.material_properties == CogitoProperties.MaterialProperties.SOFT && collider.cogito_properties.material_properties == CogitoProperties.MaterialProperties.SOFT):
				# When both objects are soft, damage the hit object.
				CogitoGlobals.debug_log(true, "CogitoProjectile", "Soft object hit, dealing damage.")
				deal_damage(collider,bullet_direction, collision_point)
			
			# Manually setting the reaction collider and calling reactions on object hit, skipping the reaction threshold time.
			collider.cogito_properties.reaction_collider = self
			collider.cogito_properties.check_for_systemic_reactions()
				
	else:
		if destroy_on_impact:
			die()



# Make the projectile stick to the object it hits using a pin joint
func stick_to_object(collider: Node):
	var joint = PinJoint3D.new()
	joint.node_a = self.get_path()
	joint.node_b = collider.get_path()

	joint.position = global_transform.origin

	# Add the joint to the scene 
	get_tree().root.add_child(joint)
	#self.linear_velocity = Vector3.ZERO
	#self.angular_velocity = Vector3.ZERO

func deal_damage(collider: Node,bullet_direction,bullet_position):
	bullet_direction = Direction
	CogitoGlobals.debug_log(true, "CogitoProjectile", self.name + ": dealing damage amount " + str(damage_amount) + " on collider " + collider.name + " at " + str(bullet_position) + " in direction " + str(Direction) )

	collider.damage_received.emit(damage_amount,bullet_direction,bullet_position)
	if destroy_on_impact:
		die()


func die():
	if sound_on_death:
		Audio.play_sound_3d(sound_on_death).global_position = global_position
		
	for scene in spawn_on_death:
		if scene:
			var spawned_object = scene.instantiate()
			spawned_object.position = position
			get_tree().current_scene.add_child(spawned_object)
			
	queue_free()
