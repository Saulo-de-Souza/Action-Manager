@tool
@icon("./icons/axis.svg")


class_name ActionManagerAxis extends Resource


## Enables or disables the execution of axis.
@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## This is the name you will give to the axis and which you will call via the get_axis(axis_name: StringName) function.[br]
## Example: [code]var dir: float = $action_manager.get_axis("Move")[/code]
@export_placeholder("Action name") var axis_name: String:
	set(value):
		axis_name = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## It is the x-axis of the negative quadrant of the 2D coordinate system. For example, the action [code]"ui_left"[/code].
@export var negative_x: StringName:
	set(value):
		negative_x = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## It is the x-axis of the positive quadrant of the 2D coordinate system. For example, the action [code]"ui_right"[/code].
@export var positive_x: StringName:
	set(value):
		positive_x = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()


var owner: ActionManager


func _init_owner(p_owner: ActionManager) -> void:
	owner = p_owner


func _inject_axis(value: float) -> void:
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
