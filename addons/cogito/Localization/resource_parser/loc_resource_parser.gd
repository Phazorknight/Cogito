@tool
extends EditorTranslationParserPlugin

func _parse_file(path: String) -> Array[PackedStringArray]: 
	var res: Resource = load(path)	
	var ret: Array[PackedStringArray] = []

	if not res:
		print("Parsing file: ", path, ": File is not res.")
		return ret

	if res is InventoryItemPD:
		print("Parsing file: ", path, ": File is InventoryItem.")
		var inventory_item: InventoryItemPD = res as InventoryItemPD
		
		var parsed_translation_entries : Array[PackedStringArray] = []

		var msgtxt = ""
		var msgid_plural = ""
		
		ret.append(PackedStringArray([inventory_item.name, msgtxt, msgid_plural, "item name"]))
		ret.append(PackedStringArray([inventory_item.description, msgtxt, msgid_plural, "item description"]))
		ret.append(PackedStringArray([inventory_item.hint_text_on_use, msgtxt, msgid_plural, "item hint on use"]))
		
	
	return ret
		
func _get_recognized_extensions() -> PackedStringArray:
	return ["tres"]


#func parse_item_translation_entries(inventory_item: InventoryItemPD) -> Array[PackedStringArray]:
	#var parsed_translation_entries : Array[PackedStringArray] = []
#
	#var msgtxt = ""
	#var msgid_plural = ""
	#
	#parsed_translation_entries.append(PackedStringArray([inventory_item.name, msgtxt, msgid_plural]))
	#parsed_translation_entries.append(PackedStringArray([inventory_item.description, msgtxt, msgid_plural]))
	#parsed_translation_entries.append(PackedStringArray([inventory_item.hint_text_on_use, msgtxt, msgid_plural]))
	#
	#return parsed_translation_entries
