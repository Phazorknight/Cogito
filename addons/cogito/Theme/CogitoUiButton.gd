extends Button
class_name CogitoUiButton

signal pressed_string(text:String)

var tween_time : float = 0.2
var tween_stylebox : StyleBoxFlat
var styleboxes : Dictionary = {}
var current_state = BaseButton.DRAW_NORMAL

# Will accept ui_accept keys as long as other shortcuts have been used in context
@export var accepts_contextual_enter : bool = false
static var used_shortcut = false

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
	styleboxes[BaseButton.DRAW_DISABLED] = get_theme_stylebox('disabled').duplicate()
	
	# Override all the other styleboxes with our tween stylebox
	add_theme_stylebox_override('normal', tween_stylebox)
	add_theme_stylebox_override('hover', tween_stylebox)
	add_theme_stylebox_override('focus', tween_stylebox)
	add_theme_stylebox_override('pressed', tween_stylebox)
	add_theme_stylebox_override('disabled', tween_stylebox)
	

func press_button_manually():
	pressed.emit()
	
	if tween and tween.is_running(): # Kill the running tween
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	
	# That tweens some properties of our tween stylebox to the target stylebox depending on the current state
	var target = styleboxes[BaseButton.DRAW_PRESSED] as StyleBoxFlat
	tween.tween_property(tween_stylebox, "bg_color", target.bg_color, tween_time)
	tween.tween_property(tween_stylebox, "border_color", target.border_color, tween_time)
	tween.tween_property(tween_stylebox, "border_width_left", target.border_width_left, tween_time)
	tween.connect('finished',unpress)


func unpress():
	if not tween or tween.is_running() or not tween.is_valid:
		# we've likely been overridden since, so don't mess with anything
		return
	current_state = BaseButton.DRAW_PRESSED # this will be changed on the next frame


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
	used_shortcut = false # focus changing implies not using shortcuts
	
	if tween and tween.is_running(): # Kill the running tween
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	
	# That tweens some properties of our tween stylebox to the target stylebox depending on the current state
	var target = styleboxes[BaseButton.DRAW_HOVER] as StyleBoxFlat
	tween.tween_property(tween_stylebox, "bg_color", target.bg_color, tween_time)
	tween.tween_property(tween_stylebox, "border_color", target.border_color, tween_time)
	tween.tween_property(tween_stylebox, "border_width_left", target.border_width_left, tween_time)


func in_context() -> bool:
	var context = get_viewport().gui_get_focus_owner()
	if context:
		var context_owner = context.shortcut_context or context.get_parent_control()
		var our_context = shortcut_context or get_parent_control()
		return context_owner == our_context
	return false


func _on_focus_exited() -> void:
	if get_viewport().gui_get_focus_owner() == null:
		# lost focus to a GUI completely
		used_shortcut = false
	
	if tween and tween.is_running(): # Kill the running tween
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	
	# That tweens some properties of our tween stylebox to the target stylebox depending on the current state
	var target = styleboxes[BaseButton.DRAW_NORMAL] as StyleBoxFlat
	tween.tween_property(tween_stylebox, "bg_color", target.bg_color, tween_time)
	tween.tween_property(tween_stylebox, "border_color", target.border_color, tween_time)
	tween.tween_property(tween_stylebox, "border_width_left", target.border_width_left, tween_time)


#func _input(event : InputEvent):
func _unhandled_input(event: InputEvent) -> void:
	if in_context():
		if shortcut and shortcut.matches_event(event):
			# let other CogitoButtons know that the current context has had a shortcut used
			used_shortcut = true
		elif used_shortcut and accepts_contextual_enter and event.is_action_pressed("ui_accept"):
			accept_event()
			press_button_manually()


func _on_pressed():
	pressed_string.emit(text)
