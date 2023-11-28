extends RigidBody3D

@export var slot_data : InventorySlotPD
@export var interaction_text : String = "Pick up"

func interact(body):
	print("Picking up ", self)
	if body.get_parent().inventory_data.pick_up_slot_data(slot_data):
		body.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " added to inventory.")
		AudioManagerPd.play_audio("pick_up")
		queue_free()
