extends CogitoAttribute

# amount of damage received when breath is empty
@export var suffocation_damage : float = 1.0 
var player : CogitoPlayer

# how frequently the player takes ticks of suffocation damage
@export var suffocation_damage_timer : float = 1.5
var suffocation_timer_current : float
# how fast oxygen regenerates in breathable areas
@export var breath_regen_speed : float = 0.5

func _ready():
	player = get_parent()
	suffocation_timer_current = suffocation_damage_timer

func out_of_breath(delta : float):
	if suffocation_timer_current <= 0.0:
		player.decrease_attribute("health", suffocation_damage)
		suffocation_timer_current = suffocation_damage_timer
	else:
		suffocation_timer_current -= delta

func check_breath():
	if !player.is_head_submerged():
		if suffocation_timer_current < suffocation_damage_timer:
			# just make sure the timer resets for consistency underwater
			suffocation_timer_current = suffocation_damage_timer
		player.increase_attribute("breath", breath_regen_speed, ConsumableItemPD.ValueType.CURRENT)
	else:
		player.decrease_attribute("breath", breath_regen_speed / 4)

func _process(delta):
	check_breath()
	if value_current <= 0:
		out_of_breath(delta)
