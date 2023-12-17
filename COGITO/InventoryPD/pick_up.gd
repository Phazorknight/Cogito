extends RigidBody3D

@export var slot_data : InventorySlotPD
@export var interaction_text : String = "Pick up"

func interact(body):
	if body.get_parent().inventory_data.pick_up_slot_data(slot_data):
		body.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " added to inventory.")
		Audio.play_sound(slot_data.inventory_item.sound_pickup)
		queue_free()
