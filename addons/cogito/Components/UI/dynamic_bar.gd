class_name CogitoDynamicBar
extends ProgressBar

@onready var timer: Timer = $Timer
@onready var difference_bar: ProgressBar = $DifferenceBar

@export var catch_up_time : float = 0.4
@export var difference_color : Color = Color.WHITE

@onready var difference_var_stylebox : StyleBoxFlat = StyleBoxFlat.new()
@onready var empty_stylebox : StyleBoxEmpty = StyleBoxEmpty.new()

var value_current: float

func _ready() -> void:
	timer.wait_time = catch_up_time
	add_theme_stylebox_override("background",empty_stylebox)

func update_value(_new_value: float,_new_max_value: float):
	var prev_value = value_current

	if max_value != _new_max_value:
		max_value = _new_max_value
		difference_bar.max_value = max_value
		
	value_current = _new_value
	value = value_current
	
	if value_current < prev_value:
		timer.start()
	else:
		difference_bar.value = value_current


func init_values(_value_current: float, _value_max: float):
	value_current = _value_current
	max_value = _value_max
	value = value_current
	
	difference_bar.max_value = max_value
	difference_bar.value = value
	
	difference_var_stylebox.bg_color = difference_color
	difference_bar.add_theme_stylebox_override("fill",difference_var_stylebox)


func _on_timer_timeout() -> void:
	var catch_up_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	catch_up_tween.tween_property(difference_bar,"value", value_current,0.2)
