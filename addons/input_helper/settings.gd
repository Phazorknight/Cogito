class_name InputHelperSettings extends Node

const USE_GRANULAR_DEVICE_IDENTIFIERS = "devices/use_granular_device_identifiers"

const SETTINGS_CONFIGURATION = {
	USE_GRANULAR_DEVICE_IDENTIFIERS: {
		value = false,
		type = TYPE_BOOL,
		is_advanced = true
	},
}


static func prepare() -> void:
	for key: String in SETTINGS_CONFIGURATION:
		var setting_config: Dictionary = SETTINGS_CONFIGURATION[key]
		var setting_name: String = "input_helper/%s" % key
		if not ProjectSettings.has_setting(setting_name):
			ProjectSettings.set_setting(setting_name, setting_config.value)
		ProjectSettings.set_initial_value(setting_name, setting_config.value)
		ProjectSettings.add_property_info({
			"name" = setting_name,
			"type" = setting_config.type,
			"hint" = setting_config.get("hint", PROPERTY_HINT_NONE),
			"hint_string" = setting_config.get("hint_string", "")
		})
		ProjectSettings.set_as_basic(setting_name, not setting_config.has("is_advanced"))
		ProjectSettings.set_as_internal(setting_name, setting_config.has("is_hidden"))


static func set_setting(key: String, value) -> void:
	if get_setting(key, value) != value:
		ProjectSettings.set_setting("input_helper/%s" % key, value)
		ProjectSettings.set_initial_value("input_helper/%s" % key, SETTINGS_CONFIGURATION[key].value)
		ProjectSettings.save()


static func get_setting(key: String, default):
	if ProjectSettings.has_setting("input_helper/%s" % key):
		return ProjectSettings.get_setting("input_helper/%s" % key)
	else:
		return default
