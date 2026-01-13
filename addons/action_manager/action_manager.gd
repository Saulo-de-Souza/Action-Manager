@tool
@icon("./icon.svg")


class_name ActionManager extends CanvasLayer


# ----------------------------------------------------
# EXPORTS
# ----------------------------------------------------
@export_enum("Physics Process", "Process") var input_processing: int = 0:
	set(value):
		input_processing = value
		_update_input_processing()
		update_configuration_warnings()

@export_group("Actions")
@export var actions_data: Array[ActionManagerAction]:
	set(value):
		actions_data = value
		if not is_inside_tree(): await tree_entered
		if not is_node_ready(): await ready
		await get_tree().process_frame
		for action in actions_data:
			if action:
				action._init_owner(self)
		update_configuration_warnings()

@export_group("Axis")
@export var axis_data: Array[ActionManagerAxis]:
	set(value):
		axis_data = value
		if not is_inside_tree(): await tree_entered
		if not is_node_ready(): await ready
		await get_tree().process_frame
		for axis in axis_data:
			if axis:
				axis._init_owner(self)
		update_configuration_warnings()

@export_group("Vectors")
@export var vectors_data: Array[ActionManagerVector]:
	set(value):
		vectors_data = value
		if not is_inside_tree(): await tree_entered
		if not is_node_ready(): await ready
		await get_tree().process_frame
		for vector in vectors_data:
			if vector:
				vector._init_owner(self)
		update_configuration_warnings()


var am_warning_once: ActionManagerWarningOnce = ActionManagerWarningOnce.new()
var _joysticks: Array[ActionManagerJoystick] = []


# ----------------------------------------------------
# ENGINE METHODS
# ----------------------------------------------------
func _ready():
	_handle_editor()
	_update_input_processing()
	_handle_actions()
	_handle_vectors()


func _process(delta: float) -> void:
	_update_actions(delta)
	_update_joysticks()


func _physics_process(delta: float) -> void:
	_update_actions(delta)
	_update_joysticks()
	
	
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if input_processing == 1 and (axis_data.size() > 0 or vectors_data.size() > 0):
		warnings.append("Axis and Vector inputs are recommended to use Physics Process.")
		
	_warings_actions(warnings)
	_warings_axis(warnings)
	_warings_vectors(warnings)

	return warnings


# ----------------------------------------------------
# GET DATA
# ----------------------------------------------------
func get_action_data(action_name: StringName) -> ActionManagerAction:
	for action in actions_data:
		if action:
			if action.action_name == action_name:
				return action
	am_warning_once.push_warning("5", "Action %s not found." % action_name)
	return null


func get_axis_data(axis_name: StringName) -> ActionManagerAxis:
	for axis in axis_data:
		if axis:
			if axis.axis_name == axis_name:
				return axis
	am_warning_once.push_warning("4", "Axis %s not found." % axis_name)
	return null


func get_vector_data(vector_name: StringName) -> ActionManagerVector:
	for vector in vectors_data:
		if vector:
			if vector.vector_name == vector_name:
				return vector
	am_warning_once.push_warning("3", "Vector %s not found." % vector_name)
	return null


# ----------------------------------------------------
# PUBLIC METHODS
# ----------------------------------------------------
func get_action(action_name: StringName) -> bool:
	var action_data: ActionManagerAction = get_action_data(action_name)
	if not action_data:
		return false

	match action_data.action_type:
		ActionManagerAction.action_type_enum.PRESSED:
			return Input.is_action_pressed(action_data.action)

		ActionManagerAction.action_type_enum.JUST_PRESSED:
			return Input.is_action_just_pressed(action_data.action)

		ActionManagerAction.action_type_enum.RELEASED:
			return Input.is_action_just_released(action_data.action)

		ActionManagerAction.action_type_enum.TOGGLE:
			return action_data._toggle_state

		ActionManagerAction.action_type_enum.LONG_PRESS:
			return action_data._event_fired

		ActionManagerAction.action_type_enum.LONG_PRESS_HOLD:
			return action_data._hold_state

		ActionManagerAction.action_type_enum.REPEAT:
			return action_data._event_fired

		ActionManagerAction.action_type_enum.DOUBLE_PRESS:
			return action_data._event_fired

		_:
			return false


