@tool
extends InteractionComponent
class_name CogitoWieldableInteractionComponent

## Player is required to hold this wiedlable to perform the interaction.
@export var required_wieldable : WieldableItemPD
## Sound that plays when interacted.
@export var interaction_sound : AudioStream
## If true, only show this interaction prompt if the player is wielding.
@export var require_wieldable_to_show : bool = false

## Action to perform
enum WieldableAction {
	CHARGE, ## Charges the equipped wieldable with a steady rate
	CONTAINER_ITEM, ## Dispenses container_item_contents to a wieldable container item
	CUSTOM, ## Calls a custom method and passes a custom parameter on the wieldable inventory item (not the wieldable node)
	}
@export var wieldable_action : WieldableAction:
	set(value):
		wieldable_action = value
		notify_property_list_changed()

# Wieldable Action Charge
## How much charge gets added to the wieldable per second.
@export var charge_rate : float = 5.0
var is_charging : bool = false
var player_interaction_component : PlayerInteractionComponent
var audio_stream_player : AudioStreamPlayer

# Wieldable Action Container Item
@export var container_item_to_dispense : ContainerItemContent

## If above is set to custom, method to call on Wieldable
@export var custom_method : String
@export var custom_parameter : int

@onready var parent_node = get_parent()
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _validate_property(property: Dictionary):
	if property.name in ["custom_method", "custom_parameter"] and wieldable_action != WieldableAction.CUSTOM:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["container_item_to_dispense"] and wieldable_action != WieldableAction.CONTAINER_ITEM:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif property.name in ["charge_rate"] and wieldable_action != WieldableAction.CHARGE:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func _ready() -> void:
	#if parent_node.has_signal("object_state_updated"):
		#parent_node.object_state_updated.connect(_on_object_state_change)
	
	if interaction_sound:
		audio_stream_player_3d.set_stream(interaction_sound)


#func _on_object_state_change(_interaction_text: String):
	#interaction_text = _interaction_text


func interact(_player_interaction_component:PlayerInteractionComponent):
	player_interaction_component = _player_interaction_component
	if !is_disabled:
		if attribute_check == AttributeCheck.NONE:
			if check_for_wieldable(_player_interaction_component):
				perform_wieldable_interaction(_player_interaction_component)
			was_interacted_with.emit(interaction_text,input_map_action)
		else:
			if check_attribute(_player_interaction_component):
				if check_for_wieldable(_player_interaction_component):
					perform_wieldable_interaction(_player_interaction_component)
				was_interacted_with.emit(interaction_text,input_map_action)


func check_for_wieldable(_player_interaction_component: PlayerInteractionComponent) -> bool:
	if !_player_interaction_component.is_wielding:
		return false
	if _player_interaction_component.equipped_wieldable_item.name == required_wieldable.name:
		return true
	else:
		_player_interaction_component.send_hint(null, tr("HINT_wrong_wieldable"))
		print("Expected: ", required_wieldable.name, ". Detected: ", _player_interaction_component.equipped_wieldable_item.name )
		return false


func perform_wieldable_interaction(_player_interaction_component: PlayerInteractionComponent):
	match wieldable_action:
		WieldableAction.CHARGE:
			if charge_wieldable(_player_interaction_component):
				pass
			else:
				_player_interaction_component.send_hint(_player_interaction_component.equipped_wieldable_item.icon, tr("HINT_is_full") )
		WieldableAction.CONTAINER_ITEM:
			_player_interaction_component.equipped_wieldable_item.change_content_to(container_item_to_dispense)
			if interaction_sound:
				audio_stream_player_3d.play()
		WieldableAction.CUSTOM:
			print("Attempting to use custom method ", custom_method, " with parameter ", custom_parameter)
			var custom_callable = Callable(_player_interaction_component.equipped_wieldable_item, custom_method)
			custom_callable.call(custom_parameter)
			if interaction_sound:
				audio_stream_player_3d.play()


func _unhandled_input(event: InputEvent) -> void:
	if self.is_visible_in_tree() and event.is_action_released(input_map_action):
		stop_charging()


func _physics_process(delta: float) -> void:
	if !is_charging:
		return
	else:
		player_interaction_component.equipped_wieldable_item.add(charge_rate * delta)
		if !audio_stream_player_3d.playing:
			audio_stream_player_3d.play()
		
		if player_interaction_component.equipped_wieldable_item.charge_current >= player_interaction_component.equipped_wieldable_item.charge_max:
			stop_charging()


func stop_charging():
	is_charging = false
	if audio_stream_player_3d.playing:
		audio_stream_player_3d.stop()


func charge_wieldable(_player_interaction_component: PlayerInteractionComponent) -> bool:
	## Check if wieldable is fully charged.
	if _player_interaction_component.equipped_wieldable_item.charge_current == _player_interaction_component.equipped_wieldable_item.charge_max:
		return false
	else:
		is_charging = true
		audio_stream_player_3d.play()
		return true
