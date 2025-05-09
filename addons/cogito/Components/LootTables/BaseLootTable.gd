class_name LootTable extends Resource

enum DropType {
	NONE = 0,
	GUARANTEED = 1,
	CHANCE = 2,
	QUEST = 4,
}

@export var contents: Array[Dictionary] = [
	# Example Item #1. Create a structure based on these parameters in a resource file derived from LootTable class.
	#{ 
		#"name": "Currency", # Name for this drop, only for human readability.
		#"DropType" : DropType.GUARANTEED, # Enum of drop type, sorted into individual arrays, DropType.NONE will be ignored by the drop function.
		#"weight": 100.0, # Drop weight in float, if zero function will not drop the item. For guaranteed drops, this value is not referenced and can be omitted.
		#"inventory_item": load("res://addons/cogito/InventoryPD/Items/Cogito_Coins.tres"), # Scene to load during function call.
		#"quantity_min" : 1, # Minimum quantity to roll for during loot generation. Script will assume 1 unit if this value is not present.
		#"quantity_max" : 15, # Maximum quantity to roll for during loot generation. Script will assume 1 unit if this value is not present.
		#"quest_id" : 0, # Quest ID associated with this drop. If there is a matching quest ID in active quests, quest item will be dropped. You need to set drop type to quest for this to function.
		#"quest_item_total_count" : 1, # Maximum amount of quest items there can be. Player inventory and the loot drop inventory is referenced against this to cap quest items. If omitted script will assume a value of 1.
	#},
]

	
func _init() -> void:
	pass
