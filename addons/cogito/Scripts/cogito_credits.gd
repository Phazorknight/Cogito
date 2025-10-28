extends Control

## Path to your credits txt. Supports BBCode.
@export_file("*.txt") var credits_text_resource : String

@export var scroll_speed : float = 1.0

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var credits_rich_text_label: RichTextLabel = %CreditsRichTextLabel

func _ready() -> void:
	var file = FileAccess.open(credits_text_resource, FileAccess.READ)
	var credits_text = file.get_as_text()
	
	credits_rich_text_label.text = ""
	credits_rich_text_label.append_text(credits_text)


func _process(delta: float) -> void:
	scroll_container.scroll_vertical += scroll_speed
