extends CogitoAttribute
class_name CogitoStaminaAttribute

@export var stamina_regen_speed : float = 1
@export var run_exhaustion_speed : float = 1
@export var jump_exhaustion : float = 1
@export var regenerate_after : float = 2
@export var auto_regenerate : bool = true
@export_group("Floor Slope Exhaustion Settings")
## If unused, running only drains stamina at the base run exhaustion speed
@export var use_floor_slope_for_run_exhaustion: bool = true
## The max exhaustion speed whil running uphill
@export var uphill_run_exhaustion_max_speed: float = 6.0
## The max exhaustion speed whil running downhill
@export var downhill_run_exhaustion_max_speed: float = 2.0
## Adjusts the exhaustion speed when detecting vertical motion on steps
@export var step_slope_multiplier: float = 4.0

var regen_timer : Timer
var stamina_regen_wait : float
var is_regenerating : bool
var player : Node3D
# Use for run exhaustion on slopes, to get vertical travel difference per frame
var last_y : float

func _ready() -> void:
	value_current = value_start
	player = get_parent()
	
	regen_timer = Timer.new()
	regen_timer.wait_time = regenerate_after
	add_child(regen_timer)
	regen_timer.timeout.connect(_on_regen_timer_timeout)


func _process(delta):
	if is_regenerating:
		add(stamina_regen_speed * delta)
		if value_current >= value_max:
			is_regenerating = false
	
	# Decreases stamina during sprinting
	if player.is_sprinting and player.current_speed > player.WALKING_SPEED and player.velocity.length() > 0.1:
		regen_timer.stop()
		is_regenerating = false
		var exhaustion: float = _run_exhaustion()
		subtract(exhaustion * delta)
	last_y = player.global_position.y
	
	if !is_regenerating and regen_timer.is_stopped() and value_current < value_max and !player.is_sprinting:
		regen_timer.start()


func _on_regen_timer_timeout():
	#if !is_regenerating: # This led to the regen timer to be called every 'regenerate_after'
		#is_regenerating = true
	is_regenerating = value_current < value_max


## Adjusts run exhaustion speed based on floor slope and vertical motion
func  _run_exhaustion() -> float:
	if !use_floor_slope_for_run_exhaustion:
		return run_exhaustion_speed
	
	# Using floor slope to determine run exhaustion speed
	var floor_normal: Vector3 = player.get_floor_normal()
	var movement_direction: Vector3 = player.main_velocity.normalized()
	# Between -1 (180 deg) and 1 (0 deg), based on move direction
	var slope_factor: float = movement_direction.dot(floor_normal)
	
	if is_equal_approx(slope_factor, 0.0): # Running on a flat surface
		# Catches sprinting on flat stairs using last player y position and a multiplier
		if !is_equal_approx(player.global_position.y, last_y): # Still moved up or down
			#print("running on a stepped surface")
			slope_factor = (last_y - player.global_position.y) * step_slope_multiplier
			slope_factor = clampf(slope_factor, -1.0, 1.0)
		else: # Running on flat ground and not moving up or down
			#print("flat ground exhaustion speed is ", run_exhaustion_speed)
			return run_exhaustion_speed
	
	if slope_factor < 0.0001: # Running uphill
		var uphill_run_exhaustion: float = lerpf(run_exhaustion_speed, uphill_run_exhaustion_max_speed, abs(slope_factor))
		#print("uphill exhaustion speed is ", uphill_run_exhaustion)
		return uphill_run_exhaustion
	else: # Running downhill
		var downhill_run_exhaustion: float = lerpf(run_exhaustion_speed, downhill_run_exhaustion_max_speed, slope_factor)
		#print("downhill exhaustion speed is ", downhill_run_exhaustion)
		return downhill_run_exhaustion
