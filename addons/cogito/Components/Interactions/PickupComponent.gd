extends InteractionComponent
class_name PickupComponent

@export var slot_data : InventorySlotPD
@export var display_item_name : bool = false

var player_interaction_component


func _enter_tree() -> void:
	if display_item_name:
		var owner_object : CogitoObject = get_parent()
		owner_object.display_name = slot_data.inventory_item.name


func interact(_player_interaction_component: PlayerInteractionComponent):
	if !is_disabled:
		pick_up(_player_interaction_component)


func pick_up(_player_interaction_component: PlayerInteractionComponent):
	### Currency Item handling
	if slot_data.inventory_item is CurrencyItemPD and slot_data.inventory_item.add_on_pickup:
		if slot_data.inventory_item.use(_player_interaction_component.get_parent()):
			#_player_interaction_component.send_hint(slot_data.inventory_item.hint_icon_on_use, slot_data.inventory_item.hint_text_on_use)
			Audio.play_sound(slot_data.inventory_item.sound_pickup)
			was_interacted_with.emit(interaction_text, input_map_action)
			self.get_parent().queue_free()
			return
		else:
			_player_interaction_component.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " couldn't be picked up.")
			return
	
	if not _player_interaction_component.get_parent().inventory_data.pick_up_slot_data(slot_data):
		return

	# Update wieldable UI if we have picked up ammo for current wieldable
	# TODO: Possibly replace with a better solution, maybe by signaling the change
	# to the UI instead of having the PlayerInteractionComponent doing it.
	if _player_interaction_component.is_wielding:
		var is_ammo: bool = "reload_amount" in slot_data.inventory_item
		var is_current_ammo: bool = _player_interaction_component.equipped_wieldable_item.ammo_item_name == slot_data.inventory_item.name
		if is_ammo and is_current_ammo:
			var equipped_wieldable = _player_interaction_component.equipped_wieldable_item
			if equipped_wieldable.charge_current < equipped_wieldable.charge_max:
				_player_interaction_component.equipped_wieldable_item.update_wieldable_data(_player_interaction_component)

	_player_interaction_component.send_hint(slot_data.inventory_item.icon, slot_data.inventory_item.name + " added to inventory.")
	was_interacted_with.emit(interaction_text, input_map_action)
	Audio.play_sound(slot_data.inventory_item.sound_pickup)
	self.get_parent().queue_free()
