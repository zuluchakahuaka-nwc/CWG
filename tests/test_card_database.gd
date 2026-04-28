extends Node

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

func _ready() -> void:
	print("\n=== TEST: CardDatabase ===")
	test_load_union_units()
	test_load_confederate_units()
	test_load_commanders()
	test_load_situations()
	test_load_territories()
	test_load_connections()
	test_get_unit()
	test_get_situation()
	test_get_territory()
	test_get_all_units_for_side()
	test_get_adjacent_territories()
	test_all_cards_have_required_fields()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_load_union_units() -> void:
	var units: Array = CardDatabase.get_all_units_for_side("union")
	_assert(units.size() == 70, "Union units count = %d (expected 70)" % units.size())

func test_load_confederate_units() -> void:
	var units: Array = CardDatabase.get_all_units_for_side("confederate")
	_assert(units.size() == 76, "Confederate units count = %d (expected 76)" % units.size())

func test_load_commanders() -> void:
	var u_cmds: Array = CardDatabase.get_all_commanders_for_side("union")
	var c_cmds: Array = CardDatabase.get_all_commanders_for_side("confederate")
	_assert(u_cmds.size() == 12, "Union commanders = %d (expected 12)" % u_cmds.size())
	_assert(c_cmds.size() == 12, "Confederate commanders = %d (expected 12)" % c_cmds.size())

func test_load_situations() -> void:
	var all_ids: Dictionary = CardDatabase.get_all_card_ids()
	var sit_count: int = all_ids.get("situations", []).size()
	_assert(sit_count > 60, "Situations count = %d (expected 67+)" % sit_count)

func test_load_territories() -> void:
	var dc: Dictionary = CardDatabase.get_territory("washington_dc")
	_assert(not dc.is_empty(), "Washington DC territory exists")
	_assert(dc.get("is_capital", false) == true, "Washington DC is capital")
	_assert(dc.get("initial_owner", "") == "union", "Washington DC owned by Union")

func test_load_connections() -> void:
	var adj: Array = CardDatabase.get_adjacent_territories("washington_dc")
	_assert(adj.size() > 0, "Washington DC has connections (%d)" % adj.size())

func test_get_unit() -> void:
	var unit: Dictionary = CardDatabase.get_unit("u_inf_20me")
	_assert(not unit.is_empty(), "20th Maine exists in database")
	_assert(unit.get("attack", 0) == 3, "20th Maine ATK = %d (expected 3)" % unit.get("attack", 0))
	_assert(unit.get("defense", 0) == 5, "20th Maine DEF = %d (expected 5)" % unit.get("defense", 0))
	_assert(unit.get("rarity", "") == "legendary", "20th Maine is legendary")

func test_get_situation() -> void:
	var sit: Dictionary = CardDatabase.get_situation("SIT_CONSCRIPTION")
	_assert(not sit.is_empty(), "Conscription situation exists")
	_assert(sit.get("cost", -1) == 1, "Conscription costs 1")

func test_get_territory() -> void:
	var richmond: Dictionary = CardDatabase.get_territory("richmond")
	_assert(not richmond.is_empty(), "Richmond territory exists")
	_assert(richmond.get("is_capital", false) == true, "Richmond is capital")
	_assert(richmond.get("initial_owner", "") == "confederate", "Richmond owned by Confederate")

func test_get_all_units_for_side() -> void:
	var union_units: Array = CardDatabase.get_all_units_for_side("union")
	var all_union: bool = true
	for u in union_units:
		if u.get("side", "") != "union":
			all_union = false
			break
	_assert(all_union, "All get_all_units_for_side('union') return union units")

func test_get_adjacent_territories() -> void:
	var adj_maryland: Array = CardDatabase.get_adjacent_territories("maryland")
	_assert(adj_maryland.size() >= 2, "Maryland has >= 2 neighbors (has %d)" % adj_maryland.size())

func test_all_cards_have_required_fields() -> void:
	var required: PackedStringArray = ["id", "name_en", "side", "type", "attack", "defense", "hp", "cost", "rarity"]
	var missing: int = 0
	var all_ids: Dictionary = CardDatabase.get_all_card_ids()
	for uid in all_ids.get("units", []):
		var u: Dictionary = CardDatabase.get_unit(uid)
		for field in required:
			if not u.has(field):
				missing += 1
				break
	_assert(missing == 0, "All unit cards have required fields (missing: %d)" % missing)

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
