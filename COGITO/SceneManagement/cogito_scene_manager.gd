extends Node

# Used to set active save slot. This could be set/modified, when selecting a save slot from the MainMenu.
@export var _active_slot : String = "A"

# Variables for player state
@export var _current_player_node : Node
@export var _player_state : CogitoPlayerState

# Variables for scene state
@export var _current_scene_name : String
@export var _current_scene_path : String
@export var _scene_state : CogitoSceneState


func loading_saved_game(passed_slot):
	print("CSM: Loading saved game from slot ", passed_slot)
	if !_player_state or !_player_state.state_exists(passed_slot):
		print("CSM: Player state of passed slot doesn't exist.")
		return
		
	_player_state = _player_state.load_state(_active_slot) as CogitoPlayerState
	
	# Check if player is currently in the same scene as in the game that is being attempted to load:
	if get_tree().current_scene.get_name() == _player_state.player_current_scene:
		print("CSM: Player state for slot ", passed_slot, " is from current scene.")
		# Do a simple scene state load and player state load.
		load_scene_state(_player_state.player_current_scene, passed_slot)
		load_player_state(_current_player_node, passed_slot)
	else:
		# Transition to target scene and then attempt to load the saved game again.
		print("CSM: Player state for slot ", passed_slot, " is in different scene. Transitioning...")
		load_next_scene(_player_state.player_current_scene_path, "", passed_slot, true)



#region PLAYER SAVE HANDLING
func load_player_state(player, passed_slot:String):
	print("CSM: Loading player state...")
	if _player_state and _player_state.state_exists(passed_slot):
		print("CSM: Player State in slot ", passed_slot, " exists. Loading ", _player_state)
		_player_state = _player_state.load_state(passed_slot) as CogitoPlayerState
		
		# Applying the save state to player node.
		player.inventory_data = _player_state.player_inventory
		# Loading saved charges of wieldables
		var array_of_wieldable_charges = _player_state.saved_wieldable_charges
		for data in array_of_wieldable_charges:
			if data == null:
				continue
			else:
				for slot in player.inventory_data.inventory_slots:
					if slot and slot.inventory_item and slot.inventory_item == data["resource"]:
						print("Match found: ", slot.inventory_item)
						slot.inventory_item.charge_current = data["charge_current"]
						
		player.inventory_data.force_inventory_update()
		
		player.health_component.current_health = _player_state.player_health.x
		player.health_component.max_health = _player_state.player_health.y
		player.stamina_component.current_stamina = _player_state.player_stamina.x
		player.stamina_component.max_stamina = _player_state.player_stamina.y
		player.sanity_component.current_sanity = _player_state.player_sanity.x
		player.sanity_component.max_sanity = _player_state.player_sanity.y
				
		player.global_position = _player_state.player_position
		player.global_rotation = _player_state.player_rotation
		
		#Loading player interaction component state
		var player_interaction_component_state = _player_state.interaction_component_state
		for state_data in player_interaction_component_state:
			for data in state_data.keys():
				player.player_interaction_component.set(data, state_data[data])
			player.player_interaction_component.set_state()
		
		player.player_state_loaded.emit()
		player._on_player_state_loaded()
	else:
		print("CSM: Player state of slot ", passed_slot, " doesn't exist.")
		

func save_player_state(player, slot:String):
	if !_player_state:
		print("CSM: State doesn't exist. Creating for slot ", slot, "...")
		_player_state = CogitoPlayerState.new()
	
	# Writing the save state from current player node.
	_player_state.player_inventory = player.inventory_data
	
	_player_state.clear_saved_wieldable_charges()
	for item_slot in player.inventory_data.inventory_slots:
		if item_slot and item_slot.inventory_item and item_slot.inventory_item.item_type == 1:
			var item_save_data = item_slot.inventory_item.save()
			_player_state.append_saved_wieldable_charges(item_save_data)
			print("Saved charge for ", item_slot.inventory_item )
	
	_player_state.player_current_scene = _current_scene_name
	_player_state.player_current_scene_path = _current_scene_path
	_player_state.player_position = player.global_position
	_player_state.player_rotation = player.global_rotation
	
	_player_state.player_health.x = player.health_component.current_health
	_player_state.player_health.y = player.health_component.max_health
	_player_state.player_stamina.x = player.stamina_component.current_stamina
	_player_state.player_stamina.y = player.stamina_component.max_stamina
	_player_state.player_sanity.x = player.sanity_component.current_sanity
	_player_state.player_sanity.y = player.sanity_component.max_sanity
	
	#Writing the state from current player interaction component:
	var current_player_interaction_component = player.player_interaction_component
	_player_state.clear_saved_interaction_component_state()
	_player_state.add_interaction_component_state_data_to_array(current_player_interaction_component.save())
	
	_player_state.write_state(slot)
