## A despawner helper to despawn a spawned Cogito container after all items has been taken out of it. 
class_name EmptiedDespawner extends Node

## Container to monitor, if this container is empty, will despawn this container.
@export var container_to_monitor: CogitoContainer

var container_inventory
var inventory_slot_data

# Internal variables to player
var _player: CogitoPlayer
var _player_hud: CogitoPlayerHudManager


func _ready() -> void:
	
	_player = get_tree().get_first_node_in_group("Player")
	_player_hud = _player.find_child("Player_HUD", true, true)
	
	container_inventory = container_to_monitor.inventory_data
	inventory_slot_data = container_inventory.inventory_slots

	if !container_inventory.inventory_updated.is_connected(_on_inventory_updated):
		container_inventory.inventory_updated.connect(_on_inventory_updated)


func _on_inventory_updated(inventory_data : CogitoInventory):
	
	inventory_slot_data = inventory_data.inventory_slots
	var items_in_slots: Array[InventoryItemPD] = []
	
	if inventory_slot_data != null:
		for _slots in inventory_slot_data:
			if _slots != null:
				if _slots.inventory_item != null:
					items_in_slots.append(_slots.inventory_item)
					
		if items_in_slots.is_empty():
			if _player_hud.inventory_interface.is_inventory_open:
				if _player_hud.inventory_interface.get_external_inventory() == container_to_monitor:
					_player_hud.inventory_interface.clear_external_inventory()
				
			if container_inventory.inventory_updated.is_connected(_on_inventory_updated):
				container_inventory.inventory_updated.disconnect(_on_inventory_updated)
				
			if container_to_monitor.toggle_inventory.is_connected(_player_hud.toggle_inventory_interface):
				container_to_monitor.toggle_inventory.disconnect(_player_hud.toggle_inventory_interface)
			
			get_parent().call_deferred("queue_free")
