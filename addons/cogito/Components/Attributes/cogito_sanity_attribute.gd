extends CogitoAttribute
class_name CogitoSanityAttribute

## The rate at which sanity decays when decaying.
@export var decay_rate : float
## The rate at which sanity increases when recovering.
@export var recovery_rate : float
## Sets if sanity decaus when player visibility attribute is zero.
@export var decay_in_darkness : bool = false
## Amount of damage the player gets when player is out of sanity.
@export var damage_when_zero : float = 2

var is_decaying : bool = false
var is_recovering : bool = false
var recovery_max : float
var player : Node3D


func _ready() -> void:
	value_current = value_start
	player = get_parent()
	


func _process(delta):
	if is_decaying:
		subtract(decay_rate * delta)
	
	if is_recovering and value_current < recovery_max:
		add(recovery_rate * delta)
		
	if value_current <= 0:
		CogitoGlobals.debug_log(true, "CogitoSanityAttribute", "Taking damage due to 0 sanity.")
		player.decrease_attribute("health",damage_when_zero * delta)


func start_decay():
	is_decaying = true


func stop_decay():
	is_decaying = false
	
	
func start_recovery(passed_recovery_rate, passed_recovery_max):
	stop_decay()
	recovery_rate = passed_recovery_rate
	recovery_max = passed_recovery_max
	is_recovering = true


func stop_recovery():
	is_recovering = false
	start_decay()


func on_visibility_changed(_visibility_name:String, _visibility_current:float, _visibility_max:float, _has_increased:bool):
	if _visibility_current > 0:
		stop_decay()
		start_recovery(recovery_rate, (_visibility_current / _visibility_max * value_max))
		
	if _visibility_current <= 0 and decay_in_darkness:
		if is_recovering:
			stop_recovery()
		else:
			start_decay()
