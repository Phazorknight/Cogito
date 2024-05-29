extends CogitoAttribute

func _ready():
	value_current = value_start
	
func check_current_visibility():
	attribute_changed.emit(attribute_name,value_current,value_max,true)
