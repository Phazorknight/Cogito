extends Node

# Lifespan is being set by the Lifespan timer.
@onready var lifespan = $Lifespan
# Damage is being set by the wieldable.
var damage_amount : int = 0
## Determine what happens if the projectile hits something. Keep this false for stuff like Arrows. True for stuff like bullets or rockets.
@export var destroy_on_impact : bool = false
## Determine if the player can pick this projectile up again.
var interaction_nodes : Array[Node]

func _ready():
	add_to_group("interactable")
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	
	lifespan.timeout.connect(on_timeout)


func on_timeout():
	queue_free()


func _on_body_entered(collider):
	if collider is CogitoObject:
		collider.damage_received.emit(damage_amount)
		if destroy_on_impact:
			queue_free()
