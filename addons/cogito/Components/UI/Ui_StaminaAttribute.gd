extends CogitoAttributeUi

@onready var display_timer : Timer

@export var time_before_fadeout: float = 1.5

func _ready() -> void:
	display_timer = Timer.new()
	add_child(display_timer)
	
	display_timer.one_shot = true
	display_timer.wait_time = time_before_fadeout
	display_timer.timeout.connect(_on_display_timer_timeout)
	
	modulate = Color.TRANSPARENT

func on_attribute_changed(_attribute_name:String,_value_current:float,_value_max:float,_has_increased:bool):
	if !_has_increased:
		modulate = Color.WHITE
	
	attribute_bar.update_value(_value_current, _value_max)
	attribute_label.text = str(int(_value_current))
	
	display_timer.start()


func _on_display_timer_timeout():
	var display_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	display_tween.tween_property(self,"modulate", Color.TRANSPARENT,.5)
