extends RigidBody3D

@export var slot_data : InventorySlotPD
@export var interaction_text : String = "Pick up"

func _ready():
	self.add_to_group("Persist")

func interact(body):
	if body.get_parent().inventory_data.pick_up_slot_data(slot_data):
		body.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " added to inventory.")
		Audio.play_sound(slot_data.inventory_item.sound_pickup)
		queue_free()


func get_item_type() -> int:
	if slot_data and slot_data.inventory_item:
		return slot_data.inventory_item.item_type
	else:
		return -1

# Function to handle persistency and saving
func save():
	var node_data = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"slot_data" : slot_data,
		"item_charge" : slot_data.inventory_item.charge_current,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return node_data
