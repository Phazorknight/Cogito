extends Node
class_name StaminaComponent

signal stamina_changed(current_value, max_value)

@export var max_stamina : float = 1
@export var stamina_regen_speed : float = 1
@export var run_exhaustion_speed : float = 1
@export var jump_exhaustion : float = 1
@export var regenerate_after : float = 2
@export var auto_regenerate : bool = true

@onready var regen_timer = $Timer

var current_stamina : float
var stamina_regen_wait : float
var is_regenerating : bool
var player

func _ready():
	current_stamina = max_stamina
	player = get_parent()
	regen_timer.wait_time = regenerate_after
	regen_timer.timeout.connect(_on_regen_timer_timeout)


func _process(delta):
	if is_regenerating:
		add(stamina_regen_speed * delta)
		if current_stamina >= max_stamina:
			is_regenerating = false
	
	# Decreases stamina during sprinting
	elif player.is_sprinting and player.current_speed > player.WALKING_SPEED:
		regen_timer.stop()
		is_regenerating = false
		subtract(run_exhaustion_speed * delta)
		
	if !is_regenerating and regen_timer.is_stopped() and current_stamina < max_stamina and !player.is_sprinting:
		regen_timer.start()


func _on_regen_timer_timeout():
	if !is_regenerating:
		is_regenerating = true


func add(amount):
	current_stamina += amount
	if current_stamina > max_stamina:
		current_stamina = max_stamina
	emit_signal("stamina_changed", current_stamina, max_stamina)
		
func subtract(amount):
	current_stamina -= amount
	if current_stamina < 0:
		current_stamina = 0
	emit_signal("stamina_changed", current_stamina, max_stamina)
