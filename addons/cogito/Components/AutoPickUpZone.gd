@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_AutoPickUpZone.svg")
class_name AutoPickUpZone
extends Area3D

signal auto_picked_up_item()

# This is useful when you have pick up items that are frustrating, tedious, or required
# and provides a smoother experience than only using the default raycasting + input interaction.

## Items listed here will be picked up automatically when they enter the area
@export var auto_pick_up_items: Array[InventoryItemPD] = []
@export var _player_interaction_component: PlayerInteractionComponent
var player: CogitoPlayer
@onready var standing_collider: CollisionShape3D = $StandingZone
@onready var crouching_collider: CollisionShape3D = $CrouchingZone

# Variables used for pooling the pickup processing to smooth out processing large amounts of pickup items.
@export var defer_queue_processing : bool = false
var _last_index := -1
var pickup_item_pool : Array[CogitoObject] = []
var is_processing_queue : bool = false
# Added as a workaround for items that use Local To Scene.
var auto_pick_up_items_by_name : Array[String] = []


func _ready() -> void:
	player = get_parent()
	for item in auto_pick_up_items:
		auto_pick_up_items_by_name.append(item.name)


func _on_body_entered(body: Node3D) -> void:
	if body is CogitoObject:
		pickup_item_pool.append(body)
		is_processing_queue = true
		#_attempt_pick_up(body)


func _physics_process(_delta) -> void:
	_update_shape()
	if is_processing_queue:
		if defer_queue_processing:
			process_pickup_queue.call_deferred()
		else: 
			process_pickup_queue()
		


func process_pickup_queue() -> void:
	if pickup_item_pool.size() > 0:
		var pickup = get_pickup_from_queue()
		if is_instance_valid(pickup):
			_attempt_pick_up(pickup)
			pickup_item_pool.remove_at(_last_index)
	else:
		is_processing_queue = false
	pass

func get_pickup_from_queue() -> CogitoObject:
	_last_index = wrapi(_last_index + 1, 0, pickup_item_pool.size())
	#print("get_pickup_from_queue results: _last_index=", _last_index, ". item found: ", pickup_item_pool[_last_index].name)
	return pickup_item_pool[_last_index]


func _update_shape() -> void:
	# Uses a shorter collision cylinder when crouching
	if player.is_crouching:
		if !standing_collider.disabled:
			standing_collider.disabled = true
		if crouching_collider.disabled:
			crouching_collider.disabled = false
	else:
		if standing_collider.disabled:
			standing_collider.disabled = false
		if !crouching_collider.disabled:
			crouching_collider.disabled = true


func _attempt_pick_up(body: Node3D) -> void:
	var child_count: int = body.get_child_count()
	# search recursively as PickupComponents tend to be childed near the back
	for i in range(child_count-1, -1, -1):
		if body.get_child(i) is not PickupComponent:
			continue
		
		var pick_up_component = body.get_child(i) as PickupComponent
		# This prevents cogito projectiles
		if body is CogitoProjectile and !(body as CogitoProjectile).can_pick_up:
			continue
		
		var inventory_item: InventoryItemPD = pick_up_component.slot_data.inventory_item
		if auto_pick_up_items.has(inventory_item) or auto_pick_up_items_by_name.has(inventory_item.name):
			pick_up_component.interact(_player_interaction_component)
			auto_picked_up_item.emit()
		# Exit loop after detecting a pick up component (should only be one)
		break


# TODO: may require save functionality to properly implement altering the item list
#func new_item_list(new_items: Array[InventoryItemPD]) -> void:
	#auto_pick_up_items = new_items.duplicate()
	#CogitoGlobals.debug_log(true,"AutoPickUpZone.gd", "Created a new auto pick up list")
#
#
#func add_item_to_list(item: InventoryItemPD) -> void:
	#if !auto_pick_up_items.has(item):
		#auto_pick_up_items.append(item)
		#CogitoGlobals.debug_log(true,"AutoPickUpZone.gd", "Added %s to auto pick up list" % item.name)
#
#
#func remove_item_from_list(item: InventoryItemPD) -> void:
	#if auto_pick_up_items.has(item):
		#auto_pick_up_items.erase(item)
		#CogitoGlobals.debug_log(true,"AutoPickUpZone.gd", "Removed %s from auto pick up list" % item.name)
