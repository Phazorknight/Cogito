@icon("res://COGITO/Assets/Graphics/Editor/Icon_CogitoObject.svg")
extends Node3D
class_name CogitoKeypad

## Emitted when the correct code has been entered.
signal correct_code_entered
## Emitted when the object status changes, used for UI prompts.
signal object_state_updated(interaction_text:String)

@onready var keypad_ui: Control = $KeypadUi
@onready var code_display: Label = $KeypadUi/Bindings/ScrollContainer/VBoxContainer/HBoxContainer/Panel/CodeDisplay
@onready var grab_focus_button : Control = $"KeypadUi/Bindings/ScrollContainer/VBoxContainer/GridContainer/5"
@onready var lock_color: Panel = $KeypadUi/Bindings/ScrollContainer/VBoxContainer/HBoxContainer/LockColor

@export_group("Keypad Settings")
## The code that needs to be entered to unlock. Needs to be just numbers.
@export var passcode : String
## If on, code will be checked immediately once the right amount of digits is entered. if OFF, the player needs to press the E button first.
@export var check_when_entered : bool
## This prompt appears when the keypad is still locked.
@export var interaction_text_when_locked : String = "Enter Code"
## This prompt appears when the keypad has been unlocked.
@export var interaction_text_when_unlocked : String = "Access granted."

## For UI purposes
@export var wrong_code_color : Color = Color.RED
## For UI purposes
@export var correct_code_color : Color = Color.GREEN
## This sets a slight delay before exiting out of the Keypad UI when entering the correct code.
@export var unlock_wait_time : float = 1.0

## Sound that plays in the UI when unlocked.
@export var correct_code_entered_sound : AudioStream
## Sound that playes when the wrong code is entered.
@export var wrong_code_entered_sound : AudioStream

@export_subgroup("Cogito specific settings")
## Cogito Doors that this Keypad unlocks. Can be left blank if used for other purposes.
@export var doors_to_unlock : Array[CogitoDoor]
## If checked, the Cogito Doors will also trigger to open when unlocked.
@export var open_when_unlocked : bool


var interaction_text : String
var is_open: bool #Used to show/hide ui.
var is_locked : bool = true #Used to check if unlocked or not.
var interaction_nodes : Array[Node]
var cogito_properties : CogitoProperties = null
var entered_code: String
var player_interaction_component

var in_focus : bool


func _ready():
	code_display.text = ""
	
	add_to_group("interactable")
	add_to_group("save_object_state")
	interaction_nodes = find_children("","InteractionComponent",true) #Grabs all attached interaction components
	keypad_ui.hide()

	if !is_locked:
		interaction_text = interaction_text_when_unlocked
	else:
		interaction_text = interaction_text_when_locked
		
	object_state_updated.emit(interaction_text)
	get_viewport().connect("gui_focus_changed", self._on_focus_changed)

func _on_focus_changed(control:Control):
	in_focus = is_open and control.owner == self

func interact(_player_interaction_component):
	player_interaction_component = _player_interaction_component
	if is_open:
		close(_player_interaction_component)
	else:
		open(_player_interaction_component)


func open(_player_interaction_component):
	_player_interaction_component.get_parent().toggled_interface.emit(true)
	_player_interaction_component.get_parent().menu_pressed.connect(close) #Connecting input action menu to close function.
	keypad_ui.show()
	grab_focus_button.grab_focus()
	in_focus = true
	is_open = true
	
	
func close(_player_interaction_component):
	keypad_ui.hide()
	_player_interaction_component.get_parent().menu_pressed.disconnect(close)
	_player_interaction_component.get_parent().toggled_interface.emit(false)
	is_open = false
	in_focus = false


func _on_button_received(_passed_string:String):
	if !is_locked:
		print("Already unlocked!")
		return
	
	match _passed_string:
		"C":
			clear_entered_code()
		"E":
			check_entered_code()
		_:
			append_to_entered_code(_passed_string)


func append_to_entered_code(_code_digit:String):
	if entered_code.length() < passcode.length():
		entered_code = entered_code + _code_digit
		update_code_display()
		if entered_code.length() == passcode.length():
			check_entered_code()
	else:
		print("Maximum code length reached")


func update_code_display():
	code_display.text = entered_code
	

func check_entered_code():
	if entered_code == passcode and is_locked:
		unlock_keypad()
	else:
		Audio.play_sound(wrong_code_entered_sound)
		lock_color.modulate = wrong_code_color
		await get_tree().create_timer(unlock_wait_time).timeout
		clear_entered_code()


func unlock_keypad():
	Audio.play_sound(correct_code_entered_sound)
	is_locked = false
	lock_color.modulate = correct_code_color
	interaction_text = interaction_text_when_unlocked
	object_state_updated.emit(interaction_text)

	await get_tree().create_timer(unlock_wait_time).timeout
	
	correct_code_entered.emit() #Emitting signal for potential other connections.
	
	# Unlocking/opening Cogito Doors
	if doors_to_unlock:
		for door in doors_to_unlock:
			door.unlock_door()
			if open_when_unlocked:
				door.open_door(player_interaction_component)
	
	close(player_interaction_component)
	

func clear_entered_code():
	entered_code = ""
	code_display.text = ""


func set_state():
	if is_locked:
		interaction_text = interaction_text_when_locked
	else:
		interaction_text = interaction_text_when_unlocked
	
	object_state_updated.emit(interaction_text)

func _unhandled_input(_event):
	if in_focus:
		get_viewport().set_input_as_handled()

func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"is_locked" : is_locked,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
