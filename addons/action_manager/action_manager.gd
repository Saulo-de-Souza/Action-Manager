@icon("./icon.svg")

## [b]Action Manager[/b] is an advanced input manager for Godot 4.5 that provides:[br][br]
## - Long press and long press hold[br]
## - Double tap[br]
## - Action toggle and oneshot[br]
## - Configurable input repetition[br]
## - Action or group blocking[br]
## - Manual input injection (UI, touch, replay, AI)[br]
## - Signals for mouse, keyboard, and gamepad events[br][br]
## It offers a unified API for reliable input handling with full state control.
class_name ActionManager extends Node


# ---------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------
signal all_event(event: InputEvent)
signal mouse_motion_event(event: InputEventMouseMotion)
signal mouse_button_event(event: InputEventMouseButton)
signal key_event(event: InputEventKey)
signal joy_button_event(event: InputEventJoypadButton)
signal joy_motion_event(event: InputEventJoypadMotion)


# ---------------------------------------------------------
# PUBLIC PROPERTIES
# ---------------------------------------------------------
var long_press_time := 0.5
var double_tap_time := 0.25
var repeat_delay := 0.8
var repeat_interval := 0.8


# ---------------------------------------------------------
# PRIVATE PROPERTIES
# ---------------------------------------------------------
var _actions_pressed: Dictionary[StringName, bool] = {}
var _actions_oneshot: Dictionary[StringName, bool] = {}
var _actions_toggle: Dictionary[StringName, bool] = {}
var _actions_press_time: Dictionary[StringName, float] = {}
var _actions_long_press: Dictionary[StringName, bool] = {}
var _actions_last_tap_time: Dictionary[StringName, float] = {}
var _actions_double_tap: Dictionary[StringName, bool] = {}
var _actions_long_press_triggered: Dictionary[StringName, bool] = {}
var _actions_long_press_hold: Dictionary[StringName, bool] = {}
var _actions_repeat_timer: Dictionary[StringName, float] = {}
var _actions_repeat: Dictionary[StringName, bool] = {}
var _actions_repeat_config: Dictionary = {}
var _input_enabled: bool = true
var _blocked_actions: Dictionary[StringName, bool] = {}
var _action_groups: Dictionary = {}
var _blocked_groups: Dictionary[StringName, bool] = {}
var _keycode_to_actions := {}
var _mouse_button_to_actions := {}
var _joy_button_to_actions := {}


# ---------------------------------------------------------
# ENGINE METHODS
# ---------------------------------------------------------
func _ready() -> void:
	_build_input_cache()


func _unhandled_input(event: InputEvent) -> void:
	all_event.emit(event)

	if event is InputEventMouseMotion:
		mouse_motion_event.emit(event)
	elif event is InputEventMouseButton:
		mouse_button_event.emit(event)
	elif event is InputEventKey:
		key_event.emit(event)
	elif event is InputEventJoypadButton:
		joy_button_event.emit(event)
	elif event is InputEventJoypadMotion:
		joy_motion_event.emit(event)


func _process(delta: float) -> void:
	if not _input_enabled:
		return

	_sync_actions_from_input()
	
	for action in _actions_pressed:
		if not _actions_pressed[action]:
			continue

		_actions_press_time[action] += delta

		if (_actions_press_time[action] >= long_press_time and not _actions_long_press_triggered.get(action, false) and not _is_action_blocked(action)):
			_actions_long_press[action] = true
			_actions_long_press_triggered[action] = true
			_actions_long_press_hold[action] = true

		if _actions_long_press_triggered.get(action, false):
			_actions_long_press_hold[action] = true

		_actions_repeat_timer[action] = _actions_repeat_timer.get(action, 0.0) + delta

		var delay := repeat_delay
		var interval := repeat_interval

		if _actions_repeat_config.has(action):
			var cfg = _actions_repeat_config[action]
			delay = cfg.get("delay", repeat_delay)
			interval = cfg.get("interval", repeat_interval)

		if _actions_repeat_timer[action] < delay:
			continue

		var repeat_time := _actions_repeat_timer[action] - delay
		if repeat_time >= interval:
			_actions_repeat[action] = true
			_actions_repeat_timer[action] = delay


