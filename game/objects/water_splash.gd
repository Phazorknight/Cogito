extends Node3D
@onready var splash_stream_player_3d = $SplashStreamPlayer3D
@onready var droplets = $Droplets
@onready var steam = $Steam


func _ready():
	droplets.emitting = true
	steam.emitting = true
	splash_stream_player_3d.play()

func _on_steam_finished():
	queue_free()
