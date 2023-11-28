@tool
extends VBoxContainer
signal value_changed(value: float)

@onready var title_label : Label = $Title
@onready var hslider : HSlider = $HSlider
@onready var current_value_label : Label = $CurrentValue

@export var show_percentage : bool = false:
	get:
		return show_percentage
	set(value):
		show_percentage = value
		if hslider != null:
			set_current_value_label(hslider.value)

@export var title : String = "":
	get:
		return title
	set(value):
		title = value
		if title_label != null:
			title_label.text = title

func _ready():
	title_label.text = title
	set_current_value_label(hslider.value)

func get_percentage(value: float, max_value: float):
	return   value / max_value

func get_percentage_string(value: float) -> String:
	return  "%d %%" % (value * 100)

func _on_h_slider_value_changed(value: float):
	set_current_value_label(value)
	value_changed.emit(value)

func set_current_value_label(value: float):
	if show_percentage:
		current_value_label.text = get_percentage_string(get_percentage(hslider.value, hslider.max_value))
	else:
		current_value_label.text = "%d" % value