# ---------------------------------------------------------
# PUBLIC METHODS
# ---------------------------------------------------------
func inject_action(action: StringName, pressed: bool) -> void:
	if not _input_enabled or _is_action_blocked(action):
		return

	if pressed:
		_press_action(action)
	else:
		_release_action(action)


func set_action_repeat(action: StringName, delay: float, interval: float) -> void:
	_actions_repeat_config[action] = {
		"delay": delay,
		"interval": interval
	}


func get_action_pressed(action: StringName) -> bool:
	return _actions_pressed.get(action, false) and not _is_action_blocked(action)


func get_action_hold(action: StringName) -> bool:
	return get_action_pressed(action)


func get_action_oneshot(action: StringName) -> bool:
	if _is_action_blocked(action):
		return false

	if _actions_oneshot.get(action, false):
		_actions_oneshot[action] = false
		return true
	return false


func get_action_toggle(action: StringName) -> bool:
	if _is_action_blocked(action):
		return false
	return _actions_toggle.get(action, false)


func get_action_long_press(action: StringName) -> bool:
	if _is_action_blocked(action):
		return false

	if _actions_long_press.get(action, false):
		_actions_long_press[action] = false
		return true
	return false


func get_action_double_tap(action: StringName) -> bool:
	if _is_action_blocked(action):
		return false

	if _actions_double_tap.get(action, false):
		_actions_double_tap[action] = false
		return true
	return false


func get_action_long_press_hold(action: StringName) -> bool:
	if _is_action_blocked(action):
		return false

	return (
		_actions_long_press_hold.get(action, false)
		and _actions_pressed.get(action, false)
	)


func get_action_repeat(action: StringName) -> bool:
	if _is_action_blocked(action):
		return false

	if _actions_repeat.get(action, false):
		_actions_repeat[action] = false
		return true

	return false


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		reset_all()


func block_action(action: StringName) -> void:
	_blocked_actions[action] = true
	reset_action(action)


func unblock_action(action: StringName) -> void:
	_blocked_actions.erase(action)


func register_action_group(group: StringName, actions: Array[StringName]) -> void:
	_action_groups[group] = actions


func block_group(group: StringName) -> void:
	_blocked_groups[group] = true

	for action in _action_groups.get(group, []):
		reset_action(action)


func unblock_group(group: StringName) -> void:
	_blocked_groups.erase(group)


func clear_action_repeat(action: StringName) -> void:
	_actions_repeat_config.erase(action)


func reset_action(action: StringName) -> void:
	_actions_pressed[action] = false
	_actions_oneshot[action] = false
	_actions_toggle[action] = false
	_actions_press_time[action] = 0.0
	_actions_long_press[action] = false
	_actions_long_press_triggered[action] = false
	_actions_long_press_hold[action] = false
	_actions_double_tap[action] = false
	_actions_last_tap_time.erase(action)
	_actions_repeat[action] = false
	_actions_repeat_timer[action] = 0.0


func reset_all(reset_actions_repeat_config: bool = false) -> void:
	_actions_pressed.clear()
	_actions_oneshot.clear()
	_actions_toggle.clear()
	_actions_press_time.clear()
	_actions_long_press.clear()
	_actions_long_press_triggered.clear()
	_actions_long_press_hold.clear()
	_actions_double_tap.clear()
	_actions_last_tap_time.clear()
	_actions_repeat.clear()
	_actions_repeat_timer.clear()

	if reset_actions_repeat_config:
		_actions_repeat_config.clear()