func get_action_axis(action_name: StringName) -> float:
	var data: ActionManagerAxis = get_axis_data(action_name)
	if not data:
		return 0.0
	return Input.get_axis(data.negative_x, data.positive_x)


func get_action_vector(action_name: StringName, dead_zone: float = -1.0) -> Vector2:
	var vector: ActionManagerVector = get_vector_data(action_name)
	if not vector:
		return Vector2.ZERO

	return Input.get_vector(
		vector.negative_x,
		vector.positive_x,
		vector.negative_y,
		vector.positive_y,
		dead_zone
	)


# ----------------------------------------------------
# PRIVATE METHODS
# ----------------------------------------------------
func _handle_editor() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		set_process_input(false)


func _handle_actions() -> void:
	for action in actions_data:
		if action:
			if action.touch_screen_button_path:
				var touch = get_node(action.touch_screen_button_path)
				if touch is TouchScreenButton:
					touch.action = ""
					touch.pressed.connect(func():
						action.inject_pressed(action.action)
					)
					touch.released.connect(func():
						action.inject_released(action.action)
					)
				else:
					am_warning_once.push_warning("2", "The touch_screen_button_path property must be of type TouchScreenButton. Consider adding a TouchScreenButton.")


func _handle_vectors() -> void:
	for vector in vectors_data:
		if vector:
			if vector.action_manager_joystick_path:
				var joystick = get_node(vector.action_manager_joystick_path)
				if joystick:
					if joystick is ActionManagerJoystick:
						#joystick.analogic_changed.connect(func(value: Vector2, distance: float, angle: float, angle_clockwise: float, angle_not_clockwise: float):
							#vector.inject_vector(value)
							#)
						joystick.set_meta("am_vector", vector)
						_joysticks.append(joystick)
					else:
						am_warning_once.push_warning("1", "The action_manager_joystick_path property must be of type ActionManagerJoystick. Consider adding a ActionManagerJoystick.")


func _update_actions(delta: float) -> void:
	for action in actions_data:
		if action:
			action.update(delta)


func _update_joysticks() -> void:
	for joystick in _joysticks:
		if not is_instance_valid(joystick):
			continue

		if joystick.has_meta("am_vector"):
			var vector = joystick.get_meta("am_vector")
			if vector:
				vector.set_virtual_vector(joystick.get_value())


func _update_input_processing() -> void:
	if Engine.is_editor_hint():
		return

	match input_processing:
		0: # Physics
			set_physics_process(true)
			set_process(false)
		1: # Process
			set_physics_process(false)
			set_process(true)


func _warings_actions(warnings: PackedStringArray) -> void:
	for action in actions_data:
		if not action:
			warnings.append("There are actions listed in actions_data, but they are not configured. Please consider completing the configuration.")
		else:
			if action.action_name.strip_edges() == "":
				warnings.append("Invalid action name. Consider assigning a unique name to action_name in Actions Data.")

			if action.action.strip_edges() == "":
				warnings.append("Invalid action. Consider adding an action to Actions Data.")

			if action.touch_screen_button_path and get_node(action.touch_screen_button_path) and not get_node(action.touch_screen_button_path) is TouchScreenButton:
				warnings.append("The touch_screen_button_path property only accepts the path of a TouchScreenButton node.")

			if not ProjectSettings.has_setting("input/%s" % action.action):
				warnings.append("Action name %s in Actions Data not found. Check if it exists or if there was a typo."%action.action)

			for action_2 in actions_data:
				if action_2:
					if not action.get_instance_id() == action_2.get_instance_id():
						if action.action_name == action_2.action_name:
							return warnings.append("In Actions Data, there are duplicate action_names (%s). Consider using a unique name." % action.action_name)


