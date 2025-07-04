@icon("res://addons/cogito/Assets/Graphics/Editor/Icon_AutoConsume.svg")
class_name AutoConsume
extends Node

## The value beyond which the first valid consumables in inventory will automatically be used.
## For consume on increase, any value above this will attempt to auto-consume.
## For health, in order for auto-consume to prevent death, set this value above zero.
## A value of zero receives the attribute signal "attribute_reached_zero".
## Non-zero values receive the attribute signal "attribute_changed".
@export var threshold_value: float = 0.0
## Auto-consume when the attribute value increases above the threshold value.
## By default auto-consumes when the attribute value decreases below the threshold value.
@export var consume_on_increase: bool
## Always auto-consume an item that increases the max value of this attribute (value_to_change == ValueType.MAX).
## Receives the inventory signal "picked_up_new_inventory_item".
@export var consume_if_increases_max: bool
## A list of valid consumables that can be auto-consumed when the attribute falls below the threshold value. Only the first valid item found will be consumed.
@export var consumables: Array[ConsumableItemPD] = []

## Icon that is displayed with the hint that pops up when used. If left blank, the default hint icon is shown.
@export var hint_icon_on_use : Texture2D
## Hint that is displayed when used."
@export var hint_text_on_use : String = "Auto-consumed"

## The player attribute name, assigned by the subclass.
var attribute_name: String = ""
var last_value_current: float
var last_value_max: float
var attribute: CogitoAttribute

# Must be called from _ready in subclass
func initialize_auto_consume() -> void:
	if !consumables or consumables.size() == 0:
		CogitoGlobals.debug_log(true, "AutoConsume", "No consumables added to the " + attribute_name + " attribute's auto-consume list.")
		return
	
	await get_tree().process_frame
	var player: CogitoPlayer = get_parent() as CogitoPlayer
	attribute = player.player_attributes[attribute_name]
	# This signal must be connected to an AutoConsume subclass
	player.connect("player_state_loaded", Callable(self, "_on_player_state_loaded"))
	if consume_if_increases_max:
		var inventory: CogitoInventory = player.inventory_data as CogitoInventory
		inventory.connect("picked_up_new_inventory_item", Callable(self, "_on_picked_up_new_inventory_item"))
	
	if threshold_value == 0.0:
		attribute.connect("attribute_reached_zero", Callable(self, "_on_attribute_reached_zero"))
	else:
		attribute.connect("attribute_changed", Callable(self, "_on_attribute_changed"))
	
	_update_values()


# Signal must be connected to the subclass
func _on_player_state_loaded() -> void:
	_update_values()
	attribute = (get_parent() as CogitoPlayer).player_attributes[attribute_name]
	
	if consume_if_increases_max:
		# Inventory is rebuilt, so reconnect the signal
		var inventory: CogitoInventory = (get_parent() as CogitoPlayer).inventory_data as CogitoInventory
		inventory.connect("picked_up_new_inventory_item", Callable(self, "_on_picked_up_new_inventory_item"))


func _on_attribute_changed(_attribute_name:String, _value_current:float, _value_max:float, has_increased:bool) -> void:
	if consume_if_increases_max and _value_max > last_value_max:
		_auto_consume(true)
	elif consume_on_increase and has_increased and _value_current != _value_max and _value_current > threshold_value:
		_auto_consume(false)
	elif !has_increased and _value_current < threshold_value:
		if self is HealthAutoConsume and _value_current <= 0.0:
			(self as HealthAutoConsume).prevent_death(_value_current)
		else:
			_auto_consume(false)
	_update_values()


# Loop through player inventory and consume the first valid consumable
func _auto_consume(value_max_increased: bool, remainder: float = 0.0) -> void:
	var inventory_slots : Array[InventorySlotPD] = (get_parent() as CogitoPlayer).inventory_data.inventory_slots
	for inventory_slot in inventory_slots:
		if !inventory_slot or !inventory_slot.inventory_item:
			continue
		
		if inventory_slot.inventory_item is ConsumableItemPD:
			for consumable in consumables:
				if consumable.name != inventory_slot.inventory_item.name or consumable.attribute_name != attribute_name:
					continue
				if consumable.attribute_change_amount == 0.0: # Shouldn't occur
					continue
				if consumable.value_to_change == ConsumableEffect.ValueType.MAX and !value_max_increased:
					continue
				# Used if the remainder between value_current and last_value_current is set
				# Used when health is depleted to see if a consumable can offset the remaining damage_value that was suffered
				if remainder > 0.0 and consumable.attribute_change_amount <= remainder:
					CogitoGlobals.debug_log(true, "AutoConsume", consumable.name + " isn't effective enough to be used.")
					continue
				
				_consume_item(inventory_slot)
				break
		break
	_update_values()


# Only called if consume_on_max_increase is true and adding a new item to inventory
func _on_picked_up_new_inventory_item(slot_data: InventorySlotPD) -> void:
	if !slot_data or !slot_data.inventory_item:
		return
	if slot_data.inventory_item is not ConsumableItemPD:
		return
	if (slot_data.inventory_item as ConsumableItemPD).attribute_change_amount == 0.0:
		return
	
	for consumable in consumables:
		if consumable.name != slot_data.inventory_item.name or consumable.attribute_name != attribute_name:
			continue
		if consumable.attribute_change_amount == 0.0:
			continue
		if consumable.value_to_change != ConsumableEffect.ValueType.MAX:
			continue
		
		_consume_item(slot_data)
		break
	_update_values()


# Only called if the threshold_value is set to zero
func _on_attribute_reached_zero(_attribute_name:String, _value_current:float, _value_max:float) -> void:
	_auto_consume(false)
	_update_values()


func _update_values() -> void:
	last_value_current = attribute.value_current
	last_value_max = attribute.value_max


func _consume_item(slot_data: InventorySlotPD) -> void:
	(get_parent() as CogitoPlayer).inventory_data.use_slot_data(slot_data.origin_index)
	CogitoGlobals.debug_log(true, "AutoConsume", "Auto-consumed " + slot_data.inventory_item.name + " for " + attribute_name)
	
	if hint_text_on_use != "":
		(get_parent() as CogitoPlayer).player_interaction_component.send_hint(hint_icon_on_use, hint_text_on_use + " " + str(slot_data.inventory_item.name))
