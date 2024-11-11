extends Control
class_name RemapEntry

@onready var label: Label = $HBoxContainer/Label

@export var action: String
@onready var kbm_bind_button: KbmBindButton = $HBoxContainer/KbmBindButton
@onready var gamepad_bind_button: GamepadBindButton = $HBoxContainer/GamepadBindButton

func _ready():
	update_entry()

func update_entry():
	kbm_bind_button.action = action
	gamepad_bind_button.action = action
