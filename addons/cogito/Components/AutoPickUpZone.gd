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


func _ready() -> void:
	player = get_parent()


func _on_body_entered(body: Node3D) -> void:
	_attempt_pick_up(body)


func _physics_process(_delta) -> void:
	_update_shape()


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
		
		if auto_pick_up_items.has(pick_up_component.slot_data.inventory_item):
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
