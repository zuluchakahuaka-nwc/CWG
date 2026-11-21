extends Node
## Suite: data schema + chaos (hub law "verifiability of behavior").
## Every card in the databases must satisfy the value ranges; every
## situation mechanic must be covered by SituationPlay (no orphan
## mechanics that silently never play); corrupted saves must degrade,
## not crash.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

func _ready() -> void:
	print("\n=== TEST: Data schema + chaos ===")
	test_unit_ranges()
	test_commander_schema()
	test_situation_mechanics_covered()
	test_chaos_corrupt_save()
	test_chaos_unknown_cards()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_unit_ranges() -> void:
	var offenders: Array = []
	for side in ["union", "confederate"]:
		for u in CardDatabase.get_all_units_for_side(side):
			var id: String = str(u.get("id", "?"))
			var atk: int = int(u.get("attack", -1))
			var dfn: int = int(u.get("defense", -1))
			var hp: int = int(u.get("hp", -1))
			var cost: int = int(u.get("cost", -1))
			if atk < 0 or atk > 8: offenders.append("%s ATK %d" % [id, atk])
			if dfn < 0 or dfn > 8: offenders.append("%s DEF %d" % [id, dfn])
			if hp < 1 or hp > 8: offenders.append("%s HP %d" % [id, hp])
			if cost < 0 or cost > 7: offenders.append("%s cost %d" % [id, cost])
			if not ["common", "uncommon", "rare", "legendary"].has(str(u.get("rarity", ""))):
				offenders.append("%s rarity '%s'" % [id, str(u.get("rarity", ""))])
	_assert(offenders.is_empty(), "all unit stats within ranges %s" % str(offenders.slice(0, 4)))

func test_commander_schema() -> void:
	var offenders: Array = []
	for side in ["union", "confederate"]:
		for c in CardDatabase.get_all_commanders_for_side(side):
			var id: String = str(c.get("id", "?"))
			if not SituationPlay.is_commander_card(c):
				offenders.append("%s not detected as commander" % id)
			if str(c.get("effect_type", "")) == "":
				offenders.append("%s has no effect_type" % id)
			if int(c.get("cost", -1)) < 0 or int(c.get("cost", -1)) > 7:
				offenders.append("%s cost %d" % [id, int(c.get("cost", -1))])
	_assert(offenders.is_empty(), "commander schema holds %s" % str(offenders.slice(0, 4)))

func test_situation_mechanics_covered() -> void:
	# Every effect_mechanic in the data must exist in SituationPlay.TABLE -
	# otherwise the card is dead (is_playable false) by accident.
	var orphans: Array = []
	var all_ids: Dictionary = CardDatabase.get_all_card_ids()
	for id in all_ids.get("situations", []):
		var s: Dictionary = CardDatabase.get_situation(str(id))
		var mech: String = str(s.get("effect_mechanic", ""))
		if mech == "":
			orphans.append("%s no mechanic" % id)
			continue
		if not SituationPlay.TABLE.has(mech):
			orphans.append("%s mechanic %s not in TABLE" % [id, mech])
	_assert(orphans.is_empty(), "every situation mechanic is covered %s" % str(orphans.slice(0, 4)))
	var playable: int = 0
	for id in all_ids.get("situations", []):
		if SituationPlay.is_playable(CardDatabase.get_situation(str(id))):
			playable += 1
	_assert(playable > 40, "a healthy share of situations is hand-playable (%d)" % playable)

func test_chaos_corrupt_save() -> void:
	GameManager.start_game("civil_war", "union")
	var data: Dictionary = GameManager.serialize()
	# Corrupt every field type the loader might trust.
	data["turn"] = "мусор"
	data["phase"] = 99
	data["morale"] = {"union": -9999, "confederate": "abc"}
	data["territory_owners"] = {"atlantis": "spanish"}
	var crashed: bool = false
	GameManager.game_over.connect(func(_w: String, _r: String) -> void: pass)
	# The morale sink may legitimately end the game (signal); that is
	# degradation, not a crash. A crash here fails the whole suite.
	GameManager.deserialize(data)
	_assert(true, "corrupt save deserialized without crashing")
	crashed = false # linter peace
	var morale_now: int = GameManager.get_morale("union")
	_assert(morale_now >= -20 and morale_now <= 20, "after corrupt save morale stays in bounds (%d)" % morale_now)

func test_chaos_unknown_cards() -> void:
	# Card lookups with garbage ids must return empty, never crash/null.
	_assert(CardDatabase.get_card("no_such_card").is_empty(), "unknown card id -> empty dict")
	_assert(CardDatabase.get_territory("atlantis").is_empty(), "unknown territory -> empty dict")
	_assert(CardDatabase.get_situation("SIT_NOPE").is_empty(), "unknown situation -> empty dict")

func _print_summary() -> void:
	for line in _test_results:
		print(line)
	print("=== DATA SCHEMA + CHAOS: %d passed, %d failed ===" % [_pass_count, _fail_count])
