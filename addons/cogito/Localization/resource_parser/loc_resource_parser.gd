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

		var msgtxt = ""
		var msgid_plural = ""
		
		ret.append(PackedStringArray([inventory_item.name, msgtxt, msgid_plural, "item name"]))
		ret.append(PackedStringArray([inventory_item.description, msgtxt, msgid_plural, "item description"]))
		ret.append(PackedStringArray([inventory_item.hint_text_on_use, msgtxt, msgid_plural, "item hint on use"]))
		
	if res is TranslationKeyDict:
		print("Parsing file: ", path, ": File is TranslationKeyDict.")
		var translation_key_dict: TranslationKeyDict = res as TranslationKeyDict
		
		for key_dict_entry in translation_key_dict.keylist:
			var msgtxt = ""
			var msgid_plural = ""
			
			ret.append(PackedStringArray([key_dict_entry, msgtxt, msgid_plural, "translation_key_dict entry"]))
	
	return ret
	

func _get_recognized_extensions() -> PackedStringArray:
	return ["tres"]
