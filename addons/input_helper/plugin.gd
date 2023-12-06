@tool
extends EditorPlugin


const REMOTE_RELEASES_URL = "https://api.github.com/repos/nathanhoad/godot_input_helper/releases"
const LOCAL_CONFIG_PATH = "res://addons/input_helper/plugin.cfg"

const DownloadDialogScene = preload("res://addons/input_helper/views/download_dialog.tscn")


var http_request: HTTPRequest = HTTPRequest.new()
var next_version: String = ""


func _enter_tree():
	add_autoload_singleton("InputHelper", "res://addons/input_helper/input_helper.gd")

	# Check for updates on GitHub
	get_editor_interface().get_base_control().add_child(http_request)
	http_request.request_completed.connect(_on_http_request_request_completed)
	http_request.request(REMOTE_RELEASES_URL)


func _exit_tree():
	remove_autoload_singleton("InputHelper")

	if next_version != "":
		remove_tool_menu_item("Update Input Helper to v%s" % next_version)


# Get the current version
func get_version() -> String:
	var config: ConfigFile = ConfigFile.new()
	config.load(LOCAL_CONFIG_PATH)
	return config.get_value("plugin", "version")


# Convert a version number to an actually comparable number
func version_to_number(version: String) -> int:
	var bits = version.split(".")
	return bits[0].to_int() * 1000000 + bits[1].to_int() * 1000 + bits[2].to_int()


### Signals


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	http_request.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS: return

	var current_version: String = get_version()

	# Work out the next version from the releases information on GitHub
	var response = JSON.parse_string(body.get_string_from_utf8())
	if typeof(response) != TYPE_ARRAY: return

	# GitHub releases are in order of creation, not order of version
	var versions = (response as Array).filter(func(release):
		var version: String = release.tag_name.substr(1)
		return version_to_number(version) > version_to_number(current_version)
	)
	if versions.size() > 0:
		next_version = versions[0].tag_name.substr(1)
		add_tool_menu_item("Update Input Helper to v%s" % next_version, _update_input_helper)


func _update_input_helper() -> void:
	var download_dialog := DownloadDialogScene.instantiate()
	download_dialog.next_version = next_version

	var scale: float = get_editor_interface().get_editor_scale()
	download_dialog.min_size = Vector2(300, 250) * scale

	download_dialog.update_finished.connect(_on_download_dialog_update_finished)
	download_dialog.update_failed.connect(_on_download_dialog_update_failed)

	get_editor_interface().get_base_control().add_child(download_dialog)
	download_dialog.show()


func _on_download_dialog_update_finished() -> void:
	remove_tool_menu_item("Update Input Helper to v%s" % next_version)

	get_editor_interface().get_resource_filesystem().scan()

	print_rich("\n[b]Updated Input Helper to v%s[/b]\n" % next_version)

	var finished_dialog: AcceptDialog = AcceptDialog.new()
	finished_dialog.dialog_text = "Your Input Helper is now up to date."

	var restart_addon = func():
		finished_dialog.queue_free()
		get_editor_interface().call_deferred("set_plugin_enabled", "input_helper", true)
		get_editor_interface().set_plugin_enabled("input_helper", false)

	finished_dialog.canceled.connect(restart_addon)
	finished_dialog.confirmed.connect(restart_addon)
	get_editor_interface().get_base_control().add_child(finished_dialog)
	finished_dialog.popup_centered()


func _on_download_dialog_update_failed() -> void:
	var failed_dialog: AcceptDialog = AcceptDialog.new()
	failed_dialog.dialog_text = "There was a problem downloading the update."
	failed_dialog.canceled.connect(func(): failed_dialog.queue_free())
	failed_dialog.confirmed.connect(func(): failed_dialog.queue_free())
	get_editor_interface().get_base_control().add_child(failed_dialog)
	failed_dialog.popup_centered()
