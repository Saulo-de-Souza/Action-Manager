@tool
@icon("./icons/axis.svg")


class_name ActionManagerAxis extends Resource

@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

@export_placeholder("Action name") var axis_name: String:
	set(value):
		axis_name = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

@export var negative_x: StringName:
	set(value):
		negative_x = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

@export var positive_x: StringName:
	set(value):
		positive_x = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()


var owner: ActionManager


func _init_owner(p_owner: ActionManager) -> void:
	owner = p_owner


func inject_axis(value: float) -> void:
	if not enabled:
		Input.action_release(negative_x)
		Input.action_release(positive_x)
		return

	Input.action_release(negative_x)
	Input.action_release(positive_x)

	if value < 0.0:
		Input.action_press(negative_x, abs(value))
		Input.action_release(positive_x)

	elif value > 0.0:
		Input.action_press(positive_x, abs(value))
		Input.action_release(negative_x)

	else:
		Input.action_release(negative_x)
		Input.action_release(positive_x)