#endregion


func load_scene_state(_scene_name_to_load:String, slot:String):
	print("CSM: Load scene state for:", _scene_name_to_load, ". Slot: ", slot)
	if _scene_state and _scene_state.state_exists(slot, _scene_name_to_load):
		print("CSM: Scene state exists. Loading ", _scene_state)
		_scene_state = _scene_state.load_state(slot,_scene_name_to_load) as CogitoSceneState
		
		# Deleting all current nodes that are in the Persist group as to not clone objects.
		var save_nodes = get_tree().get_nodes_in_group("Persist")
		for i in save_nodes:
			print("Deleting existing node: ", i)
			i.queue_free()
			
		var array_of_node_data = _scene_state.saved_nodes
		for node_data in array_of_node_data:
			var new_object = load(node_data["filename"]).instantiate()
			if get_node(node_data["parent"]):
				get_node(node_data["parent"]).add_child(new_object)
				print("Adding to scene: ", new_object.get_name())
			new_object.position = Vector3(node_data["pos_x"],node_data["pos_y"],node_data["pos_z"])
			new_object.rotation = Vector3(node_data["rot_x"],node_data["rot_y"],node_data["rot_z"])
			# Set the remaining variables.
			for data in node_data.keys():
				if data == "filename" or data == "parent" or data == "pos_x" or data == "pos_y" or data == "pos_z" or data == "rot_x" or data == "rot_y" or data == "rot_z":
					continue
				new_object.set(data, node_data[data])
		
		#Loading states of objects in Save_object_state
		var array_of_state_data = _scene_state.saved_states
		for state_data in array_of_state_data:
			var node_to_set = get_node(state_data["node_path"])
			# Set variables here
			node_to_set.position = Vector3(state_data["pos_x"],state_data["pos_y"],state_data["pos_z"])
			node_to_set.rotation = Vector3(state_data["rot_x"],state_data["rot_y"],state_data["rot_z"])
			for data in state_data.keys():
				if data == "filename" or data == "parent" or data == "pos_x" or data == "pos_y" or data == "pos_z" or data == "rot_x" or data == "rot_y" or data == "rot_z":
					continue
				node_to_set.set(data, state_data[data])
			node_to_set.set_state()
		
		print("CSM: Loading scene state finished.")
			
	else:
		print("CSM: Scene state doesn't exist.")


func save_scene_state(_scene_name_to_save, slot: String):
	if !_scene_state:
		print("CSM: Save doesn't exist. Creating...")
		_scene_state = CogitoSceneState.new()
		
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	if !save_nodes:
		print("No nodes in Persist group!")
	else:
		_scene_state.clear_saved_nodes() # Clearing out old saved nodes
	
		for node in save_nodes:
			if node.scene_file_path.is_empty(): # Check the node is an instanced scene so it can be instanced again during load.
				print("persistent node '%s' is not an instanced scene, skipped" % node.name)
				continue

			if !node.has_method("save"): # Check the node has a save function.
				print("persistent node '%s' is missing a save() function, skipped" % node.name)
				continue
		
			_scene_state.add_node_data_to_array(node.save())
	
	# Saving states of objects
	var state_nodes = get_tree().get_nodes_in_group("Save_object_state")
	if !state_nodes:
		print("No nodes in Save_object_state group!")
	else:
		_scene_state.clear_saved_states()
		
		for node in state_nodes:
			if !node.has_method("save"): # Check the node has a save function.
				print("persistent node '%s' is missing a save() function, skipped" % node.name)
				continue
				
			_scene_state.add_state_data_to_array(node.save())
			
	_scene_state.write_state(slot, _scene_name_to_save)


# Function to transition to another scene via the loading screen.
func load_next_scene(target : String, connector_name: String, passed_slot: String, loading_a_save : bool) -> void:
	var loading_screen = preload("res://COGITO/SceneManagement/LoadingScene.tscn").instantiate()
	loading_screen.next_scene_path = target
	loading_screen.connector_name = connector_name
	loading_screen.passed_slot = passed_slot
	loading_screen.attempt_to_load_save = loading_a_save
	get_tree().current_scene.add_child(loading_screen)


func reset_scene_states():
	# CREATE FUNCTION THAT DELETES SCENE STATE FILES.
	pass
