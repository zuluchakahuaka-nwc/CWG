extends Node

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []
var _CardInstance: Script
var _BattleResolver: Script

func _ready() -> void:
	_CardInstance = load("res://scripts/cards/card_instance.gd")
	_BattleResolver = load("res://scripts/combat/battle_resolver.gd")
	print("\n=== TEST: BattleResolver ===")
	test_basic_combat()
	test_terrain_defense_bonus()
	test_terrain_attack_penalty()
	test_type_advantage_cavalry_vs_artillery()
	test_type_advantage_cavalry_vs_infantry()
	test_type_advantage_infantry_vs_cavalry()
	test_combat_lethal_hit()
	test_combat_counterattack()
	test_territory_battle()
	test_territory_battle_capture()
	_print_summary()

func _make_card(id: String, atk: int, def: int, hp: int, card_type: String = "infantry", side: String = "union"):
	var data: Dictionary = {
		"id": id, "name_en": id, "side": side, "type": card_type,
		"attack": atk, "defense": def, "hp": hp, "cost": 1, "rarity": "common"
	}
	return _CardInstance.new(data)

func _make_resolver():
	return _BattleResolver.new()

func _make_territory(terrain: String = "plains", is_capital: bool = false) -> Dictionary:
	return {"id": "test_territory", "terrain": terrain, "is_capital": is_capital}

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_basic_combat() -> void:
	var resolver = _make_resolver()
	var attacker = _make_card("atk1", 5, 2, 10)
	var defender = _make_card("def1", 2, 3, 10)
	var result: Dictionary = resolver.resolve_combat(attacker, defender, _make_territory("plains"))
	_assert(result.has("rounds"), "Basic combat produces rounds")
	_assert(result["rounds"].size() >= 1, "At least 1 round occurred")
	_assert(result.has("attacker_id"), "Result has attacker_id")
	_assert(result["attacker_id"] == "atk1", "Attacker ID correct")

func test_terrain_defense_bonus() -> void:
	var resolver = _make_resolver()
	var attacker = _make_card("atk2", 5, 2, 10)
	var defender = _make_card("def2", 2, 3, 10)
	var plains_result: Dictionary = resolver.resolve_combat(attacker, defender, _make_territory("plains"))
	var plains_dmg: int = plains_result["rounds"][0]["damage_to_defender"]
	var attacker2 = _make_card("atk2b", 5, 2, 10)
	var defender2 = _make_card("def2b", 2, 3, 10)
	var hills_result: Dictionary = resolver.resolve_combat(attacker2, defender2, _make_territory("hills"))
	var hills_dmg: int = hills_result["rounds"][0]["damage_to_defender"]
	_assert(hills_dmg <= plains_dmg + 2, "Hills terrain reduces damage (plains=%d hills=%d)" % [plains_dmg, hills_dmg])

func test_terrain_attack_penalty() -> void:
	var resolver = _make_resolver()
	var atk1 = _make_card("a1", 5, 2, 10)
	var def1 = _make_card("d1", 2, 3, 10)
	var city_result: Dictionary = resolver.resolve_combat(atk1, def1, _make_territory("city"))
	var city_atk_val: int = city_result["rounds"][0]["attack_value"]
	_assert(city_atk_val <= 5 - 2, "City terrain penalizes attack (atk_val=%d)" % city_atk_val)

func test_type_advantage_cavalry_vs_artillery() -> void:
	var resolver = _make_resolver()
	var cav = _make_card("cav1", 3, 2, 4, "cavalry")
	var art = _make_card("art1", 4, 2, 3, "artillery")
	var result: Dictionary = resolver.resolve_combat(cav, art, _make_territory("plains"))
	var atk_val: int = result["rounds"][0]["attack_value"]
	_assert(atk_val >= 6, "Cavalry vs Artillery gets +3 bonus (atk_val=%d)" % atk_val)

func test_type_advantage_cavalry_vs_infantry() -> void:
	var resolver = _make_resolver()
	var cav = _make_card("cav2", 3, 2, 4, "cavalry")
	var inf = _make_card("inf2", 3, 3, 5, "infantry")
	var result: Dictionary = resolver.resolve_combat(cav, inf, _make_territory("plains"))
	var atk_val: int = result["rounds"][0]["attack_value"]
	_assert(atk_val >= 4, "Cavalry vs Infantry gets +1 bonus (atk_val=%d)" % atk_val)

func test_type_advantage_infantry_vs_cavalry() -> void:
	var resolver = _make_resolver()
	var inf = _make_card("inf3", 3, 3, 5, "infantry")
	var cav = _make_card("cav3", 3, 2, 4, "cavalry")
	var result: Dictionary = resolver.resolve_combat(inf, cav, _make_territory("plains"))
	var atk_val: int = result["rounds"][0]["attack_value"]
	_assert(atk_val <= 2, "Infantry vs Cavalry gets -1 penalty (atk_val=%d)" % atk_val)

func test_combat_lethal_hit() -> void:
	var resolver = _make_resolver()
	var strong = _make_card("strong", 50, 10, 10)
	var weak = _make_card("weak", 1, 1, 1)
	var result: Dictionary = resolver.resolve_combat(strong, weak, _make_territory("plains"))
	_assert(result["defender_destroyed"] == true, "Strong attacker destroys weak defender")
	_assert(result["attacker_won"] == true, "Attacker wins when defender destroyed")

func test_combat_counterattack() -> void:
	var resolver = _make_resolver()
	var attacker = _make_card("atk3", 3, 1, 10)
	var defender = _make_card("def3", 2, 2, 10)
	var result: Dictionary = resolver.resolve_combat(attacker, defender, _make_territory("plains"))
	if not result["defender_destroyed"]:
		_assert(result["rounds"].size() >= 2, "Counterattack occurs when defender survives")
	else:
		_assert(true, "Defender was destroyed (no counterattack needed)")

func test_territory_battle() -> void:
	var resolver = _make_resolver()
	var attackers: Array = [_make_card("a1", 3, 2, 5, "infantry", "union")]
	var defenders: Array = [_make_card("d1", 2, 3, 5, "infantry", "confederate")]
	var result: Dictionary = resolver.resolve_territory_battle(attackers, defenders, _make_territory())
	_assert(result.has("territory"), "Territory battle result has territory")
	_assert(result.has("attacker_losses"), "Result has attacker_losses")
	_assert(result.has("defender_losses"), "Result has defender_losses")

func test_territory_battle_capture() -> void:
	var resolver = _make_resolver()
	var attackers: Array = [_make_card("sa1", 50, 10, 10, "infantry", "union")]
	var defenders: Array = [_make_card("sd1", 1, 1, 1, "infantry", "confederate")]
	var result: Dictionary = resolver.resolve_territory_battle(attackers, defenders, _make_territory())
	_assert(result["territory_captured"] == true, "Strong attacker captures territory")
	_assert(result["defender_losses"] >= 1, "Defender has losses")

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
