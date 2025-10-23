class_name CogitoPauseMenu
extends Control

## You can override this class to add buttons to your pause menu
## look at the function open_options_menu for an example of showing a submenu
## also remember to add a hide call for your menu in _input

signal resume
signal back_to_main_pressed

#region Variables
@export var nodes_to_focus: Array[Control]
@export var sound_hover : AudioStream
@export var sound_click : AudioStream
@export var empty_slot_texture : Texture

var playback : AudioStreamPlaybackPolyphonic
var temp_screenshot : Image

@onready var resume_game_button: Button = %ResumeGameButton
@onready var save_button: CogitoUiButton = %SaveButton
@onready var load_button: CogitoUiButton = %LoadButton
@onready var label_active_slot: Label = %Label_ActiveSlot
@onready var options_tab_menu: OptionsTabMenu = $Content/OptionsTabMenu
@onready var game_menu: MarginContainer = $Content/GameMenu
#endregion


func _enter_tree() -> void:
	# Create an audio player
	var player = AudioStreamPlayer.new()
	add_child(player)

	# Create a polyphonic stream so we can play sounds directly from it
	var stream = AudioStreamPolyphonic.new()
	stream.polyphony = 32
	player.stream = stream
	player.play()
	# Get the polyphonic playback stream to play sounds
	playback = player.get_stream_playback()

	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node:Node) -> void:
	if node is Button:
		# If the added node is a button we connect to its mouse_entered and pressed signals
		# and play a sound
		node.mouse_entered.connect(_play_hover)
		node.focus_entered.connect(_play_hover)
		node.pressed.connect(_play_pressed)


func _play_hover() -> void:
	playback.play_stream(sound_hover, 0, 0, 1)


func _play_pressed() -> void:
	playback.play_stream(sound_click, 0, 0, 1)


func open_pause_menu():
	#Stops game and shows pause menu
	get_tree().paused = true
	label_active_slot.text = "Current Slot: " + CogitoSceneManager._active_slot
	temp_screenshot = grab_temp_screenshot()
	show()
	game_menu.show()
	options_tab_menu.hide()
	if load_current_slot_data(): # If slot save data found
		load_button.disabled = false
	else: # If no slot save data found
		load_button.disabled = true
		label_active_slot.visible = false
		
	resume_game_button.grab_focus.call_deferred()


func open_options_menu():
	options_tab_menu.show()
	options_tab_menu.load_options(true)
	options_tab_menu.have_options_changed = false
	options_tab_menu.tab_container.nodes_to_focus[0].grab_focus.call_deferred()
	game_menu.hide()


func grab_temp_screenshot() -> Image:
	return get_viewport().get_texture().get_image()


func load_current_slot_data() -> bool:
	# Load screenshot
	var image_path : String = CogitoSceneManager.get_active_slot_player_state_screenshot_path()
	if image_path != "":
		var image : Image = Image.load_from_file(image_path)
		var texture = ImageTexture.create_from_image(image)
		%Screenshot_Spot.texture = texture
	else:
		%Screenshot_Spot.texture = empty_slot_texture
		CogitoGlobals.debug_log(true,"pause_menu_controller.gd", "No screenshot for slot " + CogitoSceneManager._active_slot + " found.")
		return false
		
	# Load save state time
	var savetime : int
	if CogitoSceneManager._player_state:
		savetime = CogitoSceneManager._player_state.player_state_savetime
	if savetime == null or typeof(savetime) != TYPE_INT or savetime == 0:
		%Label_SaveTime.text = ""
		return false
	else:
		var timeoffset = Time.get_time_zone_from_system().bias*60
		var save_time_string = Time.get_datetime_string_from_unix_time(savetime+timeoffset,true)
		%Label_SaveTime.text = save_time_string
		return true


func close_pause_menu():
	get_tree().paused = false
	hide()
	emit_signal("resume")


func _on_resume_game_button_pressed():
	close_pause_menu()


func _on_quit_button_pressed():
	CogitoSceneManager.delete_temp_saves()
	get_tree().quit()


func _on_back_to_menu_button_pressed():
	close_pause_menu()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("back_to_main_pressed")


func _input(event):
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu")) and !game_menu.visible:
		accept_event()
		options_tab_menu.hide()
		game_menu.show()
		resume_game_button.grab_focus.call_deferred()
		return
		
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu")) and visible:
		accept_event()
		close_pause_menu()


func _on_save_button_pressed() -> void:
	CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
	CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
	CogitoSceneManager._screenshot_to_save = temp_screenshot
	CogitoSceneManager.save_player_state(CogitoSceneManager._current_player_node,CogitoSceneManager._active_slot)
	#CogitoSceneManager.save_scene_state(CogitoSceneManager._current_scene_name,CogitoSceneManager._active_slot)
	CogitoSceneManager.save_scene_state(CogitoSceneManager._current_scene_name,"temp")
	CogitoSceneManager.copy_temp_saves_to_slot(CogitoSceneManager._active_slot)
	
	_on_resume_game_button_pressed()


func _on_load_button_pressed() -> void:
	CogitoGlobals.debug_log(true,"pause_menu_controller.gd","LOAD button pressed.")
	CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
	CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
	CogitoSceneManager.delete_temp_saves()
	CogitoSceneManager.copy_slot_saves_to_temp(CogitoSceneManager._active_slot)
	#CogitoSceneManager.loading_saved_game(CogitoSceneManager._active_slot)
	
	_on_resume_game_button_pressed()
