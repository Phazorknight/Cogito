class_name InteractionRayCast
extends RayCast3D


signal interactable_seen(interactable)
signal interactable_unseen()

var _interactable = null


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_update_interactable()


func _update_interactable() -> void:
	var collider = get_collider()
	var new_interactable = collider

	# Handle all colliders that aren't in interactable group as null.
	if collider != null and not collider.is_in_group("interactable"):
		new_interactable = null

	# If interactable hasn't changed, no actions required. Because we treat
	# non-interactables as null, we also avoid accidental false assignations.
	if new_interactable == _interactable and is_instance_valid(new_interactable):
		return

	# If we got this far, we have unseen the currently tracked interactable
	if _interactable != null:
		interactable_unseen.emit()

	_interactable = new_interactable
	
	# If we have a new tracked interactable, we have seen an interactable
	if _interactable != null:
		interactable_seen.emit(new_interactable)
		return

	interactable_unseen.emit()
