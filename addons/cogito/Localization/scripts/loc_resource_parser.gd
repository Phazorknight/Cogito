@tool
extends EditorTranslationParserPlugin

func _parse_file(path: String) -> Array[PackedStringArray]: 
	var res: Resource = load(path)	
	var ret: Array[PackedStringArray] = []

	if not res:
		print("Parsing file: ", path, ": File is not res.")
		return ret

	if res is ContainerItemContent:
		print("Parsing file: ", path, ": File is ContainerItemContent.")
		var container_item_content = res

		var msgtxt = ""
		var msgid_plural = ""
		
		ret.append(PackedStringArray([container_item_content.content_name, msgtxt, msgid_plural, "container_item_content name"]))


#	Processing Inventory Items for Localization
	if res is InventoryItemPD:
		print("Parsing file: ", path, ": File is InventoryItem.")
		var inventory_item = res

		var msgtxt = ""
		var msgid_plural = ""
		
		ret.append(PackedStringArray([inventory_item.name, msgtxt, msgid_plural, "item name"]))
		ret.append(PackedStringArray([inventory_item.description, msgtxt, msgid_plural, "item description"]))
		ret.append(PackedStringArray([inventory_item.hint_text_on_use, msgtxt, msgid_plural, "item hint on use"]))
		
		if inventory_item is WieldableItemPD:
			ret.append(PackedStringArray([inventory_item.hint_on_empty, msgtxt, msgid_plural, "item hint on empty"]))
			ret.append(PackedStringArray([inventory_item.ammo_item_name, msgtxt, msgid_plural, "item ammo item name"]))

#	Processing Quest Resources for Localization
	if res is CogitoQuest:
		print("Parsing file: ", path, ": File is CogitoQuest.")
		var quest = res
		
		var msgtxt = ""
		var msgid_plural = ""
		
		ret.append(PackedStringArray([quest.quest_title, msgtxt, msgid_plural, "quest title"]))
		ret.append(PackedStringArray([quest.quest_description_active, msgtxt, msgid_plural, "quest description active"]))
		ret.append(PackedStringArray([quest.quest_description_completed, msgtxt, msgid_plural, "quest description completed"]))
		ret.append(PackedStringArray([quest.quest_description_failed, msgtxt, msgid_plural, "quest description failed"]))


#	Processing Translation Key Dictionaries for Localization
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
