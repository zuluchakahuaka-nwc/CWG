extends Node
## Suite: situation & commander cards in the draw pool + their
## generalized play (owner feedback 21.11: "no situation cards").

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

func _ready() -> void:
	print("\n=== TEST: Situation play ===")
	test_deck_contains_all_card_kinds()
	test_deck_excludes_battle_wired()
	test_play_buff_artillery()
	test_play_destroy_enemy_unit()
	test_play_morale_and_draw()
	test_play_commander()
	test_needs_enemy_land_routing()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_deck_contains_all_card_kinds() -> void:
	var deck = load("res://scripts/cards/deck.gd").new()
	deck.build_deck("union")
	var cards: Array = deck._cards
	var kinds: Dictionary = {"unit": 0, "situation": 0, "commander": 0}
	for c in cards:
		if SituationPlay.is_commander_card(c):
			kinds["commander"] += 1
		elif String(c.get("type", "")) == "situation" or String(c.get("type", "")) == "event":
			kinds["situation"] += 1
		else:
			kinds["unit"] += 1
	_assert(cards.size() > 100, "union deck is substantial (%d cards)" % cards.size())
	_assert(kinds.get("unit", 0) > 50, "deck holds unit cards (%d)" % kinds.get("unit", 0))
	_assert(kinds.get("situation", 0) > 10, "deck holds situation cards (%d)" % kinds.get("situation", 0))
	_assert(kinds.get("commander", 0) == 12, "deck holds all 12 union commanders (%d)" % kinds.get("commander", 0))

func test_deck_excludes_battle_wired() -> void:
	var deck = load("res://scripts/cards/deck.gd").new()
	deck.build_deck("union")
	var has_battle_wired: bool = false
	for c in deck._cards:
		if String(c.get("effect_mechanic", "")) == "CAPTURE_TARGET":
			has_battle_wired = true
			break
	_assert(not has_battle_wired, "battle-wired events (CAPTURE_TARGET etc) stay out of the deck")

func test_play_buff_artillery() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager._units_on_map.erase("washington_dc")
	var art_data: Dictionary = {}
	for u in CardDatabase.get_all_units_for_side("union"):
		if String(u.get("type", "")) == "artillery":
			art_data = u
			break
	if art_data.is_empty():
		_assert(false, "union artillery unit exists in database")
		return
	var card = load("res://scripts/cards/card_instance.gd").new(art_data)
	GameManager._units_on_map["washington_dc"] = [card]
	var atk_before: int = card.attack
	var sit: Dictionary = CardDatabase.get_situation("SIT_ARTY_BARRAGE")
	var result: Dictionary = SituationPlay.play(sit, "union", "washington_dc", {"union": [], "confederate": []})
	_assert(bool(result.get("ok", false)), "artillery barrage plays: %s" % String(result.get("telemetry", "")))
	_assert(card.attack == atk_before + 2, "artillery gains +2 ATK (%d -> %d)" % [atk_before, card.attack])

func test_play_destroy_enemy_unit() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager._units_on_map.erase("virginia_north")
	var enemy = load("res://scripts/cards/card_instance.gd").new(CardDatabase.get_all_units_for_side("confederate")[0])
	GameManager._units_on_map["virginia_north"] = [enemy]
	var sit: Dictionary = CardDatabase.get_situation("EVENT_CUSHING_TORPEDO")
	var result: Dictionary = SituationPlay.play(sit, "union", "virginia_north", {"union": [], "confederate": []})
	_assert(bool(result.get("ok", false)), "destroy plays: %s" % String(result.get("telemetry", "")))
	_assert(not GameManager._units_on_map.has("virginia_north"), "enemy unit removed from the territory")

func test_play_morale_and_draw() -> void:
	GameManager.start_game("civil_war", "union")
	var morale_before: int = GameManager.get_morale("union")
	var hands: Dictionary = {"union": [], "confederate": []}
	var sit: Dictionary = CardDatabase.get_situation("SIT_VOLUNTEERS")
	var result: Dictionary = SituationPlay.play(sit, "union", "pennsylvania", hands)
	_assert(bool(result.get("ok", false)), "volunteers plays: %s" % String(result.get("telemetry", "")))
	_assert(GameManager.get_morale("union") == morale_before + 1, "morale +1 (%d -> %d)" % [morale_before, GameManager.get_morale("union")])
	_assert(hands["union"].size() == 2, "drew 2 cards into hand (%d)" % hands["union"].size())

func test_play_commander() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager._units_on_map.erase("washington_dc")
	var inf = load("res://scripts/cards/card_instance.gd").new(CardDatabase.get_all_units_for_side("union")[0])
	GameManager._units_on_map["washington_dc"] = [inf]
	var atk_before: int = inf.attack
	var cmd: Dictionary = {}
	for c in CardDatabase.get_all_commanders_for_side("union"):
		if String(c.get("id", "")) == "cmd_grant":
			cmd = c
			break
	if cmd.is_empty():
		_assert(false, "cmd_grant exists")
		return
	var result: Dictionary = SituationPlay.play(cmd, "union", "washington_dc", {"union": [], "confederate": []})
	_assert(bool(result.get("ok", false)), "commander plays: %s" % String(result.get("telemetry", "")))
	_assert(inf.attack == atk_before + 1, "commanded unit gains +1 ATK")

func test_needs_enemy_land_routing() -> void:
	var destroy_card: Dictionary = CardDatabase.get_situation("EVENT_CUSHING_TORPEDO")
	var buff_card: Dictionary = CardDatabase.get_situation("SIT_ARTY_BARRAGE")
	_assert(SituationPlay.needs_enemy_land(destroy_card), "destroy card targets enemy land")
	_assert(not SituationPlay.needs_enemy_land(buff_card), "buff card targets own land")
	var cmd: Dictionary = CardDatabase.get_all_commanders_for_side("union")[0]
	_assert(not SituationPlay.needs_enemy_land(cmd), "commander targets own land")
	_assert(SituationPlay.is_playable(cmd), "commanders are playable")

func _print_summary() -> void:
	for line in _test_results:
		print(line)
	print("=== SITUATION PLAY: %d passed, %d failed ===" % [_pass_count, _fail_count])
