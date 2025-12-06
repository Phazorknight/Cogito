@tool
extends Control

signal end_reached
signal closed
signal opened

@export var auto_scroll_speed: float = 60.0
@export var input_scroll_speed : float = 400.0
@export var scroll_restart_delay : float = 1.5

var timer : Timer = Timer.new()
var _current_scroll_position : float = 0.0
var scroll_paused : bool = false

@onready var header_space : Control = %Header
@onready var footer_space : Control = %Footer
@onready var credits_label : Control = %CreditsRTL
@onready var scroll_container : ScrollContainer = %ScrollContainer

## Path to your credits txt. Supports BBCode.
@export_file("*.txt") var credits_text_file : String



func set_header_and_footer() -> void:
	CogitoGlobals.debug_log(true, "cogito_credits", "setting header/footer size. size.x x size.y =" + str(size.x) + "x" + str(size.y))
	scroll_container.custom_minimum_size.x = size.x
	scroll_container.custom_minimum_size.y = size.y
	header_space.custom_minimum_size.x = size.x
	header_space.custom_minimum_size.y = size.y
	footer_space.custom_minimum_size.x = size.x
	footer_space.custom_minimum_size.y = size.y
	credits_label.custom_minimum_size.x = size.x


func load_file(file_path) -> String:
	var file = FileAccess.open(credits_text_file, FileAccess.READ)
	var file_text = file.get_as_text()
	if file_text == null:
		push_warning("File open error: %s" % FileAccess.get_open_error())
		return ""
	return file_text

func _on_resized() -> void:
	set_header_and_footer()
	_current_scroll_position = scroll_container.scroll_vertical


func _end_reached() -> void:
	scroll_paused = true
	end_reached.emit()
	close()


func is_end_reached() -> bool:
	var _end_of_credits_vertical = credits_label.size.y + header_space.size.y
	return scroll_container.scroll_vertical > _end_of_credits_vertical


func _check_end_reached() -> void:
	if not is_end_reached():
		return
	_end_reached()


func _scroll_container(amount : float) -> void:
	if not visible or scroll_paused:
		return
	_current_scroll_position += amount
	scroll_container.scroll_vertical = round(_current_scroll_position)
	_check_end_reached()


func _on_gui_input(event : InputEvent) -> void:
	# Captures the mouse scroll wheel input event
	if event is InputEventMouseButton:
		scroll_paused = true
		_start_scroll_restart_timer()
	_check_end_reached()


func _on_scroll_started() -> void:
	# Captures the touch input event
	scroll_paused = true
	_start_scroll_restart_timer()


func _start_scroll_restart_timer() -> void:
	timer.start(scroll_restart_delay)


func _on_scroll_restart_timer_timeout() -> void:
	_current_scroll_position = scroll_container.scroll_vertical
	scroll_paused = false


func _on_visibility_changed() -> void:
	if visible:
		scroll_container.scroll_vertical = 0
		_current_scroll_position = scroll_container.scroll_vertical
		scroll_paused = false


func _ready() -> void:
	scroll_container.scroll_started.connect(_on_scroll_started)
	gui_input.connect(_on_gui_input)
	resized.connect(_on_resized)
	visibility_changed.connect(_on_visibility_changed)
	timer.timeout.connect(_on_scroll_restart_timer_timeout)
	set_header_and_footer()
	
	var credits_text = load_file(credits_text_file)
	credits_label.text = ""
	credits_label.append_text(credits_text)
	
	add_child(timer)


func _unhandled_input(event : InputEvent) -> void:
	if visible and event.is_action_released("menu"):
		close()
		get_viewport().set_input_as_handled()


func _process(delta : float) -> void:
	var input_axis = Input.get_axis("ui_up", "ui_down")
	if input_axis != 0:
		_scroll_container(input_axis * input_scroll_speed * delta)
	else:
		_scroll_container(auto_scroll_speed * delta)


func close() -> void:
	if not visible: return
	hide()
	closed.emit()


func _exit_tree() -> void:
	_current_scroll_position = scroll_container.scroll_vertical
