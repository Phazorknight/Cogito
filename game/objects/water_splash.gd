extends Node3D
@onready var splash_stream_player_3d = $SplashStreamPlayer3D
@onready var droplets = $Droplets


func _ready():
	droplets.emitting = true
	splash_stream_player_3d.play()

func _on_droplets_finished():
	if splash_stream_player_3d.playing != true:
		die()

func _on_splash_stream_player_3d_finished():
	if droplets.emitting != true:
		die()

func die():
	queue_free()

func _on_timer_timeout():
	#if it's alive too long kill it.
	die()
