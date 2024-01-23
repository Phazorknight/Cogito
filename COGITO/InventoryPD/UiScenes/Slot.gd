extends PanelContainer

@onready var texture_rect = $MarginContainer/TextureRect
@onready var quantity_label = $QuantityLabel
@onready var charge_label = $ChargeLabel
@onready var selection_panel = $Selected

@export var highlight_color : Color
## AudioStream that plays when slot gets highlighted.
@export var sound_highlight : AudioStream
var item_data = null


signal slot_clicked(index: int, mouse_button: int)
signal slot_pressed(index: int, action: String)

func set_slot_data(slot_data: InventorySlotPD):
	item_data = slot_data.inventory_item
	texture_rect.texture = item_data.icon
	
	if slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		quantity_label.hide()
		
	# Check if item is a WIELDABLE
	if item_data.item_type == 1:
		charge_label.text = str(int(item_data.charge_current))
		if !item_data.charge_changed.is_connected(_on_charge_changed):
			item_data.charge_changed.connect(_on_charge_changed)
		charge_label.show()
	else:
		charge_label.hide()


func _on_charge_changed():
	charge_label.text = str(int(item_data.charge_current))
 

func _on_gui_input(event):
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT \
			or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)
	
	# Setting SLOT GAMPEAD INTERACTIONS HERE
	if event.is_action_pressed("inventory_move_item"):
		slot_pressed.emit(get_index(), "inventory_move_item")
	if event.is_action_pressed("inventory_use_item"):
		slot_pressed.emit(get_index(), "inventory_use_item")
	if event.is_action_pressed("inventory_drop_item"):
		slot_pressed.emit(get_index(), "inventory_drop_item")


func set_selection(is_selected : bool):
	selection_panel.visible = is_selected
	
func _on_mouse_entered():
	grab_focus()

func _on_mouse_exited():
	release_focus()

func _on_hidden():
	release_focus()

func _on_focus_entered() -> void:
	Audio.play_sound(sound_highlight)
	$Panel.show()
	selection_panel.show()

func _on_focus_exited() -> void:
	selection_panel.hide()
	$Panel.hide()
