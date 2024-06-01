class_name CogitoTabMenu
extends TabContainer
## This class can be extended to create a tab menu with controller support.

## Helper for controller input. Sets the node  to focus on for each tab.
## The array index corresponds to the tabs.
@export var nodes_to_focus: Array[Control]

func _input(event):
	if !visible:
		return
	
	#Tab navigation
	if (event.is_action_pressed("ui_next_tab")):
		if current_tab + 1 == get_tab_count():
			current_tab = 0
		else:
			current_tab += 1
			
		if nodes_to_focus[current_tab]:
			#print("Grabbing focus of : ", tab_container.current_tab, " - ", nodes_to_focus[tab_container.current_tab])
			nodes_to_focus[current_tab].grab_focus.call_deferred()
		
	if (event.is_action_pressed("ui_prev_tab")):
		if current_tab  == 0:
			current_tab = get_tab_count()-1
		else:
			current_tab -= 1
			
		if nodes_to_focus[current_tab]:
			#print("Grabbing focus of : ", tab_container.current_tab, " - ", nodes_to_focus[tab_container.current_tab])
			nodes_to_focus[current_tab].grab_focus.call_deferred()
