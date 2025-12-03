extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body is CogitoPlayer:
		print("Player entered gravity zone.")
		set_gravity_on_player(body)


func _on_body_exited(body: Node3D) -> void:
	if body is CogitoPlayer:
		print("Player left gravity zone.")
		reset_gravity_on_player(body)


func set_gravity_on_player(_player: CogitoPlayer) -> void:
	_player.override_gravity(gravity, gravity_direction)
	
func reset_gravity_on_player(_player: CogitoPlayer) -> void:
	var default_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	var default_gravity_vector = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
	_player.override_gravity(default_gravity, default_gravity_vector)
