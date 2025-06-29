class_name StaminaAutoConsume
extends AutoConsume

func _init() -> void:
	# The attribute name is reset to the AutoConsume default of "" on load, rename it
	attribute_name = "stamina"


# Call _ready from subclass
func _ready() -> void:
	initialize_auto_consume()
