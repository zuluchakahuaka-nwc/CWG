extends Node
## Suite: MusicSlots (manifest law - slots over hardcoded track paths).
## Registered in test_runner.tscn; counters picked up by test_runner_main.gd.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

const REQUIRED_SLOTS: PackedStringArray = ["menu", "game_union", "game_confederate", "victory", "defeat"]
const REQUIRED_FIELDS: PackedStringArray = ["id", "role", "category", "loop", "source", "license", "status"]

func _ready() -> void:
	print("\n=== TEST: MusicSlots ===")
	test_manifest_loads_all_slots()
	test_slot_fields_complete()
	test_slot_categories_exist_in_catalog()
	test_side_slot_mapping()
	test_unknown_slot_is_silence()
	test_style_override_wins_for_side_slots()
	test_has_audio_never_crashes()
	test_no_track_paths_in_code()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_manifest_loads_all_slots() -> void:
	for id in REQUIRED_SLOTS:
		_assert(MusicSlots.has_slot(id), "manifest has slot '%s'" % id)
	_assert(MusicSlots.slot_ids().size() >= REQUIRED_SLOTS.size(), "at least %d slots loaded" % REQUIRED_SLOTS.size())

func test_slot_fields_complete() -> void:
	for id in MusicSlots.slot_ids():
		var slot: Dictionary = MusicSlots.get_slot(id)
		for field in REQUIRED_FIELDS:
			_assert(slot.has(field), "slot '%s' has field '%s'" % [id, field])

func test_slot_categories_exist_in_catalog() -> void:
	for id in MusicSlots.slot_ids():
		var category: String = str(MusicSlots.get_slot(id).get("category", ""))
		var playlist: Array = CardDatabase.get_music_tracks(category)
		_assert(not playlist.is_empty(), "slot '%s' category '%s' resolves to tracks" % [id, category])

func test_side_slot_mapping() -> void:
	_assert(MusicSlots.side_slot("union") == "game_union", "union maps to game_union")
	_assert(MusicSlots.side_slot("confederate") == "game_confederate", "confederate maps to game_confederate")
	_assert(MusicSlots.slot_side(MusicSlots.side_slot("union")) == "union", "slot_side round-trips")

func test_unknown_slot_is_silence() -> void:
	_assert(not MusicSlots.has_slot("no_such_slot"), "unknown slot is unknown")
	_assert(MusicSlots.playlist_for("no_such_slot").is_empty(), "unknown slot playlist is empty (silence, no crash)")
	_assert(MusicSlots.effective_category("no_such_slot") == "", "unknown slot has no category")

func test_style_override_wins_for_side_slots() -> void:
	var saved: String = GameManager.get_music_style("union")
	GameManager.set_music_style("union", "folk")
	_assert(MusicSlots.effective_category("game_union") == "folk", "settings override rebinds game_union")
	GameManager.set_music_style("union", saved)
	_assert(MusicSlots.effective_category("game_union") == saved, "restored override returns original binding")

func test_has_audio_never_crashes() -> void:
	# Dev machines ship local mp3s (true); CI builds do not (false) - both
	# are valid outcomes, the contract is "returns without crashing".
	for id in MusicSlots.slot_ids():
		var verdict: bool = MusicSlots.has_audio(id)
		_assert(typeof(verdict) == TYPE_BOOL, "has_audio('%s') returns a bool" % id)
	_assert(not MusicSlots.has_audio("no_such_slot"), "bogus slot has no audio")

func test_no_track_paths_in_code() -> void:
	# Hub law: track file paths live in data files, never in code.
	var offenders: Array = []
	for script_path in ["res://scripts/core/music_slots.gd", "res://scripts/ui/phonograph_player.gd"]:
		var f: FileAccess = FileAccess.open(script_path, FileAccess.READ)
		if f == null:
			offenders.append(script_path + " (unreadable)")
			continue
		if f.get_as_text().contains("res://assets/audio/music/"):
			offenders.append(script_path)
		f.close()
	_assert(offenders.is_empty(), "no hardcoded track paths in slot code %s" % str(offenders))

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
