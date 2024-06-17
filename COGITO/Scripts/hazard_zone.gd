extends Area3D

signal apply_hazard_effect()

## Enter the player attribute that should get drained within the zone.
@export var player_attribute : String
## The amount that gets drained each second. Higher -> faster.
@export var drain_amount : float = 2
## This flag sets the zone to be recovering instead of draining an attribute.
@export var is_recovery_zone : bool = false
## Hint icon that appears when player enters the zone.
@export var hint_icon : Texture2D
## Hint text that appears when player enteres the zone. Leave blank if you don't want a hint to appear.
@export var hint_message : String
## Used to activate / deactivate this zone on runtime.
@export var is_active : bool = true

var is_within_zone : bool
var player

func _on_body_entered(body):
	if body.is_in_group("Player") :
		player = body
		if hint_message != "":
			body.player_interaction_component.send_hint(hint_icon, hint_message)
		is_within_zone = true

func _on_body_exited(body):
	if body.is_in_group("Player") :
		is_within_zone = false


func interact(_player_interaction_component: PlayerInteractionComponent):
	if is_active:
		monitoring = false
		is_active = false
	else:
		monitoring = true
		is_active = true


func _process(delta):
	if is_within_zone:
		if is_recovery_zone:
			player.increase_attribute(player_attribute, drain_amount * delta, ConsumableItemPD.ValueType.CURRENT)
		else:
			player.decrease_attribute(player_attribute, drain_amount * delta)
