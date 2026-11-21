extends Node
## Suite: placement law (owner feedback 21.11) - recruits deploy only onto
## OWN or NEUTRAL land; enemy land is conquered in battle / by moving in.
## Bloodless capture lives in GameManager and applies to every side alike.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

func _ready() -> void:
	print("\n=== TEST: Placement law ===")
	test_can_side_place_matrix()
	test_bloodless_capture_neutral()
	test_bloodless_capture_blocked_by_defenders()
	test_bloodless_capture_own_land_noop()
	test_bloodless_capture_enemy_land_via_move()
	test_bloodless_capture_capital_morale()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func _make_unit(side: String, territory: String) -> RefCounted:
	var data: Dictionary = CardDatabase.get_all_units_for_side(side)[0]
	var card = load("res://scripts/cards/card_instance.gd").new(data)
	card.territory_id = territory
	if not GameManager._units_on_map.has(territory):
		GameManager._units_on_map[territory] = []
	GameManager._units_on_map[territory].append(card)
	return card

func test_can_side_place_matrix() -> void:
	GameManager.start_game("civil_war", "union")
	_assert(GameManager.can_side_place("union", "pennsylvania"), "own territory: placement allowed")
	_assert(GameManager.can_side_place("union", "kentucky"), "neutral territory: placement allowed")
	_assert(not GameManager.can_side_place("union", "virginia_north"), "enemy territory: placement DENIED")
	_assert(not GameManager.can_side_place("confederate", "pennsylvania"), "enemy territory (confed view): placement DENIED")
	_assert(GameManager.can_side_place("confederate", "kentucky"), "neutral territory (confed view): placement allowed")

func test_bloodless_capture_neutral() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager.set_territory_owner("kentucky", "neutral")
	GameManager._units_on_map.erase("kentucky")
	_make_unit("union", "kentucky")
	var captured: bool = GameManager.try_bloodless_capture("kentucky", "union")
	_assert(captured, "neutral garrisoned by union without defenders is captured")
	_assert(GameManager.get_territory_owner("kentucky") == "union", "kentucky owner flips to union")

func test_bloodless_capture_blocked_by_defenders() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager.set_territory_owner("kentucky", "neutral")
	GameManager._units_on_map.erase("kentucky")
	_make_unit("union", "kentucky")
	_make_unit("confederate", "kentucky")
	var captured: bool = GameManager.try_bloodless_capture("kentucky", "union")
	_assert(not captured, "contested neutral land (enemy unit present) is NOT captured")
	_assert(GameManager.get_territory_owner("kentucky") == "neutral", "kentucky stays neutral while contested")

func test_bloodless_capture_own_land_noop() -> void:
	GameManager.start_game("civil_war", "union")
	_assert(not GameManager.try_bloodless_capture("pennsylvania", "union"), "own land: capture is a no-op")
	_assert(GameManager.get_territory_owner("pennsylvania") == "union", "pennsylvania stays union")

func test_bloodless_capture_enemy_land_via_move() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager._units_on_map.erase("virginia_north")
	_make_unit("union", "virginia_north")
	var captured: bool = GameManager.try_bloodless_capture("virginia_north", "union")
	_assert(captured, "undefended enemy land flips when union units move in")
	_assert(GameManager.get_territory_owner("virginia_north") == "union", "virginia_north owner flips to union")

func test_bloodless_capture_capital_morale() -> void:
	GameManager.start_game("civil_war", "union")
	var union_morale_before: int = GameManager.get_morale("union")
	var confed_morale_before: int = GameManager.get_morale("confederate")
	GameManager._units_on_map.erase("richmond")
	_make_unit("union", "richmond")
	var captured: bool = GameManager.try_bloodless_capture("richmond", "union")
	_assert(captured, "undefended capital flips to union")
	_assert(GameManager.get_morale("union") == union_morale_before + 5, "capturing Richmond: union morale +5")
	_assert(GameManager.get_morale("confederate") == confed_morale_before - 5, "losing Richmond: confederate morale -5")

func _print_summary() -> void:
	for line in _test_results:
		print(line)
	print("=== PLACEMENT LAW: %d passed, %d failed ===" % [_pass_count, _fail_count])
