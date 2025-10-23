extends Resource
class_name ContainerItemContent

## Name of the content
@export var content_name : String
## Icon of the content as used for wieldable containers that hold this content
@export var content_icon : Texture2D

@export var consumable_effects : Array[ConsumableEffect]

func use(target) -> void:
	# Target should always be player? Null check to override using the CogitoSceneManager, which stores a reference to current player node
	if target == null or target.is_in_group("external_inventory"):
		CogitoGlobals.debug_log(true, "ConsumableEffect", "Bad target pass. Setting target to" + str(CogitoSceneManager._current_player_node) )
		target = CogitoSceneManager._current_player_node
	
	if consumable_effects:
			for effect in consumable_effects:
				effect.use(target)
