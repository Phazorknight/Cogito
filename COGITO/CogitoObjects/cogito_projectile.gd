@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoObject.svg")
extends CogitoObject
## Derived from CogitoOBject, this class handles additional information for projectiles like lifespan, damage, destroy_on_impact. Some of these are inherited from the Wieldable that spawns this projectile.
class_name CogitoProjectile

# Lifespan is being set by the Lifespan timer.
@onready var lifespan = $Lifespan
# Damage is being set by the wieldable.
var damage_amount : int = 0
## Determine what happens if the projectile hits something. Keep this false for stuff like Arrows. True for stuff like bullets or rockets.
@export var destroy_on_impact : bool = false
## Sound that gets played when projectile dies.
@export var sound_on_death : AudioStream

func _ready():
	add_to_group("interactable")
	self.add_to_group("Persist") #Adding object to group for persistence
	find_interaction_nodes()
	find_cogito_properties()
	
	if lifespan:
		lifespan.timeout.connect(on_timeout)


func on_timeout():
	die()


## Checking collision event for property tags.
func _on_body_entered(collider: Node):
	if collider.has_signal("damage_received"):
		if( !collider.cogito_properties && !cogito_properties): # Case where neither projectile nor the object hit have properties defined.
			print("Projectile: Collider nor projecte have CogitoProperties, damaging as usual.")
			deal_damage(collider)
			return
		
		if( collider.cogito_properties && !cogito_properties): # Case were only collider has properties.
			print("Projectile: Collider has CogitoProperties, currently ignoring these and damaging as usual.")
			deal_damage(collider)

		if( !collider.cogito_properties && cogito_properties): # Case where only the projectile has properties defined.
			match cogito_properties.material_properties:
				CogitoProperties.MaterialProperties.SOFT:
					# Defining what happens if a soft projectile hits an object with no properties.
					print("Projectile: Soft projectile does no damage per default.")
					if destroy_on_impact:
						die()
					return
		
		if( collider.cogito_properties && cogito_properties): # Case where both projectile and the object hit have properties defined.
			if( cogito_properties.material_properties == CogitoProperties.MaterialProperties.SOFT && collider.cogito_properties.material_properties == CogitoProperties.MaterialProperties.SOFT):
				# When both objects are soft, damage the hit object.
				print("Projectile: Soft object hit, dealing damage.")
				deal_damage(collider)
			
			# Manually setting the reaction collider and calling reactions on object hit, skipping the reaction threshold time.
			collider.cogito_properties.reaction_collider = self
			collider.cogito_properties.check_for_systemic_reactions()
				
	else:
		if destroy_on_impact:
			die()


func deal_damage(collider: Node):
	print(self.name, ": dealing damage amount ", damage_amount, " on collider ", collider.name)
	collider.damage_received.emit(damage_amount)
	if destroy_on_impact:
		die()


func die():
	if sound_on_death:
		Audio.play_sound_3d(sound_on_death).global_position = global_position
	queue_free()
