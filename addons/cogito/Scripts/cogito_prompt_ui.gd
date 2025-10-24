extends Control

## Some margin to keep the marker away from the screen's corners.
const MARGIN = 8

@export var use_spatial_prompt : bool = false

@onready var camera := get_viewport().get_camera_3d()
@onready var parent := get_parent()


func _physics_process(delta: float) -> void:
	#region CANCEL CONDITIONS	
	if !use_spatial_prompt:
		return
	
	var interactable = parent.player.player_interaction_component.interactable
	
	if interactable == null:
		visible = false
		return
	else:
		visible = true
	if not "prompt_pos_mode" in interactable:
		return
	
	if not camera or not camera.current:
		camera = get_viewport().get_camera_3d()
		if not camera:
			visible = false
			return
	#endregion
	
	var parent_position: Vector3
	match interactable.prompt_pos_mode:
		0: # Matching PromptPositionMode.ORIGIN
			parent_position = interactable.global_transform.origin
		1: # Matching PromptPositionMode.MARKER
			parent_position = interactable.prompt_marker.global_transform.origin
		2: # Matching PromptPositionMode.AABB
			parent_position = _get_interactable_center(interactable)
	
	#var camera_transform := camera.global_transform
	#var camera_position := camera_transform.origin
#
	## We would use "camera.is_position_behind(parent_position)", except
	## that it also accounts for the near clip plane, which we don't want.
	#var is_behind := camera_transform.basis.z.dot(parent_position - camera_position) > 0
#
	#var unprojected_position := camera.unproject_position(parent_position)
	## `get_size_override()` will return a valid size only if the stretch mode is `2d`.
	## Otherwise, the viewport size is used directly.
	var viewport_base_size: Vector2i = (
			get_viewport().content_scale_size if get_viewport().content_scale_size > Vector2i(0, 0)
			else get_viewport().size
	)
#
#
	## We need to handle the axes differently.
	## For the screen's X axis, the projected position is useful to us,
	## but we need to force it to the side if it's also behind.
	#if is_behind:
		#if unprojected_position.x < viewport_base_size.x / 2:
			#unprojected_position.x = viewport_base_size.x - MARGIN
		#else:
			#unprojected_position.x = MARGIN
#
	## For the screen's Y axis, the projected position is NOT useful to us
	## because we don't want to indicate to the user that they need to look
	## up or down to see something behind them. Instead, here we approximate
	## the correct position using difference of the X axis Euler angles
	## (up/down rotation) and the ratio of that with the camera's FOV.
	## This will be slightly off from the theoretical "ideal" position.
	#if is_behind or unprojected_position.x < MARGIN or \
			#unprojected_position.x > viewport_base_size.x - MARGIN:
		#var look := camera_transform.looking_at(parent_position, Vector3.UP)
		#var diff := angle_difference(look.basis.get_euler().x, camera_transform.basis.get_euler().x)
		#unprojected_position.y = viewport_base_size.y * (0.5 + (diff / deg_to_rad(camera.fov)))
#
	#position = Vector2(
			#clamp(unprojected_position.x, MARGIN, viewport_base_size.x - MARGIN),
			#clamp(unprojected_position.y, MARGIN, viewport_base_size.y - MARGIN)
	#)
	position = _convert_3d_pos_to_2d_pos(parent_position)
	
	##region overflow handling if prompt is outside of view
	#rotation = 0
	#var overflow := 0
	#if position.x <= MARGIN:
		## Left overflow.
		#overflow = int(-TAU / 8.0)
		##label.visible = false
		##rotation = TAU / 4.0
	#elif position.x >= viewport_base_size.x - MARGIN:
		## Right overflow.
		#overflow = int(TAU / 8.0)
		##label.visible = false
		#rotation = TAU * 3.0 / 4.0
#
	#if position.y <= MARGIN:
		## Top overflow.
		##label.visible = false
		#rotation = TAU / 2.0 + overflow
	#elif position.y >= viewport_base_size.y - MARGIN:
		## Bottom overflow.
		##label.visible = false
		#rotation = -overflow
	##endregion


func _convert_3d_pos_to_2d_pos(parent_position: Vector3) -> Vector2:
	var camera_transform := camera.global_transform
	var camera_position := camera_transform.origin

	# We would use "camera.is_position_behind(parent_position)", except
	# that it also accounts for the near clip plane, which we don't want.
	var is_behind := camera_transform.basis.z.dot(parent_position - camera_position) > 0

	var unprojected_position := camera.unproject_position(parent_position)
	# `get_size_override()` will return a valid size only if the stretch mode is `2d`.
	# Otherwise, the viewport size is used directly.
	var viewport_base_size: Vector2i = (
			get_viewport().content_scale_size if get_viewport().content_scale_size > Vector2i(0, 0)
			else get_viewport().size
	)


	# We need to handle the axes differently.
	# For the screen's X axis, the projected position is useful to us,
	# but we need to force it to the side if it's also behind.
	if is_behind:
		if unprojected_position.x < viewport_base_size.x / 2:
			unprojected_position.x = viewport_base_size.x - MARGIN
		else:
			unprojected_position.x = MARGIN

	# For the screen's Y axis, the projected position is NOT useful to us
	# because we don't want to indicate to the user that they need to look
	# up or down to see something behind them. Instead, here we approximate
	# the correct position using difference of the X axis Euler angles
	# (up/down rotation) and the ratio of that with the camera's FOV.
	# This will be slightly off from the theoretical "ideal" position.
	if is_behind or unprojected_position.x < MARGIN or \
			unprojected_position.x > viewport_base_size.x - MARGIN:
		var look := camera_transform.looking_at(parent_position, Vector3.UP)
		var diff := angle_difference(look.basis.get_euler().x, camera_transform.basis.get_euler().x)
		unprojected_position.y = viewport_base_size.y * (0.5 + (diff / deg_to_rad(camera.fov)))

	var _2d_pos = Vector2(
			clamp(unprojected_position.x, MARGIN, viewport_base_size.x - MARGIN),
			clamp(unprojected_position.y, MARGIN, viewport_base_size.y - MARGIN)
	)
	return _2d_pos


func _get_interactable_center(node: Node) -> Vector3:
	var aabb: AABB = _get_node_aabb(node)
	if aabb != AABB():
		return aabb.get_center()
	else:
		# Fallback: usa a origem se não houver geometria visual
		return node.global_transform.origin


func _get_node_aabb(node: Node) -> AABB:
	if node is VisualInstance3D:
		var local_aabb: AABB = node.get_aabb()
		if local_aabb.size != Vector3.ZERO:

			var transform: Transform3D = node.global_transform
			var global_aabb: AABB = transform * local_aabb
			return global_aabb

	if node is Node3D:
		var combined_aabb := AABB()
		for child in node.get_children():
			var child_aabb = _get_node_aabb(child)
			if child_aabb != AABB():
				if combined_aabb == AABB():
					combined_aabb = child_aabb
				else:
					combined_aabb = combined_aabb.merge(child_aabb)
		return combined_aabb

	return AABB()
