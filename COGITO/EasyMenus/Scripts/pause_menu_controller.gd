extends Control
signal resume
signal back_to_main_pressed

@onready var content : VBoxContainer = $%Content
@onready var options_menu : Control = $%OptionsMenu
@onready var resume_game_button: Button = $%ResumeGameButton

#region UI AUDIO
@export var sound_hover : AudioStream
@export var sound_click : AudioStream
var playback : AudioStreamPlaybackPolyphonic


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
		node.pressed.connect(_play_pressed)


func _play_hover() -> void:
	playback.play_stream(sound_hover, 0, 0, 1)


func _play_pressed() -> void:
	playback.play_stream(sound_click, 0, 0, 1)
#endregion


func open_pause_menu():
	#Stops game and shows pause menu
	get_tree().paused = true
	show()
	resume_game_button.grab_focus()
	
func close_pause_menu():
	get_tree().paused = false
	hide()
	emit_signal("resume")

func _on_resume_game_button_pressed():
	close_pause_menu()


func _on_options_button_pressed():
	content.hide()
	options_menu.show()
	options_menu.on_open()


func _on_options_menu_close():
	options_menu.hide()
	content.show()
	resume_game_button.grab_focus()

func _on_quit_button_pressed():
	get_tree().quit()


func _on_back_to_menu_button_pressed():
	close_pause_menu()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("back_to_main_pressed")

func _input(event):
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")) and visible and !options_menu.visible:
		accept_event()
		close_pause_menu()


func _on_save_button_pressed() -> void:
	CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
	CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
	CogitoSceneManager.save_player_state(CogitoSceneManager._current_player_node,CogitoSceneManager._active_slot)
	CogitoSceneManager.save_scene_state(CogitoSceneManager._current_scene_name,CogitoSceneManager._active_slot)
	

func _on_load_button_pressed() -> void:
	CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
	CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
	CogitoSceneManager.loading_saved_game(CogitoSceneManager._active_slot)
	
	_on_resume_game_button_pressed()
	
