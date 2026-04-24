extends SceneTree

var _passed: int = 0
var _failed: int = 0
var _current_test: String = ""

func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_failed += 1
		push_error("FAIL: " + _current_test + " — " + message)
	else:
		_passed += 1

func _initialize() -> void:
	print("\n=== CWG Test Suite ===")
	var test_files: PackedStringArray = [
		"res://tests/test_card_database.gd",
		"res://tests/test_battle_resolver.gd",
		"res://tests/test_morale_system.gd",
		"res://tests/test_turn_manager.gd"
	]
	for path in test_files:
		print("\nRunning: " + path)
		var script: GDScript = load(path)
		if script == null:
			push_error("Cannot load: " + path)
			continue
		var instance: RefCounted = script.new()
		if instance.has_method("before_all"):
			instance.before_all()
		var methods: Array = instance.get_script_method_list()
		for method in methods:
			var name: String = method["name"]
			if name.begins_with("test_"):
				_current_test = name
				instance.call(name)
		if instance.has_method("after_all"):
			instance.after_all()
		print("  Done: " + path)
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit()
