extends InteractionComponent
class_name PickupComponent

@export var slot_data : InventorySlotPD

var player_interaction_component

func interact(_player_interaction_component: PlayerInteractionComponent):
	if !is_disabled:
		pick_up(_player_interaction_component)


func pick_up(_player_interaction_component: PlayerInteractionComponent):
	if not _player_interaction_component.get_parent().inventory_data.pick_up_slot_data(slot_data):
		return

	# Update wieldable UI if we have picked up ammo for current wieldable
	# TODO: Possibly replace with a better solution, maybe by signaling the change
	# to the UI instead of having the PlayerInteractionComponent doing it.
	if _player_interaction_component.is_wielding:
		var is_ammo: bool = "reload_amount" in slot_data.inventory_item
		var is_current_ammo: bool = _player_interaction_component.equipped_wieldable_item.ammo_item_name == slot_data.inventory_item.name
		if is_ammo and is_current_ammo:
			_player_interaction_component.equipped_wieldable_item.update_wieldable_data(_player_interaction_component)

	_player_interaction_component.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " added to inventory.")
	was_interacted_with.emit(interaction_text, input_map_action)
	Audio.play_sound(slot_data.inventory_item.sound_pickup)
	self.get_parent().queue_free()


func get_item_type() -> int:
	if slot_data and slot_data.inventory_item:
		return slot_data.inventory_item.item_type
	else:
		return -1
