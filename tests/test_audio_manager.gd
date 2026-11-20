extends Node
## Suite: AudioManager (SFX table, degradation, throttle, button attach).
## Registered in test_runner.tscn; counters picked up by test_runner_main.gd.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

const EXPECTED_SFX_IDS: PackedStringArray = [
	"button_click", "card_draw", "card_play", "battle_start", "battle_hit",
	"battle_destroy", "march", "morale_up", "morale_down", "victory",
	"defeat", "phonograph_needle",
]

func _ready() -> void:
	print("\n=== TEST: AudioManager ===")
	test_table_covers_design_set()
	test_all_paths_resolve()
	test_unknown_id_is_silent_noop()
	test_known_id_plays()
	test_broken_path_degrades_to_silence()
	test_rapid_repeat_is_throttled()
	test_button_attach_connects()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_table_covers_design_set() -> void:
	for id in EXPECTED_SFX_IDS:
		_assert(AudioManager.has_sfx(id), "table has sfx id '%s'" % id)

func test_all_paths_resolve() -> void:
	for id in AudioManager.get_sfx_ids():
		var path: String = AudioManager.get_sfx_path(id)
		_assert(path.begins_with("res://assets/audio/sfx/"), "'%s' points into assets" % id)
		_assert(ResourceLoader.exists(path), "'%s' resolves via ResourceLoader (%s)" % [id, path])

func test_unknown_id_is_silent_noop() -> void:
	_assert(AudioManager.play("no_such_sfx") == false, "unknown id returns false")
	_assert(AudioManager.has_sfx("no_such_sfx") == false, "unknown id is not in the table")

func test_known_id_plays() -> void:
	AudioManager.reset_throttle_for_tests()
	AudioManager.override_sfx_path_for_tests("battle_start", "res://assets/audio/sfx/battle_start.wav")
	_assert(AudioManager.play("battle_start") == true, "known id with real file returns true")

func test_broken_path_degrades_to_silence() -> void:
	AudioManager.override_sfx_path_for_tests("victory", "res://assets/audio/sfx/does_not_exist.wav")
	_assert(AudioManager.play("victory") == false, "broken path returns false, no crash")
	_assert(AudioManager.play("victory") == false, "second call stays silent (failure cached)")
	# Restore the real path so later suites see the pristine table.
	AudioManager.override_sfx_path_for_tests("victory", "res://assets/audio/sfx/victory.wav")
	_assert(AudioManager.play("victory") == true, "restored path plays again")

func test_rapid_repeat_is_throttled() -> void:
	AudioManager.override_sfx_path_for_tests("button_click", "res://assets/audio/sfx/button_click.wav")
	_assert(AudioManager.play("button_click") == true, "first click plays")
	_assert(AudioManager.play("button_click") == false, "immediate repeat is throttled")

func test_button_attach_connects() -> void:
	var btn: Button = Button.new()
	add_child(btn)
	var before: int = btn.pressed.get_connections().size()
	AudioManager.attach_button_sounds(btn)
	AudioManager.attach_button_sounds(btn)
	var after: int = btn.pressed.get_connections().size()
	_assert(after == before + 1, "attach connects exactly once (double call is a no-op)")
	btn.queue_free()

func _print_summary() -> void:
	for r in _test_results:
		print(r)
	var total: int = _pass_count + _fail_count
	print("\n  TOTAL: %d/%d passed, %d failed" % [_pass_count, total, _fail_count])
	if _fail_count == 0:
		print("  ALL TESTS PASSED!")
	else:
		print("  SOME TESTS FAILED!")
	print("===========================\n")
