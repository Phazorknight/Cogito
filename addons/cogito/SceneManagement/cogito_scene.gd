extends Node

## List of connector nodes. These are used to place the Player in the correct position when they transition to this scene from a different scene. The Node name needs to match the passed string for this to work.
@export var connectors : Array[Node3D]
## Saves scene and player temp states
@export var save_temp_on_enter : bool = false

@export_category("Music Settings")
@onready var music_player: AudioStreamPlayer
@export var bgm_neutral : AudioStream
@export var bgm_combat : AudioStream
@export_range(-80.0, 24.0) var music_max_volume_db : float = -6.0


func move_player_to_connector(connector_name:String):
	for node in connectors:
		if node.get_name() == connector_name:
			CogitoGlobals.debug_log(true, "CogitoScene.gd", "Connector found, moving player to " + node.get_name() )
			CogitoSceneManager._current_player_node.global_position = node.global_position
			CogitoSceneManager._current_player_node.body.global_rotation = node.global_rotation
			return
	
	CogitoGlobals.debug_log(true, "CogitoScene.gd",  "No connector with name " + connector_name + " found.")


func _enter_tree() -> void:
	CogitoSceneManager._current_scene_root_node = self
	CogitoGlobals.debug_log(true, "CogitoScene.gd", "Current scene root node set to " + CogitoSceneManager._current_scene_root_node.name )
	
	setup_bgm.call_deferred()
	if save_temp_on_enter:
		save_temp.call_deferred()


func save_temp() -> void:
	var current_scene_statename = get_tree().get_current_scene().get_name()
	CogitoSceneManager.save_scene_state(current_scene_statename,"temp")
	CogitoSceneManager.save_player_state(CogitoSceneManager._current_player_node, "temp")


func setup_bgm() -> void:
	var valid := true
	if not is_instance_valid(bgm_neutral):
		CogitoGlobals.debug_log(true, "cogito_scene.gd", "Scene Music is lacking a \"bgm_neutral\". Set it in the inspector on the node: {0}".format([get_path()]))
		valid = false
	if not is_instance_valid(bgm_combat):
		CogitoGlobals.debug_log(true, "cogito_scene.gd", "Scene Music Demo script is lacking a \"bgm_combat\". Set it in the inspector on the node: {0}".format([get_path()]))
		valid = false
	if valid:
		music_player = Audio.play_sound(bgm_neutral,false)
		music_player.set_bus("Music")
		music_player.volume_db = -80.0 #Start at mute
		music_fade_in(music_player, 4, music_max_volume_db)
		music_player.play()


func music_fade_in(audio_stream_player, seconds := 1.0, max_volume_db:= 0.0, tween := create_tween()):
	if not (audio_stream_player is AudioStreamPlayer or audio_stream_player is AudioStreamPlayer2D or audio_stream_player is AudioStreamPlayer3D):
		push_error("Non-AudioStreamPlayer[XD] provided to Audio.fade_in(...)")
		return
	tween.tween_method(func(x): audio_stream_player.volume_db = linear_to_db(x), db_to_linear(audio_stream_player.volume_db), db_to_linear(max_volume_db), seconds)
