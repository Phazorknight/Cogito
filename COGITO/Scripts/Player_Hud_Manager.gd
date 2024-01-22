extends Control

@onready var health_bar = $PlayerAttributes/MarginContainer/VBoxContainer/HealthBar
@onready var sanity_bar = $PlayerAttributes/MarginContainer/VBoxContainer/SanityBar
@onready var brightness_bar = $PlayerAttributes/MarginContainer/VBoxContainer/BrightnessBar
@onready var health_bar_label = $PlayerAttributes/MarginContainer/VBoxContainer/HealthBar/Label
@onready var sanity_bar_label = $PlayerAttributes/MarginContainer/VBoxContainer/SanityBar/Label
@onready var damage_overlay = $DamageOverlay

@onready var stamina_bar = $PlayerAttributes/MarginContainer/VBoxContainer/StaminaBar
@onready var stamina_bar_label = $PlayerAttributes/MarginContainer/VBoxContainer/StaminaBar/Label

@onready var interaction_button = $ButtonPrompt/HBoxContainer/Container/InteractionButton
@onready var interaction_text = $ButtonPrompt/HBoxContainer/InteractionText

@onready var hint_icon = $HintPrompt/MarginContainer/HBoxContainer/HintIcon
@onready var hint_text = $HintPrompt/MarginContainer/HBoxContainer/HintText
@onready var hint_timer = $HintTimer
@onready var inventory_interface = $InventoryInterface

@onready var primary_use_icon = $UseBar/HBoxContainer/WieldablePrimaryUse/MarginContainer/PrimaryUseIcon
@onready var primary_use_label = $UseBar/HBoxContainer/WieldablePrimaryUse/PrimaryUseLabel

@onready var wieldable_icon = $UseBar/HBoxContainer/WieldableData/WieldableIcon
@onready var wieldable_text = $UseBar/HBoxContainer/WieldableData/WieldableText

## Reference to the Node that has the player.gd script.
@export var player : Node

var hurt_tween : Tween

var is_inventory_open : bool = false
var device_id : int = -1
var interaction_texture : Texture2D

## Used to reset icons etc, useful to have.
@export var empty_texture : Texture2D
# The hint icon that displays when no other icon is passed.
@export var default_hint_icon : Texture2D

@export_group("Player Components to use")
@export var use_sanity_component : bool
@export var use_brightness_component : bool
@export var use_stamina_component : bool


func _ready():
	# Connect to signal that detects change of input device
	InputHelper.device_changed.connect(_on_input_device_change)
	# Calling this function once to set proper input icons
	_on_input_device_change(InputHelper.device,InputHelper.device_index)
	
	# Setting up health bar
	health_bar.max_value = player.health_component.max_health
	health_bar.value = player.health_component.current_health
	health_bar_label.text = str(health_bar.value, "/", health_bar.max_value)
	player.health_component.health_changed.connect(_on_player_health_changed)
	player.health_component.damage_taken.connect(_on_player_damage_taken)
	player.health_component.death.connect(_on_player_death)
	$DeathScreen.hide()
	damage_overlay.modulate = Color.TRANSPARENT
	
	# Setting up stamina bar
	if use_stamina_component:
		stamina_bar.max_value = player.stamina_component.max_stamina
		stamina_bar.value = player.stamina_component.current_stamina
		stamina_bar_label.text = str(stamina_bar.value, "/", stamina_bar.max_value)
		player.stamina_component.stamina_changed.connect(_on_player_stamina_changed)
	
	# Setting up sanity bar
	if use_sanity_component:
		sanity_bar.max_value = player.sanity_component.max_sanity
		sanity_bar.value = player.sanity_component.current_sanity
		sanity_bar_label.text = str(sanity_bar.value, "/", sanity_bar.max_value)
		player.sanity_component.sanity_changed.connect(_on_player_sanity_changed)
	else:
		sanity_bar.hide()
	
	# Setting up brightness bar
	if use_brightness_component:
		brightness_bar.max_value = player.brightness_component.max_brightness
		brightness_bar.value = player.brightness_component.current_brightness
		player.brightness_component.brightness_changed.connect(_on_player_brightness_changed)
	else:
		brightness_bar.hide()
	
	# Set up for HUD elements for interactions and wieldables
	interaction_button.hide()
	interaction_text.text = ""
	primary_use_label.text = ""
	primary_use_icon.hide()
	wieldable_icon.set_texture(empty_texture)
	wieldable_text.text = ""
	
	# Set up for HUD elements for hints
	hint_icon.set_texture(empty_texture)
	hint_text.text = ""
	
	# Fill inventory HUD with player inventory
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.hot_bar_inventory.set_inventory_data(player.inventory_data)
	
	
	# Connecting to Signals from Player
	player.player_interaction_component.interaction_prompt.connect(_on_interaction_prompt)
	player.player_interaction_component.set_use_prompt.connect(_on_set_use_prompt)
	player.player_interaction_component.hint_prompt.connect(_on_set_hint_prompt)
	player.toggle_inventory_interface.connect(toggle_inventory_interface)
	player.player_state_loaded.connect(_on_player_state_load)
	player.player_interaction_component.updated_wieldable_data.connect(_on_update_wieldable_data)

	# Grabbing external inventories in scene.
	for node in get_tree().get_nodes_in_group("external_inventory"):
		print("Is in external_inventory group: ", node)
		node.toggle_inventory.connect(toggle_inventory_interface)


