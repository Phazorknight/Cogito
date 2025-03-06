extends Control
class_name CogitoDeathScreen

signal back_to_main_pressed

#region Variables
@export var nodes_to_focus: Array[Control]
@export var sound_hover : AudioStream
@export var sound_click : AudioStream
@export var empty_slot_texture : Texture

var playback : AudioStreamPlaybackPolyphonic
var temp_screenshot : Image

@onready var label_active_slot: Label = %Label_ActiveSlot
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


func open_death_screen():
	#Stops game and shows pause menu
	get_tree().paused = true
	label_active_slot.text = "Current Slot: " + CogitoSceneManager._active_slot
	temp_screenshot = grab_temp_screenshot()
	show()
	load_current_slot_data()
	nodes_to_focus[0].grab_focus.call_deferred()


func grab_temp_screenshot() -> Image:
	return get_viewport().get_texture().get_image()


func load_current_slot_data():
	# Load screenshot
	var image_path : String = CogitoSceneManager.get_active_slot_player_state_screenshot_path()
	if image_path != "":
		var image : Image = Image.load_from_file(image_path)
		var texture = ImageTexture.create_from_image(image)
		%Screenshot_Spot.texture = texture
	else:
		%Screenshot_Spot.texture = empty_slot_texture
		print("No screenshot for slot ", CogitoSceneManager._active_slot, " found.")
		
	# Load save state time
	var savetime : int
	if CogitoSceneManager._player_state:
		savetime = CogitoSceneManager._player_state.player_state_savetime
	if savetime == null or typeof(savetime) != TYPE_INT or savetime == 0:
		%Label_SaveTime.text = ""
	else:
		var timeoffset = Time.get_time_zone_from_system().bias*60
		var save_time_string = Time.get_datetime_string_from_unix_time(savetime+timeoffset,true)
		%Label_SaveTime.text = save_time_string


func _on_quit_button_pressed():
	CogitoSceneManager.delete_temp_saves()
	get_tree().quit()


func _on_back_to_menu_button_pressed():
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	back_to_main_pressed.emit()


func _on_load_button_pressed() -> void:
	get_tree().paused = false
	hide()
	CogitoGlobals.debug_log(true,"DeathScreen","LOAD button pressed.")
	CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
	CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
	CogitoSceneManager.delete_temp_saves()
	CogitoSceneManager.copy_slot_saves_to_temp(CogitoSceneManager._active_slot)
