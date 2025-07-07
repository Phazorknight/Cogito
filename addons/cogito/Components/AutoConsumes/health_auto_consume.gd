class_name HealthAutoConsume
extends AutoConsume

## The max difference allowed between value_current and full_damage, where auto-consume is permitted
@export var max_damage_remainder: float = 10.0
## Set to false if an auto-consumed health item restores it's full value.
## Set to true if you want the auto-consumed health item to merely offset the damage taken.
@export var apply_damage_remainder: bool = true


func _init() -> void:
	# The attribute name is reset to the AutoConsume default of "" on load, reassign the name
	attribute_name = "health"


# Call _ready from subclass
func _ready() -> void:
	initialize_auto_consume()


# Ensure that an auto-consumed healing item prevents player death
func prevent_death(_value_current: float) -> void:
	var max_subtracted_amount: float = attribute.last_passed_subtracted_amount
	var remainder: float = max_subtracted_amount - last_value_current
	
	# Attempt to auto-consume an inventory item after health fell below threshold value
	if last_value_current > 0.0 and remainder <= max_damage_remainder:
		_auto_consume(false, remainder)
	
		if apply_damage_remainder:
			var lowest_remainder: float = floorf(remainder)
			attribute.subtract(lowest_remainder)
			CogitoGlobals.debug_log(true, "HealthAutoConsume", "Applied damage remainder of " + str(lowest_remainder))
