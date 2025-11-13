extends Control

signal credits_finished
signal credits_interrupted

## Path to your credits txt. Supports BBCode.
@export_file("*.txt") var credits_text_resource : String

@export var scroll_speed : float = 1.0

var endpoint : int = 0
var is_scrolling : bool = false


@onready var credits_rich_text_label: RichTextLabel = %CreditsRichTextLabel
@onready var scroll_container: ScrollContainer = %ScrollContainer


func _ready() -> void:
	var file = FileAccess.open(credits_text_resource, FileAccess.READ)
	var credits_text = file.get_as_text()
	
	credits_rich_text_label.text = ""
	credits_rich_text_label.append_text(credits_text)
	
	# Finding the proper endpoint should probably be refined a bit.
	endpoint = credits_rich_text_label.size.y - (credits_rich_text_label.size.y/3)
	print("Cogito Credits: endpoint = ", endpoint)
	#start_credits()


func reset_credits() -> void:
	scroll_container.scroll_vertical = 0


func start_credits() -> void:
	is_scrolling = true


func end_credits() -> void:
	is_scrolling = false
	print("Cogito Credits: END REACHED!")
	credits_finished.emit()


func _process(delta: float) -> void:
	if !is_scrolling:
		return
	
	# This block lets player scroll manually (rewind/fast foward)
	var input_dir
	input_dir = Input.get_vector("left", "right", "forward", "back")
	
	if input_dir.y != 0.0:
		scroll_speed += input_dir.y * 2
	else:
		scroll_speed = 1.0

	# End credits if endpoint is reached
	if scroll_container.scroll_vertical >= endpoint:
		end_credits()
	else:
		scroll_container.scroll_vertical += scroll_speed