func _on_player_state_load():
	inventory_interface.set_player_inventory_data(player.inventory_data)
	inventory_interface.hot_bar_inventory.set_inventory_data(player.inventory_data)
	
	# Grabbing external inventories in scene.
	for node in get_tree().get_nodes_in_group("external_inventory"):
		print("Is in external_inventory group: ", node)
		if !node.is_connected("toggle_inventory",toggle_inventory_interface):
			node.toggle_inventory.connect(toggle_inventory_interface)



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
		player._on_pause_movement()
		inventory_interface.open_inventory()
		if external_inventory_owner:
			external_inventory_owner.interaction_text = "Close"
	else:
		inventory_interface.close_inventory()
		player._on_resume_movement()
		if external_inventory_owner:
			external_inventory_owner.interaction_text = "Open"
		
	if external_inventory_owner and inventory_interface.is_inventory_open:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()


# When HUD receives interaction prompt signal (usually if player interaction raycast hits an object on layer 2)
func _on_interaction_prompt(passed_interaction_prompt):
	if(passed_interaction_prompt == ""):
		interaction_button.hide()
#		interaction_button.set_texture(empty_texture)
	else:
#		interaction_button.set_texture(interaction_texture)
		interaction_button.show()
	interaction_text.text = passed_interaction_prompt


# When HUD receives set use prompt signal (usually when equipping a wieldable)
func _on_set_use_prompt(passed_use_text):
	primary_use_label.text = passed_use_text
	if passed_use_text != "":
		primary_use_icon.show()
	else:
		primary_use_icon.hide()


# Updating HUD wieldable data, used for stuff like flashlight battery charge, ammo display, etc
func _on_update_wieldable_data(passed_wieldable_icon, passed_wieldable_text):
	wieldable_text.text = passed_wieldable_text
	if passed_wieldable_icon != null:
		wieldable_icon.set_texture(passed_wieldable_icon)
	else:
		wieldable_icon.set_texture(empty_texture)


# When the HUD receives hint prompt signal
func _on_set_hint_prompt(passed_hint_icon, passed_hint_text):
	hint_text.text = passed_hint_text
	if passed_hint_icon != null:
		hint_icon.set_texture(passed_hint_icon)
	else:
		hint_icon.set_texture(default_hint_icon)
		
	# Starts the timer that sets how long the hint is going to be displayed.
	hint_timer.start()
	

# Resetting the hint display when hint timer runs out.
func _on_hint_timer_timeout():
	hint_text.text = ""
	hint_icon.set_texture(empty_texture)


# Updating player health bar
func _on_player_health_changed(new_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = new_health
	health_bar_label.text = str(int(health_bar.value), "/", int(health_bar.max_value))
	

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


func _on_restart_button_pressed():
	get_tree().reload_current_scene()


# Updating player stamina bar
func _on_player_stamina_changed(new_stamina, max_stamina):
	stamina_bar.max_value = max_stamina
	stamina_bar.value = new_stamina
	stamina_bar_label.text = str(int(stamina_bar.value), "/", int(stamina_bar.max_value))


# Updating player sanity bar
func _on_player_sanity_changed(new_sanity, max_sanity):
	sanity_bar.value = new_sanity
	sanity_bar.max_value = max_sanity
	sanity_bar_label.text = str(int(sanity_bar.value), "/", int(sanity_bar.max_value))
	
	
# Updating player brightness bar
func _on_player_brightness_changed(new_brightness, max_brightness):
	brightness_bar.value = new_brightness
	brightness_bar.max_value = max_brightness


# On Inventory UI Item Drop
func _on_inventory_interface_drop_slot_data(slot_data):
	var scene_to_drop = load(slot_data.inventory_item.drop_scene)
	Audio.play_sound(slot_data.inventory_item.sound_drop)
	var dropped_item = scene_to_drop.instantiate()
	dropped_item.position = player.player_interaction_component.get_interaction_raycast_tip(0)
	dropped_item.slot_data = slot_data
	get_parent().add_child(dropped_item)
