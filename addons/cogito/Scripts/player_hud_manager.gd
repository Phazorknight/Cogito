class_name CogitoPlayerHudManager
extends Control

signal show_inventory
signal hide_inventory

#region Variables

@export_group("Setup")

## Reference to the Node that has the player.gd script.
@export var player : Node

## Used to reset icons etc, useful to have.
@export var empty_texture : Texture2D


@export_group("Interaction Prompts and Hints")
## PackedScene/Prefab for Object Name as it'd pop up in the HUD
@export var object_name_component : PackedScene
## PackedScene/Prefab for Interaction Prompts
@export var prompt_component : PackedScene
## PackedScene/Prefab for Hints
@export var hint_component : PackedScene
## The hint icon that displays when no other icon is passed.
@export var default_hint_icon : Texture2D

## This sets how far away from the player dropped items appear. 0 = items appear on the tip of the player interaction raycast. Negative values mean closer, positive values mean further away that this.
@export var item_drop_distance_offset : float = -1

@export_group("HUD")
## Reference to PackedScene that gets instantiated for each player attribute.
@export var ui_attribute_prefab : PackedScene
## Reference to PackedScene that gets instantiated for each player currency.
@export var ui_currency_prefab : PackedScene
## If you want to have the stamina bar outside of the other attributes, you can set a reference here. This will remove it from the main attribute container
@export var fixed_stamina_bar : CogitoAttributeUi
@export var default_crosshair : Texture2D

@export_group("Interface Screen")
@export var ui_currency_area: Control
## If you want to display the playeres attributes (like a Stats menu), put a reference here. If not, leave blank.
@export var attribute_display_node : Control
@export var ui_attribute_display_prefab : PackedScene
## If checked, only attributes that have their visibility set to "Interface" will be shown.
@export var only_show_interface_attributes : bool

var hurt_tween : Tween
var is_inventory_open : bool = false
var device_id : int = -1
var interaction_texture : Texture2D

@onready var damage_overlay = $DamageOverlay
@onready var inventory_interface = $InventoryInterface
@onready var wieldable_hud: PanelContainer = $MarginContainer_BottomUI/WieldableHud # Displays wieldable icons and data. Hides when no wieldable equipped.
@onready var prompt_area: Control = $PromptArea
@onready var hint_area: Control = $HintArea
@onready var ui_attribute_area : BoxContainer = $MarginContainer_BottomUI/PlayerAttributes/MarginContainer/VBoxContainer
@onready var crosshair: Control = $Crosshair
@onready var crosshair_texture: TextureRect = crosshair.get_child(0)

#endregion


func _ready():
	# TESTING THIS
	set_process_unhandled_input(false)
	
	# Connect to signal that detects change of input device
	InputHelper.device_changed.connect(_on_input_device_change)
	# Calling this function once to set proper input icons
	_on_input_device_change(InputHelper.device,InputHelper.device_index)
	
	$DeathScreen.hide()
	damage_overlay.modulate = Color.TRANSPARENT
	
	# Set up for HUD elements for wieldables
	wieldable_hud.hide()
	crosshair_texture.texture = default_crosshair
	
	_setup_player.call_deferred()
	connect_to_external_inventories.call_deferred()


func setup_player(new_player : Node):
	player = new_player
	_setup_player()


func _setup_player():
	#prevent stuck prompts when changing players
	delete_interaction_prompts()

	connect_to_player_signals()
	instantiate_player_attribute_ui()
	instantiate_interface_attributes()
	instantiate_player_currency_ui()
	
	# Fill inventory HUD with player inventory
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.hot_bar_inventory.set_inventory_data(player.inventory_data)


func connect_to_player_signals():
	player.player_interaction_component.interactive_object_detected.connect(set_interaction_prompts)
	player.player_interaction_component.nothing_detected.connect(delete_interaction_prompts)
	player.player_interaction_component.started_carrying.connect(set_drop_prompt)
	player.player_interaction_component.hint_prompt.connect(_on_set_hint_prompt)
	player.player_interaction_component.updated_wieldable_data.connect(_on_update_wieldable_data)
	player.toggled_interface.connect(_on_external_ui_toggle)
	player.toggle_inventory_interface.connect(toggle_inventory_interface)
	player.player_state_loaded.connect(_on_player_state_load)


