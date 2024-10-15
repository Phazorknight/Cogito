class_name InteractionShapeCast
extends ShapeCast3D


signal interactable_seen(interactable)
signal interactable_unseen()

var _interactable = null:
	set = _set_interactable


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	_update_interactable()


func _set_interactable(value) -> void:
	_interactable = value
	if _interactable == null:
		interactable_unseen.emit()
	else:
		interactable_seen.emit(_interactable)


func _update_interactable() -> void:
	if !is_colliding():
		return
	var collider = get_collider(0)

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

	if collider == _interactable:
		return

	# HACK: Turns out a null from the collider is/can be an object.
	# This changes it to an actual null, so the freed object handling
	# won't trigger on it.
	if collider == null and typeof(collider) != 0:
		collider = null

	_interactable = collider
