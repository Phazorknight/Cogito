extends Node3D

@export var self_destructs : bool
@export var particles : Array[GPUParticles3D]

func _ready():
	for particle in particles:
		particle.restart()
		
	particles[0].finished.connect(_on_finished)

func _on_finished():
	if self_destructs:
		queue_free()
