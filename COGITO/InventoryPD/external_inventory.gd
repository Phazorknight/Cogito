extends StaticBody3D

@export var inventory_data : InventoryPD
@export var interaction_text : String = "Open"
var is_open : bool = false

signal toggle_inventory(external_inventory_owner)

func interact(_player):
	toggle_inventory.emit(self)
