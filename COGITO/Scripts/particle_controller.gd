extends GPUParticles3D

@export var self_destructs : bool

func _ready():
	restart()
	finished.connect(_on_finished)

func _on_finished():
	if self_destructs:
		queue_free()