func _warings_axis(warnings: PackedStringArray) -> void:
	for axis in axis_data:
		if not axis:
			warnings.append("There are axis listed in axis_data, but they are not configured. Please consider completing the configuration.")
		else:
			if axis.axis_name.strip_edges() == "":
				warnings.append("Invalid axis name. Consider assigning a unique name to axis_name in Axis Data.")

			if axis.negative_x.strip_edges() == "":
				warnings.append("Invalid negative_x. Consider adding an negative_x to Axis Data.")

			if axis.positive_x.strip_edges() == "":
				warnings.append("Invalid positive_x. Consider adding an positive_x to Axis Data.")

			if not ProjectSettings.has_setting("input/%s" % axis.negative_x):
				warnings.append("Action name %s in negative_x in Axis Data not found. Check if it exists or if there was a typo."%axis.negative_x)

			if not ProjectSettings.has_setting("input/%s" % axis.positive_x):
				warnings.append("Action name %s in positive_x in Axis Data not found. Check if it exists or if there was a typo."%axis.positive_x)

			if axis.negative_x == axis.positive_x:
				warnings.append("In Axis Data (%s), negative_x has the same value as positive_x .Consider assigning a different action to each." % axis.axis_name)
				
			for axis_2 in axis_data:
				if axis_2:
					if not axis.get_instance_id() == axis_2.get_instance_id():
						if axis.axis_name == axis_2.axis_name:
							return warnings.append("In Axis Data, there are duplicate axis_names (%s). Consider using a unique name." % axis.axis_name)


func _warings_vectors(warnings: PackedStringArray) -> void:
	for vector in vectors_data:
		if not vector:
			warnings.append("There are vectors listed in vectors_data, but they are not configured. Please consider completing the configuration.")
		else:
			if vector.vector_name.strip_edges() == "":
				warnings.append("Invalid vector name. Consider assigning a unique name to vector_name in Vectors Data.")

			if vector.negative_x.strip_edges() == "":
				warnings.append("Invalid negative_x. Consider adding an negative_x to Vectors Data.")

			if vector.positive_x.strip_edges() == "":
				warnings.append("Invalid positive_x. Consider adding an positive_x to Vectors Data.")

			if vector.negative_y.strip_edges() == "":
				warnings.append("Invalid negative_y. Consider adding an negative_y to Vectors Data.")

			if vector.positive_y.strip_edges() == "":
				warnings.append("Invalid positive_y. Consider adding an positive_y to Vectors Data.")

			if vector.action_manager_joystick_path and get_node(vector.action_manager_joystick_path) and not get_node(vector.action_manager_joystick_path) is ActionManagerJoystick:
				warnings.append("The action_manager_joystick_path property only accepts the path of a ActionManagerJoystick node.")

			if not ProjectSettings.has_setting("input/%s" % vector.negative_x):
				warnings.append("Action name %s in negative_x in Vectors Data not found. Check if it exists or if there was a typo."%vector.negative_x)

			if not ProjectSettings.has_setting("input/%s" % vector.positive_x):
				warnings.append("Action name %s in positive_x in Vectors Data not found. Check if it exists or if there was a typo."%vector.positive_x)

			if not ProjectSettings.has_setting("input/%s" % vector.negative_y):
				warnings.append("Action name %s in negative_y in Vectors Data not found. Check if it exists or if there was a typo."%vector.negative_y)

			if not ProjectSettings.has_setting("input/%s" % vector.positive_y):
				warnings.append("Action name %s in positive_y in Vectors Data not found. Check if it exists or if there was a typo."%vector.positive_y)

			# CHECK VALUES
			if vector.negative_x == vector.positive_x:
				warnings.append("In Vectors Data (%s), negative_x has the same value as positive_x .Consider assigning a different action to each." % vector.vector_name)
				
			if vector.negative_x == vector.negative_y:
				warnings.append("In Vectors Data (%s), negative_x has the same value as negative_y .Consider assigning a different action to each." % vector.vector_name)
				
			if vector.positive_x == vector.negative_y:
				warnings.append("In Vectors Data (%s), positive_x has the same value as negative_y .Consider assigning a different action to each." % vector.vector_name)
				
			if vector.negative_x == vector.positive_x:
				warnings.append("In Vectors Data (%s), negative_x has the same value as positive_x .Consider assigning a different action to each." % vector.vector_name)
			
			if vector.negative_y == vector.positive_y:
				warnings.append("In Vectors Data (%s), negative_y has the same value as positive_y .Consider assigning a different action to each." % vector.vector_name)
				
			for vector_2 in vectors_data:
				if vector_2:
					if not vector.get_instance_id() == vector_2.get_instance_id():
						if vector.vector_name == vector_2.vector_name:
							return warnings.append("In Vectors Data, there are duplicate vector_names (%s). Consider using a unique name." % vector.vector_name)
