extends Area3D

@export var ladder_collision : CollisionObject3D
var original_process_mode : ProcessMode

func _ready():
	body_shape_entered.connect(_on_body_shape_entered)
	body_exited.connect(_on_body_exited)
	if ladder_collision:
		original_process_mode = ladder_collision.process_mode

func _on_body_shape_entered(_body_rid,body,_body_shape_idx,local_shape_idx):
	if body.is_in_group("Player"):
		#print("Entered ladder")
		var local_shape_owner = shape_find_owner(local_shape_idx)
		var local_shape_node = shape_owner_get_owner(local_shape_owner) as CollisionShape3D
		
		var ladderDir = (local_shape_node.global_position - global_position).normalized()
		
		body.enter_ladder(local_shape_node,ladderDir)
		if body.on_ladder and ladder_collision:
			original_process_mode = ladder_collision.process_mode
			#ladder_collision.process_mode = Node.PROCESS_MODE_DISABLED


func _on_body_exited(body):
	if body.is_in_group("Player"):
		#print("Exited ladder")
		body.on_ladder = false
		if ladder_collision:
			ladder_collision.process_mode = original_process_mode
