@tool

extends AcceptDialog


signal update_finished()
signal update_failed()


@onready var download_update_panel := $DownloadUpdatePanel


var next_version: String


func _ready() -> void:
	download_update_panel.next_version = next_version


### Signals


func _on_download_update_panel_updated(updated_to_version) -> void:
	update_finished.emit()
	queue_free()


func _on_download_update_panel_failed() -> void:
	update_failed.emit()
	queue_free()
