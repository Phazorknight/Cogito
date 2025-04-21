extends Node

# These will be autofilled by the StateMachine
var Host # is our Character node (parent of StateMachine)
var States # is the StateMachine itself

@export var state_after_attack : String

@export_group("Attack properties")
## How long this attack takes.
@export var attack_duration : float = 0.5
## The damage that will be sent to target
@export var attack_damage : int = 1
## The stagger/bounce back strength of the attack
@export var attack_stagger : float = 8.0
@export var attack_sound : AudioStream

var target : Node3D = null
var count_down : float = 0


func _state_enter():
	target = Host.attention_target
	
	if !target:
		CogitoGlobals.debug_log(true,"NPC State Attack","Target was null, going to previous state...")
		States.load_previous_state()
	else:
		count_down = attack_duration
		attempt_attack()


func _state_exit() -> void:
	pass


func _physics_process(_delta):
	# Lerping down the velocity
	Host.velocity.x = move_toward(Host.velocity.x, 0, _delta * Host.move_speed)
	Host.velocity.z = move_toward(Host.velocity.z, 0, _delta * Host.move_speed)
	Host.move_and_slide()
	
	if count_down <= 0:
		attempt_attack()
		States.goto(state_after_attack)
	else:
		count_down -= _delta


func attempt_attack():
	count_down = attack_duration
	# plays animation even if target is not within reach
	Host.animation_tree.set("parameters/UpperBodyState/RaisedFists/attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	if Host.global_position.distance_to(target.global_position) <= 1.5:
		attack(target)


func attack(target: Node3D):
	var dir = Host.global_position.direction_to(target.global_position)
	
	# Delay to line up damage dealing with animation. GET RID OF MAGIC NUMBER
	await get_tree().create_timer(0.15).timeout
	
	Audio.play_sound_3d(attack_sound).global_position = Host.global_position
	
	if target is CogitoPlayer:
		#TODO This should be done via signals.
		target.apply_external_force(dir * attack_stagger)
		CogitoGlobals.debug_log(true,"NPC State Attack","Attacking player. Applying vector " + str(dir * attack_stagger) + " to target. Target.main_velocity = " + str(target.main_velocity) )
		target.decrease_attribute("health", attack_damage)
	if target.has_signal("damage_received"):
		var damage_direction = (self.global_position + target.global_position).abs()
		print(self.name, ": dealing damage amount ", attack_damage, " on target ", target.name, " in direction ", damage_direction )
		target.damage_received.emit(attack_damage,damage_direction)
		return
	else:
		# Apply damage using hitbox container logic...?
		pass
