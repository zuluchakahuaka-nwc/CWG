class_name TestBase
extends RefCounted

func assert(condition: bool, message: String = "") -> void:
	if not condition:
		push_error("ASSERT FAIL: " + message)
	else:
		pass

func before_all() -> void:
	pass

func after_all() -> void:
	pass
