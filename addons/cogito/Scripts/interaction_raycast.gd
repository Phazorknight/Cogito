class_name InteractionRayCast
extends RayCast3D

signal interactable_seen(interactable)
signal interactable_unseen()

@onready var shapecast : ShapeCast3D = $InteractionShapecast
# currently a node, but could just be an offset position
# if shapecasting, the collider closest to the hotspot's position is used
@onready var hotspot : Node3D = $ShapecastHotspot
# the starting position of the hotspot, which is closer to the raycast target position
var hotspot_base_pos_z : float = -1.5

# DEBUGGING
@onready var raycast_highlighter = $RaycastHighlighter
@onready var target_highlighter = $TargetHighlighter


@export var show_debug_shapes : bool = false

var _interactable = null:
	set = _set_interactable


func _ready() -> void:
	if hotspot != null:
		hotspot_base_pos_z = hotspot.transform.origin.z
	if !show_debug_shapes:
		raycast_highlighter.visible = false
		target_highlighter.visible = false


func _process(_delta: float) -> void:
	_update_interactable()


func _set_interactable(value) -> void:
	_interactable = value
	if _interactable == null:
		interactable_unseen.emit()
	else:
		interactable_seen.emit(_interactable)


func _update_interactable() -> void:
	var raycasted_collider = get_collider()
	# populate with any raycasted collider, else with any shapecasted collider
	var collider = raycasted_collider
	# used for positioning the hotspot to refine shapecasted target selection
	var hotspot_global_position: Vector3 = get_collision_point() if collider else global_position

	if show_debug_shapes: 	# DEBUGGING
		target_highlighter.visible = false

	# Handle freed objects.
	# is_instance_valid() will be false for null and for freed objects, but only
	# null will return 0 for typeof()
	if not is_instance_valid(_interactable):
		if typeof(_interactable) != 0:
			_interactable = null
			return

	# Handle all colliders that aren't in the interactable group as null.
	if collider != null and not collider.is_in_group("interactable"):
		collider = null
		
		# conver the global position to local position and move
		# the hotspot out to the distance of the hit point to better
		# predict what the player seems to intend to interact with
		# **this could be a problem when attempting to interact around corners**
		hotspot.transform.origin = to_local(hotspot_global_position)
		
		if show_debug_shapes: 	# DEBUGGING
			raycast_highlighter.global_position = hotspot_global_position
			raycast_highlighter.visible = true
	else:
		# set the hotspot to the base position if not raycasting anything
		hotspot.transform.origin = Vector3(0.0, 0.0, hotspot_base_pos_z)
		
		if show_debug_shapes: 	# DEBUGGING
			raycast_highlighter.transform.origin = Vector3(0.0, 0.0, hotspot_base_pos_z)
			raycast_highlighter.visible = false


	# if not raycasting a collider, then attempt a shapecast
	if collider == null:
		if shapecast.is_colliding():
			# select the closest of all colliders detected by the shapecast
			var closest_distance = INF
			for i in range(shapecast.get_collision_count()):
				var shape_collider = shapecast.get_collider(i)
				if shape_collider != null and shape_collider.is_in_group("interactable"):
					var collision_point = shapecast.get_collision_point(i)
					#print("shapecast colliding with %s" % shape_collider)
					var distance = collision_point.distance_squared_to(hotspot_global_position)
					# always return the closest interactable to the hotspot's global position
					if distance < closest_distance:
						collider = shape_collider
						closest_distance = distance
						
						if show_debug_shapes: 	# DEBUGGING
							target_highlighter.global_position = collision_point
							target_highlighter.visible = true
	else:
		if show_debug_shapes: 	# DEBUGGING
			target_highlighter.global_position = hotspot_global_position
			target_highlighter.visible = true

	if collider == _interactable:
		return

	# HACK: Turns out a null from the collider is/can be an object.
	# This changes it to an actual null, so the freed object handling
	# won't trigger on it.
	if collider == null and typeof(collider) != 0:
		collider = null

	_interactable = collider
