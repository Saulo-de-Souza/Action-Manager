@tool
@icon("./icon.svg")


class_name ActionManager extends Node


@export var actions: Dictionary[StringName, ActionManagerData]:
	set(value):
		actions = value
		if not is_inside_tree(): await tree_entered
		if not is_node_ready(): await ready
		await get_tree().process_frame
		for key in actions:
			var action: ActionManagerData = actions.get(key)
			if action:
				action._init_owner(self)
		update_configuration_warnings()


enum action_type {PRESSED, JUST_PRESSED, RELEASED, TOGGLE, LONG_PRESS, LONG_PRESS_HOLD, REPEAT}


func _process(delta: float) -> void:
	for key in actions:
		var data: ActionManagerData = actions[key]
		if data:
			data.update(delta)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	for key in actions:
		var action: ActionManagerData = actions.get(key)
		if action:
			if not action.action in InputMap.get_actions():
				warnings.append("Action name %s not found."%action.action)


	return warnings


func get_action(action_name: StringName) -> bool:
	var action_data := get_action_data(action_name)
	if not action_data:
		return false

	match action_data.action_type:
		action_type.PRESSED:
			return Input.is_action_pressed(action_data.action)

		action_type.JUST_PRESSED:
			return Input.is_action_just_pressed(action_data.action)

		action_type.RELEASED:
			return Input.is_action_just_released(action_data.action)

		action_type.TOGGLE:
			return action_data._toggle_state

		action_type.LONG_PRESS:
			return action_data._event_fired

		action_type.LONG_PRESS_HOLD:
			return action_data._hold_state

		action_type.REPEAT:
			return action_data._event_fired

		_:
			return false


func get_action_data(key: StringName) -> ActionManagerData:
	var action_data: ActionManagerData = actions.get(key)
	if not action_data:
		push_warning("Acton %s not found." % key)
	return action_data
