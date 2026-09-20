@tool
extends Control


func _enter_tree() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = Engine.is_editor_hint()
