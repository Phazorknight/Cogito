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


func _ready():
	add_to_group("interactable")
	find_interaction_nodes()
	find_cogito_properties()
	
	if lifespan:
		lifespan.timeout.connect(on_timeout)


func on_timeout():
	queue_free()


## Checking collision event for property tags.
func _on_body_entered(collider: Node):
	if collider.has_signal("damage_received"):
		if( !collider.cogito_properties && !cogito_properties): # Case where neither projectile nor the object hit have properties defined.
			print("Projectile: Collider nor projecte have CogitoProperties, damaging as usual.")
			deal_damage(collider)
			return
		
		if( !collider.cogito_properties && cogito_properties): # Case where only the projectile has properties defined.
			match cogito_properties.material_properties:
				CogitoProperties.MaterialProperties.SOFT:
					# Defining what happens if a soft project hits an object with no properties.
					print("Projectile: Soft projectile does no damage per default.")
					return
		
		if( collider.cogito_properties && cogito_properties): # Case where both projectile and the object hit have properties defined.
			if( cogito_properties.material_properties == CogitoProperties.MaterialProperties.SOFT && collider.cogito_properties.material_properties == CogitoProperties.MaterialProperties.SOFT):
				# When both objects are soft, damage the hit object.
				print("Projectile: Soft object hit, dealing damage.")
				deal_damage(collider)
			
			# Manually setting the reaction collider and calling reactions on object hit, skipping the reaction threshold time.
			collider.cogito_properties.reaction_collider = self
			collider.cogito_properties.check_for_systemic_reactions()


func deal_damage(collider: Node):
	collider.damage_received.emit(damage_amount)
	if destroy_on_impact:
		queue_free()
