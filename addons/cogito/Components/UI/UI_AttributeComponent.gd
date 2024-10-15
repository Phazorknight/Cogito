extends Control

@onready var attribute_icon: TextureRect = $HBoxContainer/AttributeIcon
@onready var attribute_bar: ProgressBar = $HBoxContainer/AttributeBar
@onready var attribute_label: Label = $HBoxContainer/AttributeLabel

@export var bar_stylebox: StyleBoxFlat

var assigned_player_attribute : CogitoAttribute

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func initiate_attribute_ui(_player_attribute: CogitoAttribute):
	assigned_player_attribute = _player_attribute
	
	#Setting up icon, bar and label
	attribute_icon.texture = assigned_player_attribute.attribute_icon
	attribute_label.text = str(int(assigned_player_attribute.value_current))
	bar_stylebox.bg_color = assigned_player_attribute.attribute_color
	attribute_bar.add_theme_stylebox_override("fill",bar_stylebox)

	#Setting bar to correct values
	attribute_bar.max_value = assigned_player_attribute.value_max
	attribute_bar.value = assigned_player_attribute.value_current
	
	_player_attribute.attribute_changed.connect(on_attribute_changed)
	
	
func on_attribute_changed(_attribute_name:String,_value_current:float,_value_max:float,_has_increased:bool):
	attribute_bar.max_value = _value_max
	attribute_bar.value = _value_current
	attribute_label.text = str(int(_value_current))
