## A timed despawner class that despawns the parent node after a specified period of time.
class_name TimedDespawner extends Node3D

## Time in seconds that the parent should despawn and be removed from world.
@export var despawn_timer: float = 5.0
## Container to monitor, after the despawn timer runs out, will despawn this container and its children.
@export var container_to_monitor: CogitoContainer
## Internal boolean variable to do a final check so we don't accidentally despawn the entire scene tree :)
var cleared_for_despawning: bool = false
var container_inventory

# Internal variables to player
var _player: CogitoPlayer
var _player_hud: CogitoPlayerHudManager
var _timer: Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("_set_up_references")
	call_deferred("_create_timer")
	call_deferred("_clear_for_despawning")
	
	print("Time Remaining: " + str(_timer.time_left))

## Set up references to player and container in a deferred manner to avoid nulling
func _set_up_references():
	_player = get_tree().get_first_node_in_group("Player")
	_player_hud = _player.find_child("Player_HUD", true, true)
	container_inventory = container_to_monitor.inventory_data
	container_to_monitor.toggle_inventory.connect(_on_inventory_toggled)


## Set up a timer in deferred manner
func _create_timer():
	_timer = Timer.new()
	add_child(_timer)
	_timer.wait_time = despawn_timer
	_timer.one_shot = true
	_timer.timeout.connect(_on_despawn_timer_timeout)
	_timer.start()
	

## Green light for despawning
func _clear_for_despawning():
	if is_inside_tree() and get_parent() == null and get_tree().current_scene == self:
		cleared_for_despawning = false
	elif is_inside_tree() and get_parent() != null and get_tree().current_scene != self:
		cleared_for_despawning = true


## Despawn
func _on_despawn_timer_timeout():
	if cleared_for_despawning:
		if _player_hud != null:
			if _player_hud.inventory_interface.is_inventory_open:
				if _player_hud.inventory_interface.get_external_inventory() == container_to_monitor:
					_player_hud.inventory_interface.clear_external_inventory()

		if container_to_monitor.toggle_inventory.is_connected(_player_hud.toggle_inventory_interface):
			container_to_monitor.toggle_inventory.disconnect(_player_hud.toggle_inventory_interface)
			
		if container_to_monitor.toggle_inventory.is_connected(_on_inventory_toggled):
			container_to_monitor.toggle_inventory.disconnect(_on_inventory_toggled)

		get_parent().call_deferred("queue_free")
	else:
		return

## Pause the timer on inventory access
func _on_inventory_toggled(external_inventory_owner: Node):
	
	if container_to_monitor == external_inventory_owner:
		if _player_hud.inventory_interface.is_inventory_open:
			_timer.paused = true
		else:
			_timer.paused = false
	pass
