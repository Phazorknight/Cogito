extends OptionButton
 
# Define available languages and their properties
var languages: Array[Dictionary] = [
	{"code": "en", "icon": preload("res://addons/cogito/Assets/Graphics/Flags/freepik_flag_us.png"), "text": "  English"},
	{"code": "de", "icon": preload("res://addons/cogito/Assets/Graphics/Flags/freepik_flag_de.png"), "text": "  Deutsch"},
]
 
var current_language_index: int = 0
 
 
func _ready() -> void:
	# Populate the OptionButton with languages
	add_language_items(languages)
 
	# Load the saved language or fallback to detecting the OS language
	var saved_language: String = load_language()
	if saved_language:
		set_language_by_code(saved_language)
	else:
		detect_and_set_language(languages)
 
	# Connect the item_selected signal to handle language changes
	item_selected.connect(_on_language_selected)
 
 
# Function to populate the OptionButton with language items
func add_language_items(languages: Array[Dictionary]) -> void:
	clear()  # Clear any existing items in the OptionButton
	for i: int in range(languages.size()):
		var language: Dictionary = languages[i]
		var text: String = language.get("text", "")
		var icon: Variant = language.get("icon", null)
 
		# Add items with or without icons
		if icon and icon is Texture2D:
			add_icon_item(icon as Texture2D, text, i)
		else:
			add_item(text, i)
 
 
# Function to detect and set the default language
func detect_and_set_language(languages: Array[Dictionary]) -> void:
	var os_language: String = OS.get_locale().split("_")[0].to_lower()
	set_language_by_code(os_language)
 
 
# Function to set language by its code
func set_language_by_code(code: String) -> void:
	for i: int in range(languages.size()):
		if languages[i]["code"] == code:
			current_language_index = i
			select(i)
			apply_language(languages[i])
			return
 
	# Fallback to the first language if no match is found
	current_language_index = 0
	select(0)
	apply_language(languages[0])
 
 
# Function to apply the selected language
func apply_language(language: Dictionary) -> void:
	var language_code: String = language["code"]
	if TranslationServer.get_locale() == language_code:
		return
	TranslationServer.set_locale(language_code)
	save_language(language_code)
	print("Language changed to:", language["text"], "(", language_code, ") and saved to user://language.cfg")
 
 
# Signal handler for when a language is selected from the dropdown
func _on_language_selected(index: int) -> void:
	current_language_index = index
	var selected_language: Dictionary = languages[index]
	apply_language(selected_language)
 
 
# Function to save the selected language
func save_language(code: String) -> void:
	var file: FileAccess = FileAccess.open("user://language.cfg", FileAccess.WRITE)
	file.store_line(code)
	file.close()
 
 
# Function to load the saved language
func load_language() -> String:
	if FileAccess.file_exists("user://language.cfg"):
		var file: FileAccess = FileAccess.open("user://language.cfg", FileAccess.READ)
		var code: String = file.get_line().strip_edges()  # Remove any extra whitespace or newlines
		file.close()
		return code
	return ""  # Return an empty string if no saved language exists
