@tool
class_name ActionManagerWarningOnce extends RefCounted


var _emitted: Dictionary[StringName, bool] = {}


func push_warning(id: StringName, message: String) -> void:
	if _emitted.has(id):
		return

	_emitted[id] = true
	push_warning(message)


func clear() -> void:
	_emitted.clear()


func clear_id(id: StringName) -> void:
	_emitted.erase(id)


func was_emitted(id: StringName) -> bool:
	return _emitted.has(id)
