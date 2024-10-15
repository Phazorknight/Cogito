extends Area3D

## Reference to the door that will get upated
@export var door_to_set : NodePath
## Setting the new open rotation position in degrees.
@export var new_open_rotation_deg : float
## Check this is the door is changing transform position instead of rotation
@export var is_sliding : bool
## The new open position transform coordinates
@export var new_open_pos : Vector3
## Check this is the door is animation based
@export var is_using_animations : bool
## Name of the new opening animation. This has to exist in the door's animation player to work.
@export var new_opening_animation : String

## Set if the door should close automatically after the player leaves the zone.
@export var close_door_on_exit : bool = false
## Set if the door should open automatically when player enters the zone.
@export var open_door_on_enter : bool = false
## Time delay when door closes. Should be at least 1-2 seconds.
@export var close_delay : float = 3.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	
func _on_body_entered(body: Node3D):
	if !body.is_in_group("Player"):
		return
	
	if door_to_set != null:
		var door = get_node(door_to_set)
		
		if open_door_on_enter and !door.is_locked:
			door.open_door()
		
		if is_sliding:
			door.open_position = new_open_pos
		elif is_using_animations:
			door.opening_animation = new_opening_animation
		else:
			door.open_rotation_deg = new_open_rotation_deg
	

func _on_body_exited(body: Node3D):
	if !body.is_in_group("Player"):
		return
	
	if door_to_set!= null and close_door_on_exit:
		var door = get_node(door_to_set)
		await get_tree().create_timer(close_delay).timeout
		door.close_door()
