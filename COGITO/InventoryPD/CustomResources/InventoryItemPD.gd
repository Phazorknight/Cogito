@tool
extends Resource
class_name InventoryItemPD

#@export_enum("Consumable", "Wieldable", "Combinable", "Key") var item_type
enum ItemType {CONSUMABLE, WIELDABLE, COMBINABLE, KEY, AMMO}
@export var item_type: ItemType

## Name of Item as it appears in game.
@export var name : String = ""
## Description of Item as it'll appear in the HUD / Inventory menu
@export_multiline var descpription : String = ""
## Icon of Item for HUD / Inventory
@export var icon : Texture2D
@export var power : float
@export var is_stackable : bool = false
@export_range(1, 99) var stack_size : int
## Path to Scene that will be spawned when item is removed from inventory to be dropped into the world.
@export_file("*.tscn") var drop_scene
## Icon that is displayed with the hint that pops up when used. If left blank, the default hint icon is shown.
@export var hint_icon_on_use : Texture2D
## Hint that is displayed when used. For example "Potion replenished 10 HP!"
@export var hint_text_on_use : String

@export_subgroup("Audio")
## Audio that plays when item is used.
@export var sound_use : AudioStream
@export var sound_pickup : AudioStream
@export var sound_drop : AudioStream

@export_group("Consumable settings")
## Name of attribute that the item is going to replenish. (For example "health")
@export var attribute_name : String
## The change amount that gets applied to the attribute. (For example 25 to heal 25hp. Allows negative values too.)
@export var attribute_change_amount : float

@export_group("Wieldable settings")
# Signal that gets sent when the wiedlable charge changes. Currently used to update Slot UI
signal charge_changed()
## HUD text for primary use (for example: shoot, switch on/off etc.)
@export var primary_use_prompt : String
## HUD text for secondary use (for example: swing, look down sight, etc.)
@export var secondary_use_prompt : String
## Icon that is displayed on the HUD when item is wielded.
@export var wieldable_data_icon : Texture2D
var wieldable_data_text : String
## The maximum charge of the item (this equals fully charged battery in a flashlight or magazine size in guns)
@export var charge_max : float
## Name of item this item uses as Ammo.
@export var ammo_item_name : String
## Current charge of item (aka how much is in the magazine).
@export var charge_current : float
## Used for weapons
@export var wieldable_range : float
## Used for weapons
@export var wieldable_damage : float
@export_subgroup("Animations")
@export var equip_anim : String
@export var unequip_anim : String
@export var reload_anim : String
@export var use_anim : String


@export_group("Combinable settings")
## The name of the item that this item combines with. Caution: String has to be a perfect match, so watch casing and space.
@export var target_item_combine : String = ""
## The item that gets created when this item is combined with the one above.
@export var resulting_item : InventorySlotPD = null

@export_group("Key settings")
# If this is checked, the key item will be removed from the inventory after it's been used on the target object.
@export var discard_after_use : bool = false

@export_group("Ammo settings")
## The item that this item is ammunition for.
@export var target_item_ammo : InventoryItemPD = null
## The amount one item addes to the target item charge. For bullets this should be 1.
@export var reload_amount : int = 1


# Variables for Wielded Items
var player_interaction_component
var is_being_wielded : bool
var wielded_item


func use(target) -> bool:
	# Target should always be player? Null check to override using the CogitoSceneManager, which stores a reference to current player node
	if target == null or target.is_in_group("external_inventory"):
		print("Bad target pass. Setting target to", CogitoSceneManager._current_player_node)
		target = CogitoSceneManager._current_player_node
		
	
	match item_type:
		ItemType.CONSUMABLE:
			if target.increase_attribute(attribute_name, power):
				print("Inventory item: Target ", target, " is using ", self)
				Audio.play_sound(sound_use)
				if hint_text_on_use != "":
					target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
				return true
			else:
				target.player_interaction_component.send_hint(hint_icon_on_use, str(attribute_name + " is already maxed."))
				return false
		
		ItemType.WIELDABLE:
			player_interaction_component = target.player_interaction_component
			if player_interaction_component.carried_object != null:
				player_interaction_component.send_hint(null,"Can't equip item while carrying.")
				return false
			if is_being_wielded:
				player_interaction_component.emit_signal("set_use_prompt", "")
				player_interaction_component.emit_signal("updated_wieldable_data", null, "")
				print("Inventory item: ", player_interaction_component, " is putting away wieldable ", name)
				put_away()
				return true
			else:
				player_interaction_component.emit_signal("set_use_prompt", primary_use_prompt)
				update_wieldable_data(player_interaction_component)
				print("Inventory item: ", player_interaction_component, " is taking out wieldable ", name)
				take_out()
				return true
		
		ItemType.COMBINABLE:
			if hint_text_on_use != "":
				target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
			return true
				
		ItemType.AMMO:
			if hint_text_on_use != "":
				target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
			return true
		
		ItemType.KEY:
			if hint_text_on_use != "":
				target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
			return true
		
		_: # DEFAULT
			print("Inventory item: item type match hit default.")
			return false
		


# Functions for WIELDABLES
func take_out():
	print("Taking out ", name)
	player_interaction_component.change_wieldable_to(self)
#	var scene_to_wield = load(drop_scene)
#	wielded_item = scene_to_wield.instantiate()
#	wielder.get_parent().add_child(wielded_item)
#	wielded_item.pick_up(wielder)
	is_being_wielded = true
	
func put_away():
	print("Putting away ", name)
	player_interaction_component.change_wieldable_to(null)
	is_being_wielded = false
#	if wielded_item != null:
#		wielded_item.queue_free()


func get_item_amount_in_inventory(item_name_to_check_for:String) -> int:
	var item_count : int = 0
	if player_interaction_component.get_parent().inventory_data != null:
		var inventory_to_check = player_interaction_component.get_parent().inventory_data
		for slot in inventory_to_check.inventory_slots:
			if slot != null and slot.inventory_item.name == item_name_to_check_for:
				item_count += slot.quantity
				
	return item_count


func update_wieldable_data(_player_interaction_component : PlayerInteractionComponent):
	if _player_interaction_component: #Only update if something get's passed
		player_interaction_component = _player_interaction_component
	wieldable_data_text = str(int(charge_current)) + "|" + str(get_item_amount_in_inventory(ammo_item_name))
	player_interaction_component.emit_signal("updated_wieldable_data", wieldable_data_icon, wieldable_data_text)


func subtract(amount):
	charge_current -= amount
	if charge_current < 0:
		charge_current = 0
		player_interaction_component.send_hint(null, name + " is out of battery.")
	
	if is_being_wielded:
		update_wieldable_data(null)
	
	charge_changed.emit()
	

func add(amount):
	charge_current += amount
	if charge_current > charge_max:
		charge_current = charge_max
	
	if is_being_wielded:
		update_wieldable_data(null)
	charge_changed.emit()



func save():
	var saved_item_data = {
		"resource" : self,
		"charge_current" : charge_current
	}
	return saved_item_data
