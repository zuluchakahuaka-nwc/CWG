extends Node

var _test_passed: int = 0
var _test_failed: int = 0
var _log: String = ""
var _started: bool = false

func _process(_delta: float) -> void:
	if _started:
		return
	_started = true
	Logger.info("TestGame", "=== FULL GAME CYCLE TEST ===")
	_test_full_game()
	Logger.info("TestGame", "=== TEST COMPLETE: %d passed, %d failed ===" % [_test_passed, _test_failed])
	Logger.info("TestGame", _log)
	get_tree().quit()

func _pass(condition: bool, msg: String) -> void:
	if condition:
		_test_passed += 1
		_log += "  PASS: %s\n" % msg
	else:
		_test_failed += 1
		_log += "  FAIL: %s\n" % msg

func _test_full_game() -> void:
	_test_start_game()
	_test_resources()
	_test_draw()
	_test_placement()
	_test_movement()
	_test_combat()
	_test_multi_turn()

func _test_start_game() -> void:
	Logger.info("TestGame", "--- Start Game ---")
	GameManager.start_game("civil_war", "union")
	_pass(GameManager.get_current_turn() == 1, "Turn=1")
	_pass(GameManager.get_current_phase() == 0, "Phase=RESOURCES")
	_pass(GameManager.get_territory_owner("washington_dc") == "union", "DC=union")
	_pass(GameManager.get_territory_owner("richmond") == "confederate", "Richmond=confed")
	_pass(GameManager.get_territory_owner("kentucky") == "neutral", "KY=neutral")

func _test_resources() -> void:
	Logger.info("TestGame", "--- Resources ---")
	var before_u: int = GameManager.get_resources("union")["money"]
	for side in ["union", "confederate"]:
		for t_id in GameManager._territory_owners:
			if GameManager._territory_owners[t_id] == side:
				var t: Dictionary = CardDatabase.get_territory(t_id)
				GameManager.change_resource(side, "money", t.get("resource_money", 0))
	var after_u: int = GameManager.get_resources("union")["money"]
	_pass(after_u > before_u, "Union money %d->%d" % [before_u, after_u])

func _test_draw() -> void:
	Logger.info("TestGame", "--- Draw Cards ---")
	var ci = load("res://scripts/cards/card_instance.gd")
	for side in ["union", "confederate"]:
		var all: Array = CardDatabase.get_all_units_for_side(side)
		_pass(all.size() > 0, "%s has %d cards" % [side, all.size()])
		var card = ci.new(all[0])
		_pass(card.attack >= 0, "%s card ATK=%d" % [side, card.attack])
		_pass(card.max_hp > 0, "%s card HP=%d" % [side, card.max_hp])

func _test_placement() -> void:
	Logger.info("TestGame", "--- Place Units ---")
	var ci = load("res://scripts/cards/card_instance.gd")
	var u_all: Array = CardDatabase.get_all_units_for_side("union")
	var c_all: Array = CardDatabase.get_all_units_for_side("confederate")
	var u_card = ci.new(u_all[0])
	u_card.territory_id = "washington_dc"
	GameManager._units_on_map["washington_dc"] = [u_card]
	var c_card = ci.new(c_all[0])
	c_card.territory_id = "richmond"
	GameManager._units_on_map["richmond"] = [c_card]
	_pass(GameManager._units_on_map["washington_dc"].size() == 1, "1 unit at DC")
	_pass(GameManager._units_on_map["richmond"].size() == 1, "1 unit at Richmond")

func _test_movement() -> void:
	Logger.info("TestGame", "--- Movement ---")
	var adj: Array = CardDatabase.get_adjacent_territories("washington_dc")
	_pass(adj.size() > 0, "DC has %d neighbors" % adj.size())
	var ci = load("res://scripts/cards/card_instance.gd")
	var u_all: Array = CardDatabase.get_all_units_for_side("union")
	var card = ci.new(u_all[1])
	card.territory_id = "pennsylvania"
	GameManager._units_on_map["pennsylvania"] = [card]
	var pa_adj: Array = CardDatabase.get_adjacent_territories("pennsylvania")
	_pass(pa_adj.size() > 0, "PA has %d neighbors" % pa_adj.size())

func _test_combat() -> void:
	Logger.info("TestGame", "--- Combat ---")
	var ci = load("res://scripts/cards/card_instance.gd")
	var u_all: Array = CardDatabase.get_all_units_for_side("union")
	var c_all: Array = CardDatabase.get_all_units_for_side("confederate")
	var attacker = ci.new(u_all[0])
	var defender = ci.new(c_all[0])
	var t_data: Dictionary = CardDatabase.get_territory("virginia_north")
	var resolver = load("res://scripts/combat/battle_resolver.gd").new()
	var result: Dictionary = resolver.resolve_combat(attacker, defender, t_data)
	_pass(result.has("rounds"), "Combat has rounds")
	_pass(result["rounds"].size() >= 1, "1+ round fought")
	_pass(result.has("defender_destroyed") or result.has("attacker_destroyed"), "Combat resolved")

func _test_multi_turn() -> void:
	Logger.info("TestGame", "--- 5 Turns ---")
	var ci = load("res://scripts/cards/card_instance.gd")
	for t in range(5):
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		for side in ["union", "confederate"]:
			var all: Array = CardDatabase.get_all_units_for_side(side)
			var owned: Array = []
			for tid in GameManager._territory_owners:
				if GameManager._territory_owners[tid] == side:
					owned.append(tid)
			if not owned.is_empty():
				var target = owned[randi() % owned.size()]
				var card = ci.new(all[randi() % all.size()])
				card.territory_id = target
				if not GameManager._units_on_map.has(target):
					GameManager._units_on_map[target] = []
				GameManager._units_on_map[target].append(card)
	var total: int = 0
	for tid in GameManager._units_on_map:
		total += GameManager._units_on_map[tid].size()
	_pass(total > 0, "%d units on map after 5 turns" % total)
	_pass(GameManager.get_current_turn() >= 6, "Turn=%d" % GameManager.get_current_turn())
	var ur: Dictionary = GameManager.get_resources("union")
	_pass(ur["money"] > 0, "Union money=%d" % ur["money"])
	Logger.info("TestGame", "Final: Turn=%d Units=%d U_res=%s" % [GameManager.get_current_turn(), total, str(ur)])
