extends InteractionComponent
class_name BackpackComponent

@export_group("Backpack Settings")
## Sound that plays when backpack is interacted with
@export var sound_on_use: AudioStream
## The new inventory grid size.
@export var new_inventory_size : Vector2i = Vector2i(8,6)


func interact(_player_interaction_component:PlayerInteractionComponent):
	update_player_inventory(_player_interaction_component.player)
	
	if sound_on_use:
		Audio.play_sound(sound_on_use)
		
	get_parent().queue_free()


func update_player_inventory(player: CogitoPlayer):
	var player_inventory = player.inventory_data
	player_inventory.inventory_size = new_inventory_size
	player_inventory.inventory_slots.resize(player_inventory.inventory_size.x * player_inventory.inventory_size.y)
	player_inventory.force_inventory_update()
