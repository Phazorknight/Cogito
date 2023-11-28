extends PanelContainer

signal hot_bar_use(index: int)

const Slot = preload("res://COGITO/InventoryPD/UiScenes/Slot.tscn")
var device_id : int = -1

@onready var h_box_container = $MarginContainer/VBoxContainer/TopRow

@export_group("Input Icons")
@export_subgroup("Input Icons Keyboard")
@export var keyboard_hotkey_1 : Texture2D
@export var keyboard_hotkey_2 : Texture2D
@export var keyboard_hotkey_3 : Texture2D
@export var keyboard_hotkey_4 : Texture2D
@export_subgroup("Input Icons Gamepad")
@export var gamepad_hotkey_1 : Texture2D
@export var gamepad_hotkey_2 : Texture2D
@export var gamepad_hotkey_3 : Texture2D
@export var gamepad_hotkey_4 : Texture2D

func _ready():
	# Call this function once to set icons:
	_joy_connection_changed(device_id,false)
	# Connect to signal that detecs change of input device/gamepad
	Input.joy_connection_changed.connect(_joy_connection_changed)


func _joy_connection_changed(passed_device_id : int, connected : bool):
	if connected:
		device_id = passed_device_id
	elif _is_steam_deck():
		device_id = 1
	else:
		device_id = -1
		
	if device_id == -1:
		set_input_icons_to_kbm()
	else:
		set_input_icons_to_gamepad()


func _is_steam_deck() -> bool:
	if RenderingServer.get_rendering_device().get_device_name().contains("RADV VANGOGH") \
	or OS.get_processor_name().contains("AMD CUSTOM APU 0405"):
		return true
	else:
		return false

func set_input_icons_to_kbm():
	$MarginContainer/VBoxContainer/BottomRow/Button1.set_texture(keyboard_hotkey_1)
	$MarginContainer/VBoxContainer/BottomRow/Button2.set_texture(keyboard_hotkey_2)
	$MarginContainer/VBoxContainer/BottomRow/Button3.set_texture(keyboard_hotkey_3)
	$MarginContainer/VBoxContainer/BottomRow/Button4.set_texture(keyboard_hotkey_4)
	
func set_input_icons_to_gamepad():
	$MarginContainer/VBoxContainer/BottomRow/Button1.set_texture(gamepad_hotkey_1)
	$MarginContainer/VBoxContainer/BottomRow/Button2.set_texture(gamepad_hotkey_2)
	$MarginContainer/VBoxContainer/BottomRow/Button3.set_texture(gamepad_hotkey_3)
	$MarginContainer/VBoxContainer/BottomRow/Button4.set_texture(gamepad_hotkey_4)



func _input(event):
	# Handles Gamepad Hotbar input
	if not visible:
		return
		
	if event.is_action_released("dpad_left"):
		hot_bar_use.emit(0)
	
	if event.is_action_released("dpad_up"):
		hot_bar_use.emit(1)
		
	if event.is_action_released("dpad_down"):
		hot_bar_use.emit(2)
	
	if event.is_action_released("dpad_right"):
		hot_bar_use.emit(3)


func _unhandled_key_input(event):
	if not visible or not event.is_pressed():
		return
		
	# Last one is exclusive in this condition
	if range(KEY_1, KEY_5).has(event.keycode):
		hot_bar_use.emit(event.keycode - KEY_1)


func set_inventory_data(inventory_data : InventoryPD) -> void:
	inventory_data.inventory_updated.connect(populate_hotbar)
	populate_hotbar(inventory_data)
	hot_bar_use.connect(inventory_data.use_slot_data)

func populate_hotbar(inventory_data : InventoryPD) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
		
	for slot_data in inventory_data.inventory_slots.slice(0,4):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)
		
		if slot_data:
			slot.set_slot_data(slot_data)
