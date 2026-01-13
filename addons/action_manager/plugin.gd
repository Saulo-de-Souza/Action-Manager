@tool
extends EditorPlugin


var icon = preload("res://addons/action_manager/icon.svg")
var icon_action = preload("res://addons/action_manager/scripts/icons/action.svg")
var icon_axis = preload("res://addons/action_manager/scripts/icons/axis.svg")
var icon_vector = preload("res://addons/action_manager/scripts/icons/vector.svg")


var main_script = preload("res://addons/action_manager/action_manager.gd")
var resource_script_vector = preload("res://addons/action_manager/scripts/action_manager_vector.gd")
var resource_script_axis = preload("res://addons/action_manager/scripts/action_manager_axis.gd")
var resource_script_action = preload("res://addons/action_manager/scripts/action_manager_action.gd")


func _enable_plugin() -> void:
	add_custom_type("ActionManager", "CanvasLayer", main_script, icon)
	add_custom_type("ActionManagerAction", "Resource", resource_script_action, icon_action)
	add_custom_type("ActionManagerAxis", "Resource", resource_script_axis, icon)
	add_custom_type("ActionManagerVector", "Resource", resource_script_vector, icon)


func _disable_plugin() -> void:
	remove_custom_type("ActionManager")
	remove_custom_type("ActionManagerAction")
	remove_custom_type("ActionManagerAxis")
	remove_custom_type("ActionManagerVector")
