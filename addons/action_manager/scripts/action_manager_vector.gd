@tool
@icon("./icons/vector.svg")


class_name ActionManagerVector extends Resource


@export_placeholder("Action name") var vector_name: String:
	set(value):
		vector_name = value
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

@export var negative_y: StringName:
	set(value):
		negative_y = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

@export var positive_y: StringName:
	set(value):
		positive_y = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

@export var action_manager_joystick_path: NodePath:
	set(value):
		action_manager_joystick_path = value
		if is_instance_valid(owner):
			if action_manager_joystick_path and owner.get_node(action_manager_joystick_path) and not owner.get_node(action_manager_joystick_path) is ActionManagerJoystick:
				action_manager_joystick_path = ""
				push_warning("The action_manager_joystick_path property only accepts the path of a ActionManagerJoystick node.")
			owner.update_configuration_warnings()


var owner: ActionManager
var _default_deadzone: float = 0.0
var _trigger_joystick: bool = false


func inject_vector(value: Vector2) -> void:
	Input.action_release(negative_x)
	Input.action_release(positive_x)
	Input.action_release(negative_y)
	Input.action_release(positive_y)

	# X AXIS
	if value.x < 0.0:
		Input.action_press(negative_x, abs(value.x))
		Input.action_release(positive_x)
	elif value.x > 0.0:
		Input.action_press(positive_x, abs(value.x))
		Input.action_release(negative_x)
	else:
		Input.action_release(negative_x)
		Input.action_release(positive_x)

	# Y AXIS
	if value.y < 0.0:
		Input.action_press(negative_y, abs(value.y))
		Input.action_release(positive_y)
	elif value.y > 0.0:
		Input.action_press(positive_y, abs(value.y))
		Input.action_release(negative_y)
	else:
		Input.action_release(negative_y)
		Input.action_release(positive_y)


func set_virtual_vector(value: Vector2) -> void:
	if value.length() > 0.0:
		inject_vector(value)
		_trigger_joystick = false
	else:
		if not _trigger_joystick:
			inject_vector(Vector2.ZERO)
			_trigger_joystick = true


func _init_owner(p_owner: ActionManager) -> void:
	owner = p_owner
