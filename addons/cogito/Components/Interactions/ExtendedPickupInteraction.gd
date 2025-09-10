class_name ExtendedPickupInteraction
extends HoldInteraction

signal on_hold_complete(player_interaction_component:PlayerInteractionComponent)
signal interaction_complete(player_interaction_component: PlayerInteractionComponent)

@export var hold_interaction_text: String = "INTERFACE_Use"
## Add a linebreak here to separate the pickup interaction text from the hold interaction text
@export_multiline var separator_text: String = " | "
var pickup: PickupComponent


func _ready() -> void:
	if parent_node.has_signal("object_state_updated"):
		parent_node.object_state_updated.connect(_on_object_state_change)
	
	pickup = get_parent().get_node_or_null("PickupComponent") as PickupComponent
	if !pickup or pickup is not PickupComponent or !pickup.slot_data or !pickup.slot_data.inventory_item:
		CogitoGlobals.debug_log(true, "ExtendedPickupInteraction", "ExtendedPickupInteraction can't find a pickup component")
		is_disabled = true
		return
	
	interaction_text = tr(pickup.interaction_text) + tr(separator_text) + tr(hold_interaction_text)
	
	pickup.is_disabled = true
	
	# Must be arranged above the PickupComponent to work properly when setting interaction prompts
	await get_tree().process_frame
	parent_node.move_child(self,  pickup.get_index())


func interact(_player_interaction_component):
	if !is_disabled:
		was_interacted_with.emit(interaction_text, input_map_action)
		player_interaction_component = _player_interaction_component
		
		var hud_path := NodePath(_player_interaction_component.player.player_hud)
		var hud = _player_interaction_component.player.get_node(hud_path) as CogitoPlayerHudManager
		if !hud.hold_ui.is_holding:
			hud.hold_ui.start_holding(self)


func _on_object_state_change(_interaction_text: String):
	pass


func use() -> void:
	if pickup.slot_data.inventory_item is ConsumableItemPD:
		consume(pickup.slot_data.inventory_item)
	elif pickup.slot_data.inventory_item is AmmoItemPD:
		attempt_reload_current_wieldable(pickup.slot_data.inventory_item)
	elif pickup.slot_data.inventory_item is WieldableItemPD:
		attempt_wield(pickup.slot_data.inventory_item)


## For Consumables: Disable and hide prompt if attribute is maxed out
## For Ammo: Hide prompt if inventory has space or wieldable is maxed with ammo
## For Wieldables: Hide prompt if 
func set_disabled(player: CogitoPlayer) -> bool:
	if !pickup:
		is_disabled = true
		return is_disabled
	
	player_interaction_component = player.player_interaction_component
	var item:= pickup.slot_data.inventory_item
	if item is ConsumableItemPD:
		var consumable: ConsumableItemPD = item as ConsumableItemPD
		if player.player_attributes.has(consumable.attribute_name):
			var attribute: CogitoAttribute = player.player_attributes[consumable.attribute_name] as CogitoAttribute
			if consumable.value_to_change == ConsumableItemPD.ValueType.CURRENT:
				is_disabled = attribute.value_current == attribute.value_max
			elif consumable.value_to_change == ConsumableItemPD.ValueType.MAX:
				is_disabled = false # Since there's no limit to max, always allow it
	elif item is AmmoItemPD:
		if player_interaction_component.is_wielding:
			is_disabled = cant_reload_current_wieldable()
		else:
			is_disabled = true
	elif item is WieldableItemPD:
		# Disable if no space in inventory
		is_disabled = player_interaction_component.is_carrying or !player_interaction_component.player.inventory_data.can_pick_up_slot_data(pickup.slot_data)
	
	# Invert pickup is_disabled state based on this disabled state
	pickup.is_disabled = !is_disabled
	
	return is_disabled


#region Consumables
## Called if the PickupComponent item is a ConsumableItem type
func consume(consumable: ConsumableItemPD) -> void:
	consumable.use(player_interaction_component.player)
	player_interaction_component.interaction_raycast._set_interactable(null)
	was_interacted_with.emit(interaction_text, input_map_action)
	Audio.play_sound(consumable.sound_pickup)
	get_parent().queue_free()
#endregion


#region Ammos
## Called if the PickupComponent item is an AmmoItem type
func cant_reload_current_wieldable() -> bool:
	if player_interaction_component.equipped_wieldable_node.animation_player.is_playing():
		return true
	if player_interaction_component.equipped_wieldable_item.ammo_item_name != pickup.slot_data.inventory_item.name:
		return true
	if player_interaction_component.equipped_wieldable_item.no_reload:
		return true
	
	var ammo_needed: int = abs(player_interaction_component.equipped_wieldable_item.charge_max - player_interaction_component.equipped_wieldable_item.charge_current)
	return ammo_needed <= 0


## Called if the PickupComponent item is an AmmoItem type. 
## Based on the attempt_reload function in PIC, but doesn't reference player inventory and just looks at the pickup itself
func attempt_reload_current_wieldable(ammo: AmmoItemPD) -> void:
	if player_interaction_component.equipped_wieldable_node.animation_player.is_playing():
		return
	if player_interaction_component.equipped_wieldable_item.ammo_item_name != ammo.name:
		return
	if player_interaction_component.equipped_wieldable_item.no_reload:
		return
	
	var ammo_needed: int = abs(player_interaction_component.equipped_wieldable_item.charge_max - player_interaction_component.equipped_wieldable_item.charge_current)
	if ammo_needed <= 0:
		return
	
	player_interaction_component.equipped_wieldable_node.reload()
	
	var quantity_needed: int = ceili(float(ammo_needed) / ammo.reload_amount)
	var ammo_used: int = 0
	var free_ammo: bool
	
	if pickup and pickup.slot_data:
		if pickup.slot_data.quantity <= quantity_needed:
			ammo_used = ammo.reload_amount * pickup.slot_data.quantity
			free_ammo = true
		elif pickup.slot_data.quantity > quantity_needed:
			ammo_used = ammo.reload_amount * quantity_needed
			pickup.slot_data.quantity -= quantity_needed
	
	player_interaction_component.equipped_wieldable_item.add(ammo_used)
	ammo_needed -= ammo_used
	
	player_interaction_component.equipped_wieldable_item.update_wieldable_data(player_interaction_component)
	was_interacted_with.emit(interaction_text, input_map_action)
	Audio.play_sound(ammo.sound_pickup)
	
	if free_ammo:
		player_interaction_component.interaction_raycast._set_interactable(null)
		get_parent().queue_free()
#endregion


#region Wieldables
func attempt_wield(wieldable: WieldableItemPD) -> void:
	if player_interaction_component.is_changing_wieldables:
		return
	
	if player_interaction_component.player.inventory_data.pick_up_slot_data(pickup.slot_data):
		if player_interaction_component.is_wielding:
			player_interaction_component.equipped_wieldable_item.put_away()
			await get_tree().create_timer(player_interaction_component.equipped_wieldable_node.animation_player.current_animation_length).timeout 
	
		wieldable.use(player_interaction_component.player)
		was_interacted_with.emit(interaction_text, input_map_action)
		Audio.play_sound(wieldable.sound_pickup)
		player_interaction_component.interaction_raycast._set_interactable(null)
		get_parent().queue_free()
	else:
		player_interaction_component.send_hint(wieldable.icon, wieldable.name + " couldn't be picked up.")
#endregion
