@tool
@icon("./icons/action.svg")


class_name ActionManagerAction extends Resource


## Enables or disables the execution of actions.
@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## This is the name you will give to the action and which you will call via the get_action(action_name: StringName) function.[br]
## Example: [code]var jump: bool = $action_manager.get_action("Jump")[/code]
@export_placeholder("Action name") var action_name: String:
	set(value):
		action_name = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## This is the action you will use. For example: [code]"ui_accept", "ui_cancel"[/code], etc.
@export var action: StringName:
	set(value):
		action = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## This is the time it will take for the [code]LONG_PRESS[/code], [code]LONG_PRESS_HOLD[/code], and [code]REPEAT[/code] triggers to fire.
@export_range(0.0, 1.0, 0.001, "or_greater") var long_time: float = 1.0:
	set(value):
		long_time = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## This is the amount of time the [b]REPEAT[/b] trigger will repeat after the [b]long_time[/b] has been triggered.
@export_range(0.0, 1.0, 0.001, "or_greater") var repeat_time: float = 0.2:
	set(value):
		repeat_time = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## The action will be triggered by the time set between two button presses.
@export_range(0.05, 0.5, 0.01, "or_greater") var double_press_time: float = 0.25:
	set(value):
		double_press_time = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## Each action can be configured to work as you wish.[br][br]
## Use [b]PRESSED[/b] to check every frame, [br]
## use [b]JUST_PRESSED[/b] to receive only one response while holding down the key or button. [br]
## Use [b]RELEASED[/b] to receive the action when you release the key or button. [br]
## Use [b]TOGGLE[/b] to toggle between true and false, even within a loop. [br]
## Use [b]LONG_PRESS[/b] to press once, hold down, and receive the same result as JUST_PRESSED. [br]
## Use [b]LONG_PRESS_HOLD[/b] to have the same effect as LONG_PRESS, except that after being triggered, the action corresponding to each frame will be triggered. [br]
## Use [b]REPEAT[/b] to have an action that repeats at a specific time you configure, and [br]
## use [b]DOUBLE_PRESS[/b] to activate the action only if the player presses the button or key twice within the interval configured in double_press_time.[br]
@export var action_type: action_type_enum = action_type_enum.PRESSED:
	set(value):
		action_type = value
		if is_instance_valid(owner):
			owner.update_configuration_warnings()

## Associate a TouchScreenButton node to use the action.
@export var touch_screen_button_path: NodePath:
	set(value):
		touch_screen_button_path = value
		if is_instance_valid(owner):
			if touch_screen_button_path and owner.get_node(touch_screen_button_path) and not owner.get_node(touch_screen_button_path) is TouchScreenButton:
				touch_screen_button_path = ""
				push_warning("The touch_screen_button_path property only accepts the path of a TouchScreenButton node.")
			owner.update_configuration_warnings()


var owner: ActionManager
enum action_type_enum {
						## Continuous firing.
						PRESSED,
						
						## Single firing.
						JUST_PRESSED,
						
						## Firing when the button or key is released.
						RELEASED,
						
						## Toggles the value.
						TOGGLE,
						
						## Firing after a single press.
						LONG_PRESS,
						
						## Firing after a press and continuing to fire afterward if the button or key is held down.
						LONG_PRESS_HOLD,
						
						## Repeats firing for a specified time.
						REPEAT,
						
						## Firing only if pressed twice within the configured interval.
						DOUBLE_PRESS
						}
var _press_time: float = 0.0
var _repeat_timer: float = 0.0
var _long_triggered: bool = false
var _toggle_state: bool = false
var _event_fired: bool = false
var _hold_state: bool = false
var _double_timer: float = 0.0
var _waiting_second_press: bool = false


func _inject_pressed(_action_name: StringName) -> void:
	if not enabled:
		return
	Input.action_press(_action_name)


func _inject_released(_action_name: StringName) -> void:
	if not enabled:
		return
	Input.action_release(_action_name)


func _update(delta: float) -> void:
	if not enabled:
		_event_fired = false
		_hold_state = false
		_waiting_second_press = false
		_double_timer = 0.0
		return
		
	if action.strip_edges() == "":
		return

	_event_fired = false
	_hold_state = false

	var pressed := Input.is_action_pressed(action)
	var just_pressed := Input.is_action_just_pressed(action)

	# ----------------------------------------------------
	# DOUBLE PRESS (isolado, ordem CRÍTICA)
	# ----------------------------------------------------
	if action_type == action_type_enum.DOUBLE_PRESS:
		if just_pressed:
			if _waiting_second_press and _double_timer <= double_press_time:
				_event_fired = true
				_waiting_second_press = false
				_double_timer = 0.0
			else:
				_waiting_second_press = true
				_double_timer = 0.0

		if _waiting_second_press:
			_double_timer += delta
			if _double_timer > double_press_time:
				_waiting_second_press = false
				_double_timer = 0.0

		return

	# ----------------------------------------------------
	# MODOS BASEADOS EM HOLD
	# ----------------------------------------------------
	if pressed:
		_press_time += delta

		if action_type == action_type_enum.TOGGLE:
			pass

		elif action_type == action_type_enum.LONG_PRESS:
			if _press_time >= long_time and not _long_triggered:
				_long_triggered = true
				_event_fired = true

		elif action_type == action_type_enum.LONG_PRESS_HOLD:
			if _press_time >= long_time:
				_hold_state = true

		elif action_type == action_type_enum.REPEAT:
			if _press_time >= long_time:
				_repeat_timer += delta
				if _repeat_timer >= repeat_time:
					_repeat_timer = 0.0
					_event_fired = true

	# ----------------------------------------------------
	# RELEASE
	# ----------------------------------------------------
	else:
		if action_type == action_type_enum.TOGGLE and _press_time > 0.0:
			_toggle_state = not _toggle_state

		_press_time = 0.0
		_repeat_timer = 0.0
		_long_triggered = false


func _init_owner(p_owner: ActionManager) -> void:
	owner = p_owner
