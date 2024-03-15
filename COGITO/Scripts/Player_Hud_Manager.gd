extends Control

signal show_inventory
signal hide_inventory

@onready var damage_overlay = $DamageOverlay
@onready var inventory_interface = $InventoryInterface
@onready var wieldable_hud: PanelContainer = $MarginContainer_BottomUI/WieldableHud # Displays wieldable icons and data. Hides when no wieldable equipped.

## Reference to the Node that has the player.gd script.
@export var player : Node

var hurt_tween : Tween
var is_inventory_open : bool = false
var device_id : int = -1
var interaction_texture : Texture2D

## Used to reset icons etc, useful to have.
@export var empty_texture : Texture2D
## The hint icon that displays when no other icon is passed.
@export var default_hint_icon : Texture2D

## PackedScene/Prefab for Interaction Prompts
@export var prompt_component : PackedScene
@onready var prompt_area: Control = $PromptArea

## PackedScene/Prefab for Hints
@export var hint_component : PackedScene
@onready var hint_area: Control = $HintArea

## This sets how far away from the player dropped items appear. 0 = items appear on the tip of the player interaction raycast. Negative values mean closer, positive values mean further away that this.
@export var item_drop_distance_offset : float = -1

## Reference to PackedScene that gets instantiated for each player attribute.
@export var ui_attribute_prefab : PackedScene
@onready var ui_attribute_area : VBoxContainer = $MarginContainer_BottomUI/PlayerAttributes/MarginContainer/VBoxContainer


func _ready():
	# Connect to signal that detects change of input device
	InputHelper.device_changed.connect(_on_input_device_change)
	# Calling this function once to set proper input icons
	_on_input_device_change(InputHelper.device,InputHelper.device_index)
	
	### NEW ATTRIBUTE SYSTEM:
	for attribute in player.player_attributes:
		var spawned_attribute_ui = ui_attribute_prefab.instantiate()
		ui_attribute_area.add_child(spawned_attribute_ui)
		if attribute.attribute_name == "health":
			attribute.damage_taken.connect(_on_player_damage_taken)
			attribute.death.connect(_on_player_death)
		
		spawned_attribute_ui.initiate_attribute_ui(attribute)


	$DeathScreen.hide()
	damage_overlay.modulate = Color.TRANSPARENT
	
	
	# Set up for HUD elements for wieldables
	wieldable_hud.hide()
	
	# Fill inventory HUD with player inventory
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.hot_bar_inventory.set_inventory_data(player.inventory_data)
	
	player.player_interaction_component.interactive_object_detected.connect(set_interaction_prompts)
	player.player_interaction_component.nothing_detected.connect(delete_interaction_prompts)
	player.player_interaction_component.started_carrying.connect(set_drop_prompt)
	
	player.toggled_interface.connect(_on_external_ui_toggle)
	
	player.player_interaction_component.hint_prompt.connect(_on_set_hint_prompt)
	player.toggle_inventory_interface.connect(toggle_inventory_interface)
	player.player_state_loaded.connect(_on_player_state_load)
	player.player_interaction_component.updated_wieldable_data.connect(_on_update_wieldable_data)

	connect_to_external_inventories.call_deferred()


func connect_to_external_inventories(): # Grabbing external inventories in scene.
	for node in get_tree().get_nodes_in_group("external_inventory"):
		print("Is in external_inventory group: ", node)
		if !node.is_connected("toggle_inventory",toggle_inventory_interface):
			node.toggle_inventory.connect(toggle_inventory_interface)


func _on_player_state_load():
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.hot_bar_inventory.set_inventory_data(player.inventory_data)
	connect_to_external_inventories()


func _is_steam_deck() -> bool:
	if RenderingServer.get_rendering_device().get_device_name().contains("RADV VANGOGH") \
	or OS.get_processor_name().contains("AMD CUSTOM APU 0405"):
		return true
	else:
		return false


func _on_input_device_change(_device, _device_index):
	if _device == "keyboard":
		$InventoryInterface/InfoPanel/MarginContainer/VBoxContainer/HBoxDrop.hide()
	else:
		$InventoryInterface/InfoPanel/MarginContainer/VBoxContainer/HBoxDrop.show()


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
	for node in passed_interaction_nodes:
		if !node.is_disabled:
			var instanced_prompt = prompt_component.instantiate()
			prompt_area.add_child(instanced_prompt)
			instanced_prompt.set_prompt(node.interaction_text, node.input_map_action)
	
	
func delete_interaction_prompts():
	var current_prompts = prompt_area.get_children()
	if current_prompts:
		for prompt in current_prompts:
			prompt.discard_prompt()


func set_drop_prompt(_carrying_node):
	var current_prompts = prompt_area.get_children()
	if current_prompts:
		for prompt in current_prompts:
			prompt.discard_prompt()
			
	var instanced_prompt = prompt_component.instantiate()
	prompt_area.add_child(instanced_prompt)
	instanced_prompt.set_prompt("Drop", _carrying_node.input_map_action)


#What happens when an external UI is shown (like inventory, readbale document, keypad, external inventory)
func _on_external_ui_toggle(is_showing:bool):
	if is_showing:
		player._on_pause_movement()
		player.is_showing_ui = true
		prompt_area.hide()
	else:
		player._on_resume_movement()
		player.is_showing_ui = false
		prompt_area.show()


# When HUD receives set use prompt signal (usually when equipping a wieldable)
func _on_set_use_prompt(_passed_use_text):
	print("Player HUD manager: _on_set_use_prompt called")
	# DEPRECATED: Showing these prompts felt increasingly useless.
	pass
	#primary_use_label.text = passed_use_text
	#if passed_use_text != "":
		#primary_use_icon.show()
	#else:
		#primary_use_icon.hide()


# Updating HUD wieldable data, used for stuff like flashlight battery charge, ammo display, etc
func _on_update_wieldable_data(passed_wieldable_item: WieldableItemPD, passed_ammo_in_inventory: int, passed_ammo_item: AmmoItemPD):
	if passed_wieldable_item:
		wieldable_hud.show()
		wieldable_hud.update_wieldable_data(passed_wieldable_item, passed_ammo_in_inventory, passed_ammo_item)
	else:
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
	$DeathScreen.show()
	$DeathScreen/Panel/BoxContainer/VBoxContainer/RestartButton.grab_focus()


# Button appears on player death. TODO change to load latest save?
func _on_restart_button_pressed():
	get_tree().reload_current_scene()


# On Inventory UI Item Drop
func _on_inventory_interface_drop_slot_data(slot_data: InventorySlotPD):
	var scene_to_drop = load(slot_data.inventory_item.drop_scene)
	Audio.play_sound(slot_data.inventory_item.sound_drop)
	var dropped_item = scene_to_drop.instantiate()
	dropped_item.position = player.player_interaction_component.get_interaction_raycast_tip(item_drop_distance_offset)
	dropped_item.find_interaction_nodes()
	for node in dropped_item.interaction_nodes:
		if node.has_method("get_item_type"):
			node.slot_data = slot_data

	get_parent().add_child(dropped_item)
