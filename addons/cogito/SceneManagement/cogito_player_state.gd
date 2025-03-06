class_name CogitoPlayerState
extends Resource

var player_state_dir : String = CogitoSceneManager.cogito_state_dir + CogitoSceneManager.cogito_player_state_prefix

@export var version : int = 1
@export var player_inventory : CogitoInventory

@export var player_quickslots : Array[InventorySlotPD]

@export var saved_wieldable_charges : Array

@export var player_current_scene : String
@export var player_current_scene_path : String
@export var player_position : Vector3
@export var player_rotation : Vector3
@export var player_try_crouch : bool

#Using Vector2 for saving player attributes. X = current, Y = max.
@export var player_health: Vector2
@export var player_stamina : Vector2
@export var player_sanity : Vector2

#New way of saving player attributes
@export var player_attributes : Dictionary

# Saving currencies
@export var player_currencies : Dictionary

# Saving world dict
@export var world_dictionary : Dictionary

#Saving parameters from the player interaction component
@export var interaction_component_state : Array

#Saving quests:
@export var player_active_quests : Array[CogitoQuest]
@export var player_completed_quests : Array[CogitoQuest]
@export var player_failed_quests : Array[CogitoQuest]

#Saving some extra data for save game management/UI
@export var player_state_screenshot_file : String
@export var player_state_savetime : int
@export var player_state_slot_name : String

# Sitting vars
@export var is_sitting: bool = false
@export var sittable_look_marker: Vector3 = Vector3()
@export var sittable_look_angle: float = 0.0
@export var moving_seat: bool = false
@export var displacement_position: Vector3 = Vector3()
@export var original_position: Transform3D = Transform3D()
@export var original_neck_basis: Basis = Basis()
@export var is_ejected: bool = false
@export var currently_tweening: bool = false
@export var current_sittable_path: NodePath

#Collision shapes
@export var standing_collision_shape_enabled : bool = true
@export var crouching_collision_shape_enabled : bool = false


@export var body_transform: Transform3D
@export var neck_transform: Transform3D
@export var head_transform: Transform3D
@export var eyes_transform: Transform3D
@export var camera_transform: Transform3D


func save_node_transforms(player):
	body_transform = player.get_node("Body").transform
	neck_transform = player.get_node("Body/Neck").transform
	head_transform = player.get_node("Body/Neck/Head").transform
	eyes_transform = player.get_node("Body/Neck/Head/Eyes").transform
	camera_transform = player.get_node("Body/Neck/Head/Eyes/Camera").transform


func load_node_transforms(player):
	player.get_node("Body").transform = body_transform
	player.get_node("Body/Neck").transform = neck_transform
	player.get_node("Body/Neck/Head").transform = head_transform
	player.get_node("Body/Neck/Head/Eyes").transform = eyes_transform
	player.get_node("Body/Neck/Head/Eyes/Camera").transform = camera_transform


# Save the state of the player's collision shapes
func save_collision_shapes(player):
	standing_collision_shape_enabled = not player.standing_collision_shape.disabled
	crouching_collision_shape_enabled = not player.crouching_collision_shape.disabled


# Load the state of the player's collision shapes
func load_collision_shapes(player):
	player.standing_collision_shape.disabled = not standing_collision_shape_enabled
	player.crouching_collision_shape.disabled = not crouching_collision_shape_enabled


func save_sitting_state(player):
	is_sitting = player.is_sitting
	sittable_look_marker = player.sittable_look_marker if player.is_sitting else Vector3()
	sittable_look_angle = player.sittable_look_angle if player.is_sitting else 0.0
	moving_seat = player.moving_seat
	displacement_position = player.displacement_position if player.is_sitting else Vector3()
	original_position = player.original_position if player.is_sitting else Transform3D()
	original_neck_basis = player.original_neck_basis if player.is_sitting else Basis()
	is_ejected = player.is_ejected
	currently_tweening = player.currently_tweening
	if is_sitting:
		current_sittable_path = CogitoSceneManager._current_sittable_node.get_path()


func load_sitting_state(player):
	player.is_sitting = is_sitting
	player.sittable_look_marker = sittable_look_marker
	player.sittable_look_angle = sittable_look_angle
	player.moving_seat = moving_seat
	player.displacement_position = displacement_position
	player.original_position = original_position
	player.original_neck_basis = original_neck_basis
	player.is_ejected = is_ejected
	player.currently_tweening = currently_tweening
	if is_sitting and current_sittable_path != null:
		CogitoSceneManager._current_sittable_node = CogitoSceneManager.get_node(current_sittable_path)


# Functions for attributes
func add_player_attribute_to_state_data(name: String, attribute_data:Vector2):
	player_attributes[name] = attribute_data


func clear_saved_attribute_data():
	player_attributes.clear()


# Functions for currencies
func add_player_currency_to_state_data(name: String, currency_data:Vector2):
	player_currencies[name] = currency_data


func clear_saved_currency_data():
	player_currencies.clear()


# Functions for world dictionary
func add_to_world_dictionary(world_property_name: String, world_property_data):
	if world_dictionary.has(world_property_name):
		world_dictionary[world_property_name] = world_property_data
		CogitoGlobals.debug_log(true, "CogitoPlayerState", "world dict key found and value saved: " + str(world_property_name) + " " + str(world_property_data) )
	else:
		world_dictionary.get_or_add(world_property_name)
		world_dictionary[world_property_name] = world_property_data
		CogitoGlobals.debug_log(true, "CogitoPlayerState", "world dict key not found. Added and value saved: " + str(world_property_name) + " " + str(world_property_data) )


func clear_world_dictionary():
	world_dictionary.clear()


func add_interaction_component_state_data_to_array(state_data):
	interaction_component_state.append(state_data)


func clear_saved_interaction_component_state():
	interaction_component_state.clear()


func append_saved_wieldable_charges(saved_item_data):
	saved_wieldable_charges.append(saved_item_data)

func clear_saved_wieldable_charges():
	saved_wieldable_charges.clear()


func write_state(state_slot : String) -> void:
	var dir = DirAccess.open(CogitoSceneManager.cogito_state_dir)
	dir.make_dir(str(state_slot))
	var player_state_file = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_player_state_prefix + ".res")
	#var player_state_file = str(player_state_dir + state_slot + ".res")
	ResourceSaver.save(self, player_state_file, ResourceSaver.FLAG_CHANGE_PATH)
	CogitoGlobals.debug_log(true, "CogitoPlayerState", "Player state saved as " + str(player_state_file) )


func state_exists(state_slot : String) -> bool:
	#var player_state_file = str(player_state_dir + state_slot + ".res")
	var player_state_file = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_player_state_prefix + ".res")
	#return ResourceLoader.exists(player_state_file)
	return FileAccess.file_exists(player_state_file)
 

func load_state(state_slot : String) -> Resource:
	#var player_state_file = str(player_state_dir + state_slot + ".res")
	var player_state_file = str(CogitoSceneManager.cogito_state_dir + state_slot + "/" + CogitoSceneManager.cogito_player_state_prefix + ".res")
	return ResourceLoader.load(player_state_file, "", ResourceLoader.CACHE_MODE_IGNORE)
	
