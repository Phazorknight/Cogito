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

# Function to handle persistency and saving
func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x, # Vector2 is not supported by JSON
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return save_dict
