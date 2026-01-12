@tool
extends EditorPlugin


var icon = preload("res://addons/action_manager/icon.svg")
var main_script = preload("res://addons/action_manager/action_manager.gd")
var resource_script = preload("res://addons/action_manager/action_manager_data.gd")


func _enable_plugin() -> void:
	add_custom_type("ActionManager", "Node", main_script, icon)
	add_custom_type("ActionManagerData", "Node", resource_script, icon)


func _disable_plugin() -> void:
	remove_custom_type("ActionManager")
	remove_custom_type("ActionManagerData")
