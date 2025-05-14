class_name LootDropEntry extends Resource

enum DropType {
	NONE = 0,
	GUARANTEED = 1,
	CHANCE = 2,
	QUEST = 4,
}

## Name for this drop, only for human readability.
@export var name : String
## Enum of drop type, sorted into individual arrays, DropType.NONE will be ignored by the drop function.
@export var droptype : DropType = 2
## Drop weight in float, if zero function will not drop the item. For guaranteed drops, this value is not referenced and can be omitted.
@export var weight : float = 100.0
## Scene to load during function call.
@export var inventory_item : InventoryItemPD
## Minimum quantity to roll for during loot generation. Script will assume 1 unit if this value is not present.
@export var quantity_min : int = 1
## Maximum quantity to roll for during loot generation. Script will assume 1 unit if this value is not present.
@export var quantity_max : int = 15
## If this item is not used for Quests, leave at -1. Quest ID associated with this drop. If there is a matching quest ID in active quests, quest item will be dropped. You need to set drop type to quest for this to function.
@export var quest_id : int = -1
## Maximum amount of quest items there can be. Player inventory and the loot drop inventory is referenced against this to cap quest items. If omitted script will assume a value of 1.
@export var quest_item_total_count : int = 1
