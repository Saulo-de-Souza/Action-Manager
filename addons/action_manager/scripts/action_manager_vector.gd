@tool
@icon("./icons/vector.svg")


class_name ActionManagerVector extends Resource


## Enables or disables the execution of vectors.
@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## This is the name you will give to the vector and which you will call via the get_vector(vector_name: StringName) function.[br]
## Example: [code]var dir: Vector3 = $action_manager.get_vector("Move")[/code]
@export_placeholder("Action name") var vector_name: String:
	set(value):
		vector_name = value
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

## It is the y-axis of the negative quadrant of the 2D coordinate system. For example, the action [code]"ui_up"[/code].
@export var negative_y: StringName:
	set(value):
		negative_y = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## It is the y-axis of the positive quadrant of the 2D coordinate system. For example, the action [code]"ui_down"[/code].
@export var positive_y: StringName:
	set(value):
		positive_y = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## When you activate this plugin, it makes available a new node called [b]ActionManagerJoystick[/b], which can be used to create an on-screen joystick for new devices.[br]
## Search for the [b]ActionManagerJoystick[/b] node and associate it here.
@export var action_manager_joystick_path: NodePath:
	set(value):
		action_manager_joystick_path = value
		if is_instance_valid(owner):
			if action_manager_joystick_path and owner.get_node(action_manager_joystick_path) and not owner.get_node(action_manager_joystick_path) is ActionManagerJoystick:
				action_manager_joystick_path = ""
				push_warning("The action_manager_joystick_path property only accepts the path of a ActionManagerJoystick node.")
			owner.update_configuration_warnings()


var owner: ActionManager
var _trigger_joystick: bool = false


func _inject_vector(value: Vector2) -> void:
	if not enabled:
		Input.action_release(negative_x)
		Input.action_release(positive_x)
		Input.action_release(negative_y)
		Input.action_release(positive_y)
		return

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


func _set_virtual_vector(value: Vector2) -> void:
	if not enabled:
		if not _trigger_joystick:
			_inject_vector(Vector2.ZERO)
			_trigger_joystick = true
		return
		
	if value.length() > 0.0:
		_inject_vector(value)
		_trigger_joystick = false
	else:
		if not _trigger_joystick:
			_inject_vector(Vector2.ZERO)
			_trigger_joystick = true


func _init_owner(p_owner: ActionManager) -> void:
	owner = p_owner
