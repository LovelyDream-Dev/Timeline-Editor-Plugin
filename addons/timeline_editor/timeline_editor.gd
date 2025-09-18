@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_autoload_singleton("NoteData", "res://addons/timeline_editor/Singletons/note_data.gd")
	call_deferred("_init_note_data")
	pass

func _init_note_data():
	var root = get_tree().root
	var note_data = root.find_child("NoteData", false, false)
	if note_data:
		note_data.initialize()

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_autoload_singleton("NoteData")
