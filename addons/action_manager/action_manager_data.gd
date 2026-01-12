@tool
@icon("./icon.svg")


class_name ActionManagerData extends Resource


@export var action: StringName:
	set(value):
		action = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()
			
@export var long_time: float = 1.0:
	set(value):
		long_time = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()
			
@export var repeat_time: float = 0.2:
	set(value):
		repeat_time = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()
			
@export var action_type: ActionManager.action_type = ActionManager.action_type.PRESSED:
	set(value):
		action_type = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()


var owner: ActionManager
var _press_time: float = 0.0
var _repeat_timer: float = 0.0
var _long_triggered: bool = false
var _toggle_state: bool = false
var _event_fired: bool = false
var _hold_state: bool = false


func _init_owner(p_owner: ActionManager) -> void:
	owner = p_owner


func update(delta: float) -> void:
	_event_fired = false
	_hold_state = false

	var pressed := Input.is_action_pressed(action)

	if pressed:
		_press_time += delta

		if action_type == ActionManager.action_type.TOGGLE:
			pass

		elif action_type == ActionManager.action_type.LONG_PRESS:
			if _press_time >= long_time and not _long_triggered:
				_long_triggered = true
				_event_fired = true

		elif action_type == ActionManager.action_type.LONG_PRESS_HOLD:
			if _press_time >= long_time:
				_hold_state = true

		elif action_type == ActionManager.action_type.REPEAT:
			if _press_time >= long_time:
				_repeat_timer += delta
				if _repeat_timer >= repeat_time:
					_repeat_timer = 0.0
					_event_fired = true

	else:
		# TAP → TOGGLE
		if action_type == ActionManager.action_type.TOGGLE and _press_time > 0.0:
			_toggle_state = not _toggle_state

		_press_time = 0.0
		_repeat_timer = 0.0
		_long_triggered = false
