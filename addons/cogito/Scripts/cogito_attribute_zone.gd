extends Area3D

signal apply_attribute_effect()

## Enter the player attribute that is effected within the zone.
@export var player_attribute: String
@export var increase_attribute: bool
## The amount an attribute is changed while in the zone, either immediately or over time based on the effect delay.
@export_range(0.0, 10.0, 0.01, "or_greater") var effect_amount: float = 5.0
## The delay time between effect calls. A value of 0 will change the amount over time.
@export_range(0.0, 10.0, 0.01, "or_greater") var effect_delay: float = 2.0
## On zone enter sets the effect delay to zero to cause an immediate effect on the attribute.
@export var skip_delay_on_zone_enter: bool = true
## Hint icon that appears when player enters the zone.
@export var hint_icon: Texture2D
## Hint text that appears when player enteres the zone. Leave blank if you don't want a hint to appear.
@export var hint_message: String
## Adds a hint message at this rate of effect. Only works when using a delay.
## For example, a rate of 5 will show the hint after every 5 times the attribute is changed by the zone.
## A rate of 0 won't show the hint again after entering the zone.
@export_range(0, 10, 1, "or_greater") var hint_rate: int = 5
## Used to activate / deactivate this zone on runtime.
@export var is_active: bool = true

var is_within_zone: bool
var player
var delay_time: float
var hint_count: int
var hint_delay_time: float


func _on_body_entered(body):
	if body.is_in_group("Player"):
		if !player:
			player = body
		if effect_amount > 0 and hint_message != "":
			body.player_interaction_component.send_hint(hint_icon, hint_message)
		is_within_zone = true
		delay_time = 0 if skip_delay_on_zone_enter else effect_delay
		hint_delay_time = hint_rate
		hint_count = 0


func _on_body_exited(body):
	if body.is_in_group("Player"):
		is_within_zone = false


func interact(_player_interaction_component: PlayerInteractionComponent):
	if is_active:
		monitoring = false
		is_active = false
	else:
		monitoring = true
		is_active = true


func _process(delta):
	if effect_amount == 0.0 or !is_active:
		return
	
	if is_within_zone:
		# Run the timer out before changing the attribute value
		delay_time -= delta
		if delay_time > 0:
			return
		delay_time = effect_delay
		
		# Instantly change the attribute by the effect amount if running a delay
		# Otherwise, change the effect amount over time using the frame delta
		var amount = effect_amount if effect_delay > 0 else effect_amount * delta
		
		if increase_attribute:
			player.increase_attribute(player_attribute, amount, ConsumableItemPD.ValueType.CURRENT)
		else:
			player.decrease_attribute(player_attribute, amount)
		
		if hint_message != "" and hint_rate > 0:
			if effect_delay > 0:
				hint_count += 1
				if hint_count >= hint_rate:
					hint_count = 0
					player.player_interaction_component.send_hint(hint_icon, hint_message)
			else:
				hint_delay_time -= delta
				if hint_delay_time <= 0:
					hint_delay_time = hint_rate
					player.player_interaction_component.send_hint(hint_icon, hint_message)
