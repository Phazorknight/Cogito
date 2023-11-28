extends Node
class_name SanityComponent

signal sanity_changed(current_value, max_value)

@export var max_sanity : float = 50
@export var start_sanity : float
@export var decay_rate : float
@export var is_decaying : bool = false

var current_sanity : float
var is_recovering : bool = false
var recovery_rate : float
var recovery_max : float

# Called when the node enters the scene tree for the first time.
func _ready():
	current_sanity = start_sanity

func add(amount):
	current_sanity += amount
	if current_sanity > max_sanity:
		current_sanity = max_sanity
	emit_signal("sanity_changed", current_sanity, max_sanity)
		
func subtract(amount):
	current_sanity -= amount
	if current_sanity < 0:
		current_sanity = 0
	emit_signal("sanity_changed", current_sanity, max_sanity)

func _process(delta):
	if is_decaying:
		subtract(decay_rate * delta)
	
	if is_recovering and current_sanity < recovery_max:
		add(recovery_rate * delta)

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
