class_name LootTable extends Resource

enum DropType {
	NONE = 0,
	GUARANTEED = 1,
	CHANCE = 2,
	QUEST = 4,
}

@export var drops: Array[LootDropEntry] = []


func _init() -> void:
	pass