func instantiate_player_attribute_ui():
	for n in ui_attribute_area.get_children():
		ui_attribute_area.remove_child(n)
		n.queue_free()
		
	for attribute in player.player_attributes.values():
		if fixed_stamina_bar and attribute.attribute_name == "stamina":
			fixed_stamina_bar.initiate_attribute_ui(attribute)
		else:
			if attribute.attribute_visibility == 0 or attribute.attribute_visibility == 1: # Only instantiates Attributes that have visibility set to HUD
				var spawned_attribute_ui = ui_attribute_prefab.instantiate()
				ui_attribute_area.add_child(spawned_attribute_ui)
				if attribute.attribute_name == "health":
					attribute.damage_taken.connect(_on_player_damage_taken)
					attribute.death.connect(_on_player_death)
				
				spawned_attribute_ui.initiate_attribute_ui(attribute)


func instantiate_interface_attributes():
	# Clearing out child nodes
	for n in attribute_display_node.get_children():
		attribute_display_node.remove_child(n)
		n.queue_free()
	
	# Only spawn attributes set to visibility "Interface"
	for attribute in player.player_attributes.values():
		if attribute.attribute_visibility == 1 or attribute.attribute_visibility == 2  : # Only instantiates Attributes that have visibility set to HUD
			var spawned_interface_attribute = ui_attribute_display_prefab.instantiate()
			attribute_display_node.add_child(spawned_interface_attribute)
			spawned_interface_attribute.initiate_interface_ui(attribute)


func instantiate_player_currency_ui():
	for n in ui_currency_area.get_children():
		ui_currency_area.remove_child(n)
		n.queue_free()
	
	for currency in player.player_currencies.values():
		var spawned_currency_ui = ui_currency_prefab.instantiate()
		ui_currency_area.add_child(spawned_currency_ui)
		spawned_currency_ui.initiate_currency_ui(currency)


func connect_to_external_inventories(): # Grabbing external inventories in scene.
	for node in get_tree().get_nodes_in_group("external_inventory"):
		CogitoGlobals.debug_log(true, "player_hud_manager", node.name + " is in external_inventory group.")
		if !node.is_connected("toggle_inventory",toggle_inventory_interface):
			node.toggle_inventory.connect(toggle_inventory_interface)


func _on_player_state_load():
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.hot_bar_inventory.set_inventory_data(player.inventory_data)
	connect_to_external_inventories()
	player.inventory_data.inventory_updated.emit(player.inventory_data)


func _is_steam_deck() -> bool:
	if RenderingServer.get_rendering_device().get_device_name().contains("RADV VANGOGH") \
	or OS.get_processor_name().contains("AMD CUSTOM APU 0405"):
		return true
	else:
		return false


func _on_input_device_change(_device, _device_index):
	# Used to update HUD on device change.
	pass


func toggle_inventory_interface(external_inventory_owner = null):
	if !inventory_interface.is_inventory_open:
		inventory_interface.open_inventory()
		_on_external_ui_toggle(true)
		if external_inventory_owner:
			external_inventory_owner.open()
		show_inventory.emit()
	else:
		inventory_interface.close_inventory()
		if external_inventory_owner:
			external_inventory_owner.close()
		_on_external_ui_toggle(false)
		hide_inventory.emit()
		
	if external_inventory_owner and inventory_interface.is_inventory_open:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()


### Interaction Prompt UI:
func set_interaction_prompts(passed_interaction_nodes : Array[Node]):
	delete_interaction_prompts() # clear prompts whenever new ones are received
	
	if passed_interaction_nodes.size() < 1:
		return
	
	var interactive_object = passed_interaction_nodes[0].get_parent()
	var display_name : String = interactive_object.display_name
	if display_name:
		var instanced_object_name : UiObjectNameComponent = object_name_component.instantiate()
		prompt_area.add_child(instanced_object_name)
		instanced_object_name.set_object_name(display_name)
	
	for node in passed_interaction_nodes:
		if node.is_disabled:
			continue
		if node.attribute_check == 2 and !node.check_attribute(player.player_interaction_component):  # Hide if attribute check is set to Hide Interaction and the check doesn't pass
			continue
		
		var instanced_prompt: UiPromptComponent = prompt_component.instantiate()
		prompt_area.add_child(instanced_prompt)
		instanced_prompt.set_prompt(node.interaction_text, node.input_map_action)


