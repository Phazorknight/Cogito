extends Node

# Some paramterers for game behaviour
var persistent_objects_y_offset_on_load : float = .1


# Function to transition to another scene via the loading screen.
func load_next_scene(target : String, ignore_scene_state : bool) -> void:
	var loading_screen = preload("res://COGITO/SceneManagement/LoadingScene.tscn").instantiate()
	loading_screen.next_scene_path = target
	loading_screen.ignore_scene_state = ignore_scene_state
	get_tree().current_scene.add_child(loading_screen)


func reset_scene_states():
	# CREATE FUNCTION THAT DELETES SCENE STATE FILES.
	pass

# Save function
func save_scene_state(scene_state_filename : String):
	print("Attempting to save scene state for ", scene_state_filename)
	var scene_state_path = str("res://COGITO/SceneManagement/SceneStateFiles/" + scene_state_filename + ".save")
	
	var scene_state = FileAccess.open(scene_state_path, FileAccess.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	
	if !save_nodes:
		print("No nodes in Persist group!")
		return
	
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save")

		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data)

		# Store the save dictionary as a new line in the save file.
		scene_state.store_line(json_string)
		print("Saved state for ", node)
	
	print("Scene state saved.")
		
# Load function
func load_scene_state(scene_state_filename : String):
	print("Attempting to load scene state for ", scene_state_filename)
	var scene_state_path = str("res://COGITO/SceneManagement/SceneStateFiles/" + scene_state_filename + ".save")
	if not FileAccess.file_exists(scene_state_path):
		print("Scene state file not found: ", scene_state_filename)
		return # Error! We don't have a save to load.

	# We need to revert the game state so we're not cloning objects
	# during loading. This will vary wildly depending on the needs of a
	# project, so take care with this step.
	# For our example, we will accomplish this by deleting saveable objects.
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for i in save_nodes:
		print("Deleting existing node: ", i)
		i.queue_free()

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var scene_state = FileAccess.open(scene_state_path, FileAccess.READ)
	while scene_state.get_position() < scene_state.get_length():
		var json_string = scene_state.get_line()

		var json = JSON.new() # Creates the helper class to interact with JSON

		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		var node_data = json.get_data() # Get the data from the JSON object

		# Create the object,  add it to the tree, set its position and rotation.
		var new_object = load(node_data["filename"]).instantiate()
		get_node(node_data["parent"]).add_child(new_object)
		print("Adding to scene: ", new_object)
		new_object.position = Vector3(node_data["pos_x"], node_data["pos_y"] + persistent_objects_y_offset_on_load, node_data["pos_z"])
		new_object.rotation = Vector3(node_data["rot_x"], node_data["rot_y"], node_data["rot_z"])
		
		# Set the remaining variables.
		for i in node_data.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y" or i == "pos_z" or i == "rot_x" or i == "rot_y" or i == "rot_z":
				continue
			new_object.set(i, node_data[i])
			print( new_object, ": Set ", i, " to ", node_data[i])

	print("Scene state loaded.")
