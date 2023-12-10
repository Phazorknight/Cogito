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
## Name of sound in SoundManager that will play when item is used
@export var use_sound : String = ""
## Path to Scene that will be spawned when item is removed from inventory to be dropped into the world.
@export_file("*.tscn") var drop_scene
## Icon that is displayed with the hint that pops up when used. If left blank, the default hint icon is shown.
@export var hint_icon_on_use : Texture2D
## Hint that is displayed when used. For example "Potion replenished 10 HP!"
@export var hint_text_on_use : String

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
@export var charge_current : float

@export_group("Combinable settings")
## The name of the item that this item combines with. Caution: String has to be a perfect match, so watch casing and space.
@export var target_item_combine : String = ""
## The item that gets created when this item is combined with the one above.
@export var resulting_item : InventorySlotPD = null

@export_group("Ammo settings")
## The item that this item is ammunition for.
@export var target_item_ammo : InventoryItemPD = null
## The amount one item addes to the target item charge. For bullets this should be 1.
@export var reload_amount : int = 1

@export_group("Key settings")
# If this is checked, the key item will be removed from the inventory after it's been used on the target object.
@export var discard_after_use : bool = false

# Variables for Wielded Items
var wielder
var is_being_wielded : bool
var wielded_item


func use(target):
	match item_type:
		ItemType.CONSUMABLE:
			print("Inventory item: Target ", target, " is using ", self)
			AudioManagerPd.play_audio(use_sound)
			if hint_text_on_use != "":
				target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
			target.increase_attribute(attribute_name, power)
		
		ItemType.WIELDABLE:
			wielder = target.player_interaction_component
			print("Inventory item: ", wielder, " is using wieldable ", name)
			if is_being_wielded:
				wielder.emit_signal("set_use_prompt", "")
				wielder.emit_signal("update_wieldable_data", null, "")
				put_away()
			else:
				wielder.emit_signal("set_use_prompt", primary_use_prompt)
				wieldable_data_text = str(int(charge_current)) + "/" + str(int(charge_max))
				wielder.emit_signal("update_wieldable_data", wieldable_data_icon, wieldable_data_text)
				take_out()
		
		ItemType.COMBINABLE:
			if hint_text_on_use != "":
				target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
				
		ItemType.AMMO:
			if hint_text_on_use != "":
				target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
		
		ItemType.KEY:
			if hint_text_on_use != "":
				target.player_interaction_component.send_hint(hint_icon_on_use,hint_text_on_use)
		
		_: # DEFAULT
			print("Inventory item: item type match hit default.")
		


# Functions for WIELDABLES
func take_out():
	print("Taking out ", name)
	var scene_to_wield = load(drop_scene)
	wielded_item = scene_to_wield.instantiate()
	wielder.get_parent().add_child(wielded_item)
	wielded_item.pick_up(wielder)
	is_being_wielded = true
	
func put_away():
	print("Putting away ", name)
	is_being_wielded = false
	wielded_item.queue_free()

func subtract(amount):
	charge_current -= amount
	if charge_current < 0:
		charge_current = 0
		wielded_item.turn_off()
	
	if is_being_wielded:
		wieldable_data_text = str(int(charge_current)) + "/" + str(int(charge_max))
		wielder.emit_signal("update_wieldable_data", wieldable_data_icon, wieldable_data_text)
	
	charge_changed.emit()
	

func add(amount):
	charge_current += amount
	if charge_current > charge_max:
		charge_current = charge_max
	
	if is_being_wielded:
		wieldable_data_text = str(int(charge_current)) + "/" + str(int(charge_max))
		wielder.emit_signal("update_wieldable_data", wieldable_data_icon, wieldable_data_text)
	charge_changed.emit()
