extends CogitoUiButton
class_name CogitoSaveSlotButton

@onready var screenshot_spot: TextureRect = $MarginContainer/HBoxContainer/Screenshot_Spot
@onready var slot_name_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/SlotName
@onready var save_time_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/SaveTime

@export var save_slot_manager_node : Control
@export var manual_save_slot_name : String
@export var empty_slot_screenshot : Texture2D

var player_state : CogitoPlayerState

func _ready() -> void:
	pressed.connect(_on_save_slot_button_pressed)

	### BRINGING THIS OVER FROM CogitoUiButton due to the override.
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
	
	# Override all the other styleboxes with our tween stylebox
	add_theme_stylebox_override('normal', tween_stylebox)
	add_theme_stylebox_override('hover', tween_stylebox)
	add_theme_stylebox_override('focus', tween_stylebox)
	add_theme_stylebox_override('pressed', tween_stylebox)


func set_data_from_state(_player_state:CogitoPlayerState):
	if _player_state == null:
		slot_name_label.text = "NEW GAME"
		save_time_label.text = ""
		screenshot_spot.texture = empty_slot_screenshot
		player_state = null
		return
	else:
		player_state = _player_state
	
	if player_state.player_state_slot_name:
		slot_name_label.text = "SLOT " + player_state.player_state_slot_name
	else:
		slot_name_label.text = "NEW GAME"

	var savetime : int
	if player_state:
		savetime = player_state.player_state_savetime
	if savetime == null or typeof(savetime) != TYPE_INT:
		save_time_label.text = ""
	else:
		var timeoffset = Time.get_time_zone_from_system().bias*60
		save_time_label.text = Time.get_datetime_string_from_unix_time(savetime+timeoffset,true)

	# Set screenshot
	var image_path : String = player_state.player_state_screenshot_file
	if image_path != "":
		var image : Image = Image.load_from_file(image_path)
		var texture = ImageTexture.create_from_image(image)
		screenshot_spot.texture = texture
	else:
		CogitoGlobals.debug_log(true,"SaveSlotButton.gd","No screenshot for slot " + CogitoSceneManager._active_slot + " found.")


func _on_save_slot_button_pressed() -> void:
	if !player_state:
		CogitoGlobals.debug_log(true,"SaveSlotButton.gd","No player state. Should start a new game.")
		if save_slot_manager_node:
			CogitoSceneManager.switch_active_slot_to(manual_save_slot_name)
			CogitoSceneManager.delete_temp_saves()
			save_slot_manager_node.start_new_game()
	else:
		CogitoGlobals.debug_log(true,"SaveSlotButton.gd","Attempting to load player_state " + player_state.player_state_slot_name)
		CogitoSceneManager._player_state = player_state
		CogitoSceneManager.switch_active_slot_to(player_state.player_state_slot_name)
		CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
		CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
		CogitoSceneManager.delete_temp_saves()
		CogitoSceneManager.copy_slot_saves_to_temp(CogitoSceneManager._active_slot)




func _on_delete_slot_pressed():
	CogitoSceneManager.switch_active_slot_to(manual_save_slot_name)
	if CogitoSceneManager._player_state != null:
		CogitoSceneManager.delete_save(manual_save_slot_name)
		save_slot_manager_node.load_all_save_slots()
	else:
		CogitoGlobals.debug_log(true,"SaveSlotButton.gd","Slot is already empty!")
	