# ---------------------------------------------------------
# PUBLIC METHODS - INPUT
# ---------------------------------------------------------
func get_vector(negative_x: StringName, positive_x: StringName, negative_y: StringName, positive_y: StringName, dead_zone: float = 0.0) -> Vector2:
	var x := 0.0
	var y := 0.0

	if not _is_action_blocked(negative_x):
		x -= Input.get_action_raw_strength(negative_x)
	if not _is_action_blocked(positive_x):
		x += Input.get_action_raw_strength(positive_x)
	if not _is_action_blocked(negative_y):
		y -= Input.get_action_raw_strength(negative_y)
	if not _is_action_blocked(positive_y):
		y += Input.get_action_raw_strength(positive_y)

	var vec := Vector2(x, y)
	if vec.length() < dead_zone:
		vec = Vector2.ZERO
	else:
		vec = vec.normalized() * ((vec.length() - dead_zone) / (1.0 - dead_zone))
		
	return vec


func is_action_just_released(action: StringName, exact_match: bool = false) -> float:
	if _is_action_blocked(action):
		return false
	return Input.is_action_just_released(action, exact_match)


func get_axis(negative_action: StringName, positive_action: StringName, dead_zone: float = 0.15) -> float:
	var value := 0.0

	if not _is_action_blocked(negative_action):
		value -= Input.get_action_raw_strength(negative_action)
	if not _is_action_blocked(positive_action):
		value += Input.get_action_raw_strength(positive_action)

	if abs(value) < dead_zone:
		return 0.0

	return clamp(value, -1.0, 1.0)


# ---------------------------------------------------------
# PRIVATE METHODS
# ---------------------------------------------------------
func _is_action_blocked(action: StringName) -> bool:
	if _blocked_actions.get(action, false):
		return true

	for group in _blocked_groups:
		var actions = _action_groups.get(group)
		if actions and action in actions:
			return true

	return false


func _build_input_cache() -> void:
	_keycode_to_actions.clear()
	_mouse_button_to_actions.clear()
	_joy_button_to_actions.clear()

	for action in InputMap.get_actions():
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				var keycode = ev.keycode
				if not _keycode_to_actions.has(keycode):
					_keycode_to_actions[keycode] = []
				_keycode_to_actions[keycode].append(action)

			elif ev is InputEventMouseButton:
				var btn = ev.button_index
				if not _mouse_button_to_actions.has(btn):
					_mouse_button_to_actions[btn] = []
				_mouse_button_to_actions[btn].append(action)

			elif ev is InputEventJoypadButton:
				var btn = ev.button_index
				if not _joy_button_to_actions.has(btn):
					_joy_button_to_actions[btn] = []
				_joy_button_to_actions[btn].append(action)


func _sync_actions_from_input() -> void:
	for action in InputMap.get_actions():
		if _is_action_blocked(action):
			continue

		var pressed := Input.is_action_pressed(action)
		var was_pressed = _actions_pressed.get(action, false)

		if pressed and not was_pressed:
			_press_action(action)
		elif not pressed and was_pressed:
			_release_action(action)


func _press_action(action: StringName) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	if _actions_last_tap_time.has(action):
		if now - _actions_last_tap_time[action] <= double_tap_time:
			_actions_double_tap[action] = true

	_actions_last_tap_time[action] = now

	if not _actions_pressed.get(action, false):
		_actions_oneshot[action] = true
		_actions_toggle[action] = not _actions_toggle.get(action, false)

	_actions_pressed[action] = true
	_actions_press_time[action] = 0.0
	_actions_long_press[action] = false
	_actions_long_press_triggered[action] = false
	_actions_long_press_hold[action] = false
	_actions_repeat[action] = false
	_actions_repeat_timer[action] = 0.0


func _release_action(action: StringName) -> void:
	_actions_pressed[action] = false
	_actions_press_time[action] = 0.0
	_actions_long_press[action] = false
	_actions_long_press_triggered[action] = false
	_actions_long_press_hold[action] = false
	_actions_double_tap[action] = false
	_actions_repeat[action] = false
	_actions_repeat_timer[action] = 0.0
