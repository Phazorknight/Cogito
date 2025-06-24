extends CogitoAttributeUi


## When the attribute reaches its max value fade it out quickly.
@export var start_fade_at_value_max: bool = true
## Will fade out, even while value increases. If false will only fade out when at max.
@export var fade_on_attribute_increase: bool = true
## If the attribute is fully transparent when increasing to its max value, display it once
@export var blink_fade_at_value_max: bool = true
@export var time_before_fadeout: float = 1.5
@onready var display_timer : Timer
# Cache the tween so we can abort the fade when the attribute changes
@onready var display_tween: Tween

var last_value: float

func _ready() -> void:
	display_timer = Timer.new()
	add_child(display_timer)
	
	display_timer.one_shot = true
	display_timer.wait_time = time_before_fadeout
	display_timer.timeout.connect(_on_display_timer_timeout)
	
	modulate = Color.TRANSPARENT

func on_attribute_changed(_attribute_name:String,_value_current:float,_value_max:float,_has_increased:bool):
	
	if !_has_increased:
		_stop_fade_and_show(Color.WHITE)
	else: # Attribute increased
		if _value_current == _value_max and last_value < _value_max:
			# The attribute just maxed out, update the display timer
			if fade_on_attribute_increase and blink_fade_at_value_max and modulate.a < 0.75:
				# Only stop the fade and show the attribute bar if it fades while increasing
				_stop_fade_and_show(Color(1.0, 1.0, 1.0, 0.75))
				display_timer.wait_time = 0.5
			else: # Fade out when maxed
				display_timer.wait_time = 0.01 if start_fade_at_value_max else time_before_fadeout
			display_timer.start()
		elif fade_on_attribute_increase and display_timer.is_stopped():
			display_timer.wait_time = time_before_fadeout
			display_timer.start()

	attribute_bar.update_value(_value_current, _value_max)
	attribute_label.text = str(int(_value_current))
	
	last_value = _value_current


func _on_display_timer_timeout():
	display_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	display_tween.tween_property(self,"modulate", Color.TRANSPARENT,.5)

func _stop_fade_and_show(start_modulate: Color) -> void:
	# Abort the fade
	if display_tween and display_tween.is_running():
		display_tween.kill()
	# Stops the tween timer, which won't call the timeout signal
	display_timer.stop()
	
	modulate = start_modulate