func delete_interaction_prompts() -> void:
	for prompt in prompt_area.get_children():
		prompt.discard_prompt()


func set_drop_prompt(_carrying_node):
	delete_interaction_prompts()
	
	# Create an input prompt if a PickupComponent or BackpackComponent exists
	# This approach isn't great, but doesn't affect the passed argument or connected signals
	# Build this input prompt first to maintain the same prompt layout
	var carry_parent: CogitoObject = _carrying_node.get_parent() as CogitoObject
	if carry_parent:
		for node: InteractionComponent in carry_parent.interaction_nodes:
			if node is PickupComponent or node is BackpackComponent:
				var instanced_take_prompt: UiPromptComponent = prompt_component.instantiate()
				prompt_area.add_child(instanced_take_prompt)
				instanced_take_prompt.set_prompt(node.interaction_text, node.input_map_action)
				break # Break out of the loop as no object should have both
	
	var instanced_prompt: UiPromptComponent = prompt_component.instantiate()
	prompt_area.add_child(instanced_prompt)
	instanced_prompt.set_prompt("Drop", _carrying_node.input_map_action)
	
	# Create the rotation input prompt
	if _carrying_node.enable_manual_rotating:
		var instanced_secondary_prompt: UiPromptComponent = prompt_component.instantiate()
		prompt_area.add_child(instanced_secondary_prompt)
		instanced_secondary_prompt.set_prompt("Rotate", "action_secondary")


#What happens when an external UI is shown (like inventory, readbale document, keypad, external inventory)
func _on_external_ui_toggle(is_showing:bool):
	if is_showing:
		player._on_pause_movement()
		player.is_showing_ui = true
		prompt_area.hide()
		crosshair.hide()
	else:
		player._on_resume_movement()
		player.is_showing_ui = false
		prompt_area.show()
		crosshair.show()


# When HUD receives set use prompt signal (usually when equipping a wieldable)
func _on_set_use_prompt(_passed_use_text):
	print("Player HUD manager: _on_set_use_prompt called")
	# DEPRECATED: Showing these prompts felt increasingly useless.
	pass


# Updating HUD wieldable data, used for stuff like flashlight battery charge, ammo display, etc
func _on_update_wieldable_data(passed_wieldable_item: WieldableItemPD, passed_ammo_in_inventory: int, passed_ammo_item: AmmoItemPD):
	if passed_wieldable_item:
		wieldable_hud.show()
		wieldable_hud.update_wieldable_data(passed_wieldable_item, passed_ammo_in_inventory, passed_ammo_item)
		if passed_wieldable_item.wieldable_crosshair:
			crosshair_texture.texture = passed_wieldable_item.wieldable_crosshair
		else:
			crosshair_texture.texture = default_crosshair
	else:
		crosshair_texture.texture = default_crosshair
		wieldable_hud.hide()


# NEW Hint System
func _on_set_hint_prompt(passed_int_icon, passed_hint_text):
	var instanced_hint = hint_component.instantiate()
	hint_area.add_child(instanced_hint)
	instanced_hint.set_hint(passed_int_icon,passed_hint_text)


# Function that controls damage vignette when damage taken.
func _on_player_damage_taken():
	damage_overlay.modulate = Color.WHITE
	if hurt_tween:
		hurt_tween.kill()
	hurt_tween = create_tween()
	hurt_tween.tween_property(damage_overlay,"modulate", Color.TRANSPARENT, .3)


# Function called when player dies.
func _on_player_death():
	player._on_pause_movement()
	$DeathScreen.open_death_screen()


# Button appears on player death. TODO change to load latest save?
func _on_restart_button_pressed():
	get_tree().reload_current_scene()


# On Inventory UI Item Drop
func _on_inventory_interface_drop_slot_data(slot_data: InventorySlotPD):
	pass
