extends Node
## Suite: game start - initial garrisons from the scenario file.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

func _ready() -> void:
	print("\n=== TEST: GameStart garrisons ===")
	test_civil_war_places_garrisons()
	test_garrisons_survive_save_roundtrip()
	test_units_are_free_and_owned()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_civil_war_places_garrisons() -> void:
	GameManager.start_game("civil_war", "union")
	var dc: Array = GameManager._units_on_map.get("washington_dc", [])
	var rich: Array = GameManager._units_on_map.get("richmond", [])
	_assert(dc.size() == 2, "Washington DC starts with 2 garrison units")
	_assert(rich.size() == 2, "Richmond starts with 2 garrison units")
	_assert(dc.size() > 0 and dc[0].side == "union", "DC garrison is Union")
	_assert(rich.size() > 0 and rich[0].side == "confederate", "Richmond garrison is Confederate")
	_assert(dc.size() > 0 and dc[0].territory_id == "washington_dc", "garrison cards carry their territory id")

func test_garrisons_survive_save_roundtrip() -> void:
	GameManager.start_game("civil_war", "union")
	var data: Dictionary = GameManager.serialize()
	GameManager.deserialize(data)
	var dc: Array = GameManager._units_on_map.get("washington_dc", [])
	var rich: Array = GameManager._units_on_map.get("richmond", [])
	_assert(dc.size() == 2, "DC garrison survives serialize/deserialize")
	_assert(rich.size() == 2, "Richmond garrison survives serialize/deserialize")
	_assert(rich.size() > 0 and rich[0].side == "confederate", "garrison side survives the roundtrip")

func test_units_are_free_and_owned() -> void:
	GameManager.start_game("civil_war", "union")
	var res: Dictionary = GameManager.get_resources("union")
	_assert(int(res.get("money", 0)) == 7, "garrisons cost nothing (union money intact at 7)")
	var res_c: Dictionary = GameManager.get_resources("confederate")
	_assert(int(res_c.get("money", 0)) == 4, "garrisons cost nothing (confederate money intact at 4)")

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
