extends Control
## Test suite aggregator for CI.
##
## Child nodes (test suites) run synchronously in their _ready (children
## are ready before the parent). This script sums their counters, prints
## the grand total and exits with a CI-friendly code: 0 = all passed,
## 1 = failures. Without it the scene hangs forever after the summary.

func _ready() -> void:
	await get_tree().process_frame
	var passed: int = 0
	var failed: int = 0
	var suites: int = 0
	for child in get_children():
		var child_passed = child.get("_pass_count")
		if child_passed != null:
			suites += 1
			passed += child_passed
			failed += child.get("_fail_count")
	print("\n=== SUITES TOTAL: %d suites, %d passed, %d failed ===" % [suites, passed, failed])
	get_tree().quit(0 if (failed == 0 and suites > 0) else 1)
