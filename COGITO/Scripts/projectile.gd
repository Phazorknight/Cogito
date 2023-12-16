extends Node

# Lifespan is being set by the Lifespan timer.
@onready var lifespan = $Lifespan
# Damage is being set by the wieldable.
var damage_amount : int = 0
## Determine what happens if the projectile hits something. Keep this false for stuff like Arrows. True for stuff like bullets or rockets.
@export var destroy_on_impact : bool = false
## Determine if the player can pick this projectile up again.
@export var is_pickup : bool = false
@export var slot_data : InventorySlotPD
@export var interaction_text : String = "Pick up"


func _ready():
	lifespan.timeout.connect(on_timeout)


func on_timeout():
	queue_free()


func _on_body_entered(body):
	if body is HitboxComponent:
		print(self, " _on_body_entered: ", body)
		body.damage(damage_amount)
		if destroy_on_impact:
			queue_free()
	if destroy_on_impact:
		queue_free()
		

func interact(body):
	if is_pickup:
		print("Picking up ", self)
		if body.get_parent().inventory_data.pick_up_slot_data(slot_data):
			body.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " added to inventory.")
			Audio.play_sound(slot_data.inventory_item.sound_pickup)
			queue_free()
