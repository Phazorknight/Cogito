# Full video: https://www.youtube.com/watch?v=OEpfdmW6_s0
# (c) Bryce Dixon, distributed under MIT License: https://github.com/BtheDestroyer/Godot_QuickAudio
@icon("./icon.svg")
extends Node

@onready var tree := get_tree() # Gets the slightest of performance improvements by caching the SceneTree

func _play_sound(sound: AudioStream, player, autoplay := true):
	player.stream = sound
	player.autoplay = autoplay
	player.finished.connect(func(): player.queue_free())
	tree.current_scene.add_child(player)
	return player

# Use this for non-diagetic music or UI sounds which have no position
func play_sound(sound: AudioStream, autoplay := true) -> AudioStreamPlayer:
	return _play_sound(sound, AudioStreamPlayer.new(), autoplay)

# Use this for 2D gameplay sounds which should fade with distance
# Note: Remember to set the global_position or reparent(new_parent, false)!
func play_sound_2d(sound: AudioStream, autoplay := true) -> AudioStreamPlayer2D:
	return _play_sound(sound, AudioStreamPlayer2D.new(), autoplay)

# Use this for 3D gameplay sounds which should fade with distance
# Note: Remember to set the global_position or reparent(new_parent, false)!
func play_sound_3d(sound: AudioStream, autoplay := true) -> AudioStreamPlayer3D:
	return _play_sound(sound, AudioStreamPlayer3D.new(), autoplay)
	
	
#########################################
# Extra fun stuff for music transitions #
#########################################

func fade_in(audio_stream_player, seconds := 1.0, tween := create_tween()):
	if not (audio_stream_player is AudioStreamPlayer or audio_stream_player is AudioStreamPlayer2D or audio_stream_player is AudioStreamPlayer3D):
		push_error("Non-AudioStreamPlayer[XD] provided to Audio.fade_in(...)")
		return
	tween.tween_method(func(x): audio_stream_player.volume_db = linear_to_db(x), db_to_linear(audio_stream_player.volume_db), 1.0, seconds)
	
	
func fade_out(audio_stream_player, seconds := 1.0, tween := create_tween()):
	if not (audio_stream_player is AudioStreamPlayer or audio_stream_player is AudioStreamPlayer2D or audio_stream_player is AudioStreamPlayer3D):
		push_error("Non-AudioStreamPlayer[XD] provided to Audio.fade_out(...)")
		return
	tween.tween_method(func(x): audio_stream_player.volume_db = linear_to_db(x), db_to_linear(audio_stream_player.volume_db), 0.0, seconds)
	tween.tween_callback(func(): audio_stream_player.stop(); audio_stream_player.queue_free())
	
	
func cross_fade(audio_stream_player_out, audio_stream_player_in, seconds := 1.0, tween := create_tween()):
	if not (audio_stream_player_out is AudioStreamPlayer or audio_stream_player_out is AudioStreamPlayer2D or audio_stream_player_out is AudioStreamPlayer3D):
		push_error("Non-AudioStreamPlayer[XD] provided to Audio.cross_fade(...) as audio_stream_player_out")
		return
	if not (audio_stream_player_in is AudioStreamPlayer or audio_stream_player_in is AudioStreamPlayer2D or audio_stream_player_in is AudioStreamPlayer3D):
		push_error("Non-AudioStreamPlayer[XD] provided to Audio.cross_fade(...) as audio_stream_player_in")
		return
	fade_in(audio_stream_player_in, seconds, tween)
	fade_out(audio_stream_player_out, seconds, tween.parallel())

func sequential_fade(audio_stream_player_out, audio_stream_player_in, out_seconds := 1.0, in_seconds := out_seconds, tween := create_tween(), empty_seconds := 0.0):
	if not (audio_stream_player_out is AudioStreamPlayer or audio_stream_player_out is AudioStreamPlayer2D or audio_stream_player_out is AudioStreamPlayer3D):
		push_error("Non-AudioStreamPlayer[XD] provided to Audio.sequential_fade(...) as audio_stream_player_out")
		return
	if not (audio_stream_player_in is AudioStreamPlayer or audio_stream_player_in is AudioStreamPlayer2D or audio_stream_player_in is AudioStreamPlayer3D):
		push_error("Non-AudioStreamPlayer[XD] provided to Audio.sequential_fade(...) as audio_stream_player_in")
		return
	fade_out(audio_stream_player_out, out_seconds, tween)
	if empty_seconds > 0.0:
		tween.tween_interval(empty_seconds)
	fade_in(audio_stream_player_in, in_seconds, tween)
