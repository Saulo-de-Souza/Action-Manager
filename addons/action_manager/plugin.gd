@tool
extends EditorPlugin


var icon = preload("res://addons/action_manager/icon.svg")
var main_script = preload("res://addons/action_manager/action_manager.gd")


func _enable_plugin() -> void:
	add_custom_type("ActionManager", "Node", main_script, icon)


func _disable_plugin() -> void:
	remove_custom_type("ActionManager")
