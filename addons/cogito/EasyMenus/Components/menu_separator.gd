extends HBoxContainer
@onready var label: Label = $Label

var separator_text: String = "Section":
	set(value):
		separator_text = value
		label.text = separator_text
