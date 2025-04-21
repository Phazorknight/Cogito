extends Area3D

@export var target_scale : Vector3
@export var duration : float
@export var damage_amount : float = 6.0
@export var damage_force : float = 10.0
@export var explode_on_spawn : bool = true

var col_shape : Shape3D
var is_exploding : bool = false
var explosion_time : float = 0

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D



#size starts at 1
#in 1sec i want it to grow to 5
#how much does it have to grow each delta?
#
#growth_factor = delta/size


func _ready() -> void:
	# Hiding mesh, getting collision shape reference and setting it to radius zero
	if mesh_instance_3d:
		mesh_instance_3d.hide()
	col_shape = collision_shape_3d.shape as SphereShape3D
	#col_shape.radius = 0.1
	if explode_on_spawn:
		explode.call_deferred()


func explode() -> void:
	mesh_instance_3d.show()
	is_exploding = true
	
	var explosion_tween = create_tween()
	var collision_tween = create_tween()
	
	var initial_scale = mesh_instance_3d.transform.basis.get_scale()
	explosion_tween.tween_method(
		_apply_scale.bind(mesh_instance_3d), 
		initial_scale, 
		target_scale, 
		duration,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	collision_tween.tween_property(col_shape, "radius", target_scale.x/2, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await explosion_tween.finished
	finish()


func finish():
	self.queue_free()


func _apply_scale(scale: Vector3, obj: Node3D):
	var transform = obj.transform
	transform.basis = transform.basis.scaled(scale / transform.basis.get_scale())
	obj.transform = transform




func _on_body_entered(collider: Node3D) -> void:
	var damage_dir = self.global_position.direction_to(collider.global_position)
		
	if collider is CogitoPlayer:
		#TODO This should be done via signals.
		collider.apply_external_force(damage_dir * damage_force)
		CogitoGlobals.debug_log(true,"Explosion","Damaging player. Applying vector " + str(damage_dir * damage_force) + " to target. Target.main_velocity = " + str(collider.main_velocity) )
		collider.decrease_attribute("health", damage_amount)

	if collider.has_signal("damage_received"):
		if !collider.cogito_properties: # Case where neither projectile nor the object hit have properties defined.
			CogitoGlobals.debug_log(true, "Explosion", "Collider nor projectile have CogitoProperties, damaging as usual.")
			deal_damage(collider,damage_dir)
			return
		
		if collider.cogito_properties: # Case were only collider has properties.
			CogitoGlobals.debug_log(true, "Explosion", "Collider has CogitoProperties, currently ignoring these and damaging as usual.")
			deal_damage(collider,damage_dir)


func deal_damage(collider: Node,damage_dir):
	collider.damage_received.emit(damage_amount,damage_dir,Vector3.ZERO)
