extends Node

@export var audio_objects = {}

@onready var player_sfx = $PlayerSFX
@onready var player_music = $PlayerMusic

var audio_object : AudioObjectPD

func play_audio(sound_name):
	if audio_objects.has(sound_name):
		audio_object = audio_objects.get(sound_name)
		if audio_object.is_music:
			play_music()
		else:
			play_sfx()
		
	else:
		print(sound_name, " not found in dictionary.")
		
		
func play_music():
	player_music.stream = audio_object.audio_file
	player_music.volume_db = linear_to_db(audio_object.volume)
	print("playing as music.")
	player_music.play()
	
func play_sfx():
	player_sfx.stream = audio_object.audio_file
	player_sfx.volume_db = linear_to_db(audio_object.volume)
	player_sfx.play()
