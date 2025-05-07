class_name CogitoAttributeDisplay
extends Control

@onready var attribute_name: Label = $HBoxContainer/VBoxContainer/HBox_Top/AttributeName
@onready var attribute_icon: TextureRect = $HBoxContainer/AttributeIcon
@onready var attribute_bar: CogitoDynamicBar = $HBoxContainer/VBoxContainer/HBox_Bottom/AttributeBar
@onready var attribute_label_current: Label = $HBoxContainer/VBoxContainer/HBox_Top/HBoxValues/AttributeLabelCurrent
@onready var attribute_label_max: Label = $HBoxContainer/VBoxContainer/HBox_Top/HBoxValues/AttributeLabelMax

@export var bar_stylebox: StyleBoxFlat

var assigned_player_attribute : CogitoAttribute


func initiate_interface_ui(_player_attribute: CogitoAttribute):
	assigned_player_attribute = _player_attribute
	
	CogitoGlobals.debug_log(true, "CogitoAttributeDisplay", "Initiating attribute " + assigned_player_attribute.attribute_display_name)
	
	#Setting up icon, bar and label
	attribute_icon.texture = assigned_player_attribute.attribute_icon
	attribute_name.text = assigned_player_attribute.attribute_display_name
	attribute_label_current.text = str(int(assigned_player_attribute.value_current))
	attribute_label_max.text = str(int(assigned_player_attribute.value_max))
	bar_stylebox.bg_color = assigned_player_attribute.attribute_color
	attribute_bar.add_theme_stylebox_override("fill",bar_stylebox)

	#Setting bar to correct values
	#attribute_bar.max_value = assigned_player_attribute.value_max
	#attribute_bar.value = assigned_player_attribute.value_current
	
	attribute_bar.init_values(assigned_player_attribute.value_current, assigned_player_attribute.value_max)
	
	_player_attribute.attribute_changed.connect(on_attribute_changed)
	
	
	
func on_attribute_changed(_attribute_name:String,_value_current:float,_value_max:float,_has_increased:bool):
	attribute_bar.update_value(_value_current, _value_max)
	#attribute_bar.max_value = _value_max
	#attribute_bar.value = _value_current
	attribute_label_current.text = str(int(_value_current))
	attribute_label_max.text = str(int(_value_max))
