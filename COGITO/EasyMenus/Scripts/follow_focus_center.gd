extends ScrollContainer

var scrollable : Control
@export var animate = true
@export var transition_time = 0.2
@export var gamepad_scroll_speed : int = 5
@export var gamepad_scroll_deadzone : float = 0.1
var _last_input_event
var gamepad_scroll : float = 0


func _ready():
	scrollable = get_child(0)
	get_viewport().gui_focus_changed.connect(focus_changed)


func _get_position_relative_to_control(a: Control, b: Control) -> Vector2:
	return b.get_global_rect().position - a.get_global_rect().position 


func focus_changed(focus: Control):
	if _last_input_event is InputEventMouseButton:
		return
		
	var scroll_destination = _get_position_relative_to_control(scrollable, focus).y - get_rect().size.y / 2
	if animate:
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scroll_vertical", scroll_destination, transition_time)
	else:
		scroll_vertical = scroll_destination

func _input(event):
	_last_input_event = event

	# Checking Analog stick input for mouse look
	if event is InputEventJoypadMotion:
		if event.get_axis() == 3:
			gamepad_scroll = event.get_axis_value()
			
			
func _process(delta: float) -> void:
	if abs(gamepad_scroll) > abs(gamepad_scroll_deadzone):
		scroll_vertical = scroll_vertical + gamepad_scroll_speed * gamepad_scroll
