extends Button
class_name CogitoButton

signal pressed_string(text:String)

var tween_time : float = 0.2
var tween_stylebox : StyleBoxFlat
var styleboxes : Dictionary = {}
var current_state = BaseButton.DRAW_NORMAL

var tween : Tween

func _ready() -> void:
	#Attempt to make this work with focus
	self.focus_entered.connect(_on_focus_entered)
	self.focus_exited.connect(_on_focus_exited)
	self.pressed.connect(_on_pressed)
	
	# Duplicate the normal stylebox. We are going to use it as our base stylebox
	tween_stylebox = get_theme_stylebox('normal').duplicate()
	
	# Save the different styleboxes to be able to tween between their properties later
	styleboxes[BaseButton.DRAW_NORMAL] = get_theme_stylebox('normal').duplicate()
	styleboxes[BaseButton.DRAW_HOVER] = get_theme_stylebox('hover').duplicate()
	styleboxes[BaseButton.DRAW_PRESSED] = get_theme_stylebox('pressed').duplicate()
	styleboxes[BaseButton.DRAW_HOVER_PRESSED] = get_theme_stylebox('pressed').duplicate()
	
	# Override all the other styleboxes with our tween stylebox
	add_theme_stylebox_override('normal', tween_stylebox)
	add_theme_stylebox_override('hover', tween_stylebox)
	add_theme_stylebox_override('focus', tween_stylebox)
	add_theme_stylebox_override('pressed', tween_stylebox)


func _process(_delta: float) -> void:
	if get_draw_mode() != current_state:
		# If the draw mode changed
		current_state = get_draw_mode()
		
		if tween and tween.is_running(): # Kill the running tween
			tween.kill()
		tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
		
		# That tweens some properties of our tween stylebox to the target stylebox depending on the current state
		var target = styleboxes[current_state] as StyleBoxFlat
		tween.tween_property(tween_stylebox, "bg_color", target.bg_color, tween_time)
		tween.tween_property(tween_stylebox, "border_color", target.border_color, tween_time)
		tween.tween_property(tween_stylebox, "border_width_left", target.border_width_left, tween_time)


func _on_focus_entered() -> void:
	if tween and tween.is_running(): # Kill the running tween
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	
	# That tweens some properties of our tween stylebox to the target stylebox depending on the current state
	var target = styleboxes[BaseButton.DRAW_HOVER] as StyleBoxFlat
	tween.tween_property(tween_stylebox, "bg_color", target.bg_color, tween_time)
	tween.tween_property(tween_stylebox, "border_color", target.border_color, tween_time)
	tween.tween_property(tween_stylebox, "border_width_left", target.border_width_left, tween_time)


func _on_focus_exited() -> void:
	if tween and tween.is_running(): # Kill the running tween
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	
	# That tweens some properties of our tween stylebox to the target stylebox depending on the current state
	var target = styleboxes[BaseButton.DRAW_NORMAL] as StyleBoxFlat
	tween.tween_property(tween_stylebox, "bg_color", target.bg_color, tween_time)
	tween.tween_property(tween_stylebox, "border_color", target.border_color, tween_time)
	tween.tween_property(tween_stylebox, "border_width_left", target.border_width_left, tween_time)


func _on_pressed():
	pressed_string.emit(text)
