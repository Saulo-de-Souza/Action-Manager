@tool
@icon("./icon.svg")


## [b]Action Manager[/b] is a superclass built upon Godot's Input singleton that offers:[br]
## [br]
## Configuration of action types: TOGGLE, LONG PRESS, LONG PRESS HOLD, REPEAT, DOUBLE PRESS, as well as PRESSED, JUST_PRESSED, and JUST_RELEASED.[br]
## [br]
## Attach TouchScreenButtons to events.[br]
## [br]
## It comes with a Virtual Joystick named ActionManagerJoystick. Simply create and connect it to the Action Manager.
class_name ActionManager extends CanvasLayer


# ----------------------------------------------------
# EXPORTS
# ----------------------------------------------------
## If you choose Physics, the long press and repeat time will be based on physics_process.[br]
## Otherwise, it will be based on process.[br]
## We advise using physics because that's where you'll want to handle events.[br]
@export_enum("Physics Process", "Process") var input_processing: int = 0:
	set(value):
		input_processing = value
		_update_input_processing()
		update_configuration_warnings()

@export_group("Actions")
## These are the actions you want to work with. [br]
## For example: [code]"ui_accept", "ui_left", "ui_right"[/code], etc.
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
## These are the actions used to create horizontal or vertical movement, for example, using [b]negative x and positive x[/b] to obtain a [code]float[/code].
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
## These are the actions used to create a 3D movement, for example, [b]negative x, positive x, negative y, and positive y[/b] to obtain a [code]Vector2[/code].
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


var _am_warning_once: ActionManagerWarningOnce = ActionManagerWarningOnce.new()
var _joysticks: Array[ActionManagerJoystick] = []
var _warnings: PackedStringArray = []


# ----------------------------------------------------
# ENGINE METHODS
# ----------------------------------------------------
func _ready():
	_handle_editor()
	_update_input_processing()
	_handle_actions()
	_handle_vectors()
	
	if not Engine.is_editor_hint():
		_warings_actions(_warnings)
		_warings_axis(_warnings)
		_warings_vectors(_warnings)
		_warnings_global(_warnings)


func _process(delta: float) -> void:
	_update_actions(delta)
	_update_joysticks()


func _physics_process(delta: float) -> void:
	_update_actions(delta)
	_update_joysticks()


func _get_configuration_warnings() -> PackedStringArray:
	_warnings = []
	_warings_actions(_warnings)
	_warings_axis(_warnings)
	_warings_vectors(_warnings)
	_warnings_global(_warnings)
	return _warnings


# ----------------------------------------------------
# GET DATA
# ----------------------------------------------------
## Get an ActionManagerAction by its name.
func get_data_action(action_name: StringName) -> ActionManagerAction:
	for action in actions_data:
		if action:
			if action.action_name == action_name:
				return action
	_am_warning_once.push_warning("5", "Action %s not found." % action_name)
	return null


## Get an ActionManagerAxis by its name.
func get_data_axis(axis_name: StringName) -> ActionManagerAxis:
	for axis in axis_data:
		if axis:
			if axis.axis_name == axis_name:
				return axis
	_am_warning_once.push_warning("4", "Axis %s not found." % axis_name)
	return null


## Get an ActionManagerVector by its name.
func get_data_vector(vector_name: StringName) -> ActionManagerVector:
	for vector in vectors_data:
		if vector:
			if vector.vector_name == vector_name:
				return vector
	_am_warning_once.push_warning("3", "Vector %s not found." % vector_name)
	return null


# ----------------------------------------------------
# PUBLIC METHODS
# ----------------------------------------------------
## Check if an action is being executed.
func get_action(action_name: StringName) -> bool:
	var action_data: ActionManagerAction = get_data_action(action_name)
	if not action_data:
		return false

	if not action_data.enabled and not action_data.action_type == ActionManagerAction.action_type_enum.TOGGLE:
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


## Check if an axis is being executed.
func get_axis(action_name: StringName) -> float:
	var data: ActionManagerAxis = get_data_axis(action_name)
	if not data:
		return 0.0

	if not data.enabled:
		return 0.0

	return Input.get_axis(data.negative_x, data.positive_x)


## ## Check if an vector is being executed.
func get_vector(action_name: StringName, dead_zone: float = -1.0) -> Vector2:
	var vector: ActionManagerVector = get_data_vector(action_name)
	if not vector:
		return Vector2.ZERO

	if not vector.enabled:
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
						action._inject_pressed(action.action)
					)
					touch.released.connect(func():
						action._inject_released(action.action)
					)
				else:
					_am_warning_once.push_warning("2", "The touch_screen_button_path property must be of type TouchScreenButton. Consider adding a TouchScreenButton.")


func _handle_vectors() -> void:
	for vector in vectors_data:
		if vector:
			if vector.action_manager_joystick_path:
				var joystick = get_node(vector.action_manager_joystick_path)
				if joystick:
					if joystick is ActionManagerJoystick:
						joystick.set_meta("am_vector", vector)
						_joysticks.append(joystick)
					else:
						_am_warning_once.push_warning("1", "The action_manager_joystick_path property must be of type ActionManagerJoystick. Consider adding a ActionManagerJoystick.")


func _update_actions(delta: float) -> void:
	for action in actions_data:
		if action and action.enabled:
			action._update(delta)


func _update_joysticks() -> void:
	for joystick in _joysticks:
		if not is_instance_valid(joystick):
			continue

		if joystick.has_meta("am_vector"):
			var vector = joystick.get_meta("am_vector")
			if vector and vector.enabled:
				vector._set_virtual_vector(joystick.get_value())


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


func _warnings_global(warnings: PackedStringArray) -> void:
	if input_processing == 1 and (axis_data.size() > 0 or vectors_data.size() > 0):
		warnings.append("Axis and Vector inputs are recommended to use Physics Process.")
		_am_warning_once.push_warning("6", "Axis and Vector inputs are recommended to use Physics Process.")
