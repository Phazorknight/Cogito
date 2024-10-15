extends Area3D

func _on_body_entered(body):
	if body.is_in_group("Player") :
		body.increase_attribute("visibility", 1, ConsumableItemPD.ValueType.CURRENT)
		

func _on_body_exited(body):
	if body.is_in_group("Player") :
		body.decrease_attribute("visibility", 1)
