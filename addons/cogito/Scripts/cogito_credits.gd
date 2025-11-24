extends Control

signal credits_finished
signal credits_interrupted

## Path to your credits txt. Supports BBCode.
@export_file("*.txt") var credits_text_file : String

@export var input_scroll_speed : float = 400.0
@export var auto_scroll_speed : float = 60

var endpoint : int = 0
var _line_number : float = 0
var _current_scroll_position : float = 0.0
var scroll_paused : bool = false

@onready var credits_rich_text_label: RichTextLabel = %CreditsRichTextLabel
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var panel_empty_header: Panel = %PanelEmptyHeader
@onready var panel_empty_footer: Panel = %PanelEmptyFooter


func _ready() -> void:
	var credits_text = load_file(credits_text_file)
	
	credits_rich_text_label.text = ""
	credits_rich_text_label.append_text(credits_text)
	
	# Finding the proper endpoint should probably be refined a bit.
	endpoint = credits_rich_text_label.size.y - (credits_rich_text_label.size.y/3)
	print("Cogito Credits: endpoint = ", endpoint)
	#start_credits()


func load_file(file_path) -> String:
	var file = FileAccess.open(credits_text_file, FileAccess.READ)
	var file_text = file.get_as_text()
	if file_text == null:
		push_warning("File open error: %s" % FileAccess.get_open_error())
		return ""
	return file_text


func start_credits() -> void:
	scroll_container.scroll_vertical = 0
	_current_scroll_position = scroll_container.scroll_vertical
	scroll_paused = false


func reset_credits() -> void:
	scroll_container.scroll_vertical = 0


func end_credits() -> void:
	print("Cogito Credits: END REACHED!")
	credits_finished.emit()


func _process(delta: float) -> void:
	# This block lets player scroll manually (rewind/fast foward)
	var input_axis = Input.get_axis("forward", "back")
	if input_axis != 0:
		_scroll_container(input_axis * input_scroll_speed * delta)
	else:
		_scroll_container(auto_scroll_speed * delta)
		
		
func _scroll_container(amount : float) -> void:
	if not visible or scroll_paused:
		return
	_current_scroll_position += amount
	scroll_container.scroll_vertical = round(_current_scroll_position)
	_check_end_reached()
	

func _check_end_reached() -> void:
	if not is_end_reached():
		return
	end_credits()


func is_end_reached() -> bool:
	var _end_of_credits_vertical = credits_rich_text_label.size.y + panel_empty_header.size.y
	return scroll_container.scroll_vertical > _end_of_credits_vertical
