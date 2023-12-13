@tool
extends EditorPlugin

func _enter_tree():
  add_autoload_singleton("Audio", "./Audio.gd")

func _exit_tree():
  remove_autoload_singleton("Audio")
