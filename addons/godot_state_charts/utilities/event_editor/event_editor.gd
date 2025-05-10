@tool
extends EditorProperty

const StateChartUtil = preload("../state_chart_util.gd")
var _refactor_window_scene:PackedScene = preload("../event_refactor/event_refactor.tscn")


# The main control for editing the property.
var _property_control:LineEdit = LineEdit.new()
# drop down button for the popup menu
var _dropdown_button:Button = Button.new()
# popup menu with event names
var _popup_menu:PopupMenu = PopupMenu.new()

# the state chart we are currently editing
var _chart:StateChart
# the undo redo manager
var _undo_redo:EditorUndoRedoManager


func _init(transition:Transition, undo_redo:EditorUndoRedoManager):
	
	# save the variables
	_chart = StateChartUtil.find_parent_state_chart(transition)
	_undo_redo = undo_redo
		
	# setup the ui
	_popup_menu.index_pressed.connect(_on_event_selected)
	
	_dropdown_button.icon = get_theme_icon("arrow", "OptionButton")
	_dropdown_button.flat = true
	_dropdown_button.pressed.connect(_show_popup)
	
	# build the actual editor
	var hbox := HBoxContainer.new()
	hbox.add_child(_property_control)
	hbox.add_child(_dropdown_button)
	_property_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add the control as a direct child of EditorProperty node.
	add_child(hbox)
	add_child(_popup_menu)
	
	# Make sure the control is able to retain the focus.
	add_focusable(_property_control)
	_property_control.text_changed.connect(_on_text_changed)

## Shows the popup when the user clicks the button.
func _show_popup():
	# always show up-to-date information in selector
	var known_events = StateChartUtil.events_of(_chart)
	
	_popup_menu.clear()
	_popup_menu.add_item("<empty>")
	_popup_menu.add_icon_item(get_theme_icon("Tools", "EditorIcons"), "Manage...")
	
	if known_events.size() > 0:
		_popup_menu.add_separator()
	
	for event in known_events:
		_popup_menu.add_item(event)
	
	# and show it relative to the dropdown button
	var gt := _dropdown_button.get_global_rect()
	_popup_menu.reset_size()
	var ms := _popup_menu.get_contents_minimum_size().x
	var popup_pos := gt.end - Vector2(ms, 0) + Vector2(DisplayServer.window_get_position())
	_popup_menu.set_position(popup_pos)
	_popup_menu.popup()


func _on_event_selected(index:int) -> void:
	# index 1 == "Manage"
	if index == 1:
		# open refactor window
		var window = _refactor_window_scene.instantiate()
		add_child(window)
		window.open(_chart, _undo_redo)
		return
	
	# replace content with selection from popup
	var event := _popup_menu.get_item_text(index) if index > 0 else ""
	_property_control.text = event
	_on_text_changed(event)
	_property_control.grab_focus()


func _on_text_changed(new_text:String):
	emit_changed(get_edited_property(), new_text)


func _update_property() -> void:
	# Read the current value from the property.
	var new_value = get_edited_object()[get_edited_property()]
	
	# if the text is already correct, don't change it.	
	if new_value == _property_control.text:
		return

	_property_control.text = new_value
