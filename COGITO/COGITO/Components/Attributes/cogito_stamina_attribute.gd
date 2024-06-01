extends CogitoAttribute

@export var stamina_regen_speed : float = 1
@export var run_exhaustion_speed : float = 1
@export var jump_exhaustion : float = 1
@export var regenerate_after : float = 2
@export var auto_regenerate : bool = true

var regen_timer : Timer
var stamina_regen_wait : float
var is_regenerating : bool
var player : Node3D


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
		subtract(run_exhaustion_speed * delta)
		
	if !is_regenerating and regen_timer.is_stopped() and value_current < value_max and !player.is_sprinting:
		regen_timer.start()


func _on_regen_timer_timeout():
	if !is_regenerating:
		is_regenerating = true
