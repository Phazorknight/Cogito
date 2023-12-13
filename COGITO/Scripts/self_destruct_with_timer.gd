extends Node

@onready var lifespan = $Lifespan
var damage_amount : int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	lifespan.timeout.connect(on_timeout)


func on_timeout():
	queue_free()


func _on_body_entered(body):
	if body is HitboxComponent:
		body.damage(damage_amount)
		queue_free()
