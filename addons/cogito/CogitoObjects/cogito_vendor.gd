extends Node3D

##How much stock the vendor starts with

@export var starting_amount : int = 3
@export var object_to_spawn : PackedScene
@export var spawn_delay : float = 1.5
@export var spawn_rotation : Vector3 = Vector3.ZERO
@export var purchased_hint_text : String = "Purchased a Health Potion"
@export var have_stock_text : String = "In Stock"
@export var stock_empty_text : String = "Sold Out"
@export_group("Sound Settings")
@export var dispensing_sound : AudioStream

@onready var cogito_button = $GenericButton
@onready var currency_check : CurrencyCheck = $GenericButton/CurrencyCheck
@onready var spawn_point : Marker3D = $Spawnpoint
@onready var stock_label = $StaticBody3D/StockLabel
@onready var stock_counter : Label3D = $StaticBody3D/StockCounter

var player_interaction_component : PlayerInteractionComponent
var currency_attribute : CogitoCurrency

var amount_remaining : int
var is_dispensing : bool


func _ready():
	add_to_group("save_object_state")
	amount_remaining = starting_amount
	_update_vendor_state()
	cogito_button.allows_repeated_interaction = amount_remaining > 1
	# spawn delay must be shorter than the press cooldown or spawn count could be affected
	if spawn_delay >= cogito_button.press_cooldown_time:
		spawn_delay = cogito_button.press_cooldown_time - 0.1
		printerr("spawn_delay exceeded button press cooldown time. It has been set to " + str(spawn_delay))
	currency_check.connect("transaction_success", Callable(self, "_on_transaction_success"))
	var player_node = CogitoSceneManager._current_player_node
	player_interaction_component = (player_node as CogitoPlayer).player_interaction_component
	for attribute in player_node.find_children("", "CogitoCurrency", false):
		if attribute is CogitoCurrency and attribute.currency_name == currency_check.currency_name:
			currency_attribute = attribute
			break


func _on_transaction_success() -> void:
	# communicate the event
	player_interaction_component.send_hint(currency_attribute.currency_icon, purchased_hint_text)
	
	# update vendor
	amount_remaining -= 1
	_update_vendor_state()
	
	# dispense object
	is_dispensing = true
	_delayed_object_spawn()


func _delayed_object_spawn() -> void:
	if dispensing_sound:
		Audio.play_sound_3d(dispensing_sound).global_position = spawn_point.global_position
	
	await get_tree().create_timer(spawn_delay).timeout
	is_dispensing = false
	
	var spawned_object = object_to_spawn.instantiate()
	spawned_object.position = spawn_point.global_position
	spawned_object.rotation = spawn_rotation
	get_tree().current_scene.add_child(spawned_object)


func _update_vendor_state() -> void:
	# when only 1 is left have the button handle it's own behavior
	if amount_remaining == 0:
		cogito_button.allows_repeated_interaction = false
		stock_label.text = stock_empty_text
	elif stock_label.text != have_stock_text:
		stock_label.text = have_stock_text
	
	stock_counter.text = str(amount_remaining)


func set_state():
	starting_amount = amount_remaining
	_update_vendor_state()
	
	if is_dispensing:
		_delayed_object_spawn()


func save():
	var state_dict = {
		"node_path" : self.get_path(),
		"amount_remaining" : amount_remaining,
		"is_dispensing" : is_dispensing,
		"pos_x" : position.x,
		"pos_y" : position.y,
		"pos_z" : position.z,
		"rot_x" : rotation.x,
		"rot_y" : rotation.y,
		"rot_z" : rotation.z,
		
	}
	return state_dict
