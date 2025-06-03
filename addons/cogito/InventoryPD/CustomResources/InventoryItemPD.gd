extends Resource
class_name InventoryItemPD

## Name of Item as it appears in game.
@export var name : String = ""
## Description of Item as it'll appear in the HUD / Inventory menu
@export_multiline var description : String = ""
## Icon of Item for HUD / Inventory
@export var icon : Texture2D
## Sets if an item can be stackable or not. Usually used for consumables or ammo.
@export var is_stackable : bool = false
## Sets if an item can be dropped or not. Used for important items so they can't get lost. Items can still be moved to external inventories.
@export var is_droppable : bool = true
## LootComponent - Sets the item as a unique. Meaning there can be only one copy in player inventory and all the loot bags.
@export var is_unique : bool = false
@export_range(1, 99) var stack_size : int
## Path to Scene that will be spawned when item is removed from inventory to be dropped into the world.
@export_file("*.tscn") var drop_scene
## Physical size as a spherical radius - used to account for the space an item takes up when being dropped in the world. (e.g. an item thats 1m long should have a drop size of .5 as that checks for a sphere with 1m diameter.
@export var item_drop_size : float = 0.5
## Icon that is displayed with the hint that pops up when used. If left blank, the default hint icon is shown.
@export var hint_icon_on_use : Texture2D
## Hint that is displayed when used. For example "Potion replenished 10 HP!"
@export var hint_text_on_use : String
@export var item_size : Vector2 = Vector2(1,1)

@export_subgroup("Audio")
## Audio that plays when item is used.
@export var sound_use : AudioStream
@export var sound_pickup : AudioStream
@export var sound_drop : AudioStream

@export_category("Auto Quickslot Settings")
## When set to true, this item will be automatically bound to an empty quickslot on pickup.
@export var can_auto_slot: bool = false
## Quickslot number this item will be  bound to on pickup.
@export var slot_number: int = -1

# Variables for Wielded Items
var player_interaction_component
var is_being_wielded : bool
var wielded_item

func get_region(x, y):
	var image = icon.get_image()
	var x_chunk = icon.get_width() / item_size.x
	var y_chunk = icon.get_height() / item_size.y
	var region = Rect2i(Vector2i(x * x_chunk, y * y_chunk), Vector2i(x_chunk, y_chunk))
	return image.get_region(region)
