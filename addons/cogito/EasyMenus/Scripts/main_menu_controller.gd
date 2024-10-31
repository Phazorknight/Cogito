extends Control
signal start_game_pressed

@export var first_focus_button: Button
@onready var game_menu: MarginContainer = $ContentMain/GameMenu
@onready var options_tab_menu: OptionsTabMenu = $ContentMain/OptionsTabMenu
@onready var options_button: CogitoUiButton = $ContentMain/GameMenu/VBoxContainer/OptionsButton

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


func _ready():
	first_focus_button.grab_focus()


func quit():
	get_tree().quit()


func _input(event):
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu")) and !game_menu.visible:
		accept_event()
		options_tab_menu.hide()
		game_menu.show()
		options_button.grab_focus.call_deferred()


func open_options_menu():
	options_tab_menu.show()
	options_tab_menu.tab_container.nodes_to_focus[0].grab_focus.call_deferred()
	game_menu.hide()


func _on_start_game_button_pressed():
	emit_signal("start_game_pressed")
