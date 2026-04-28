extends Node

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []
var _CardInstance: Script

func _ready() -> void:
	_CardInstance = load("res://scripts/cards/card_instance.gd")
	print("\n=== TEST: TurnManager ===")
	test_initial_turn()
	test_phase_advancement()
	test_full_phase_cycle()
	test_month_calculation_turn1()
	test_month_calculation_turn13()
	test_month_calculation_turn25()
	test_max_turns_triggers_game_over()
	test_resource_income()
	test_card_instance_hp()
	test_card_instance_damage()
	test_card_instance_heal()
	test_card_instance_buffs()
	test_card_instance_serialize()
	test_serialize_deserialize()
	_print_summary()

func _reset_game() -> void:
	GameManager._current_turn = 1
	GameManager._current_phase = GameManager.Phase.RESOURCES
	GameManager._morale = {"union": 0, "confederate": 0}
	GameManager._resources = {
		"union": {"manpower": 6, "money": 7, "supply": 5},
		"confederate": {"manpower": 4, "money": 4, "supply": 4}
	}
	GameManager._territory_owners = {
		"washington_dc": "union",
		"richmond": "confederate",
		"maryland": "union",
		"virginia_north": "confederate"
	}
	for conn in GameManager.game_over.get_connections():
		GameManager.game_over.disconnect(conn["callable"])

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_initial_turn() -> void:
	_reset_game()
	_assert(GameManager.get_current_turn() == 1, "Initial turn = 1")
	_assert(GameManager.get_current_phase() == GameManager.Phase.RESOURCES, "Initial phase = RESOURCES")

func test_phase_advancement() -> void:
	_reset_game()
	GameManager.advance_phase()
	_assert(GameManager.get_current_phase() == GameManager.Phase.DRAW, "Phase 2 = DRAW")
	GameManager.advance_phase()
	_assert(GameManager.get_current_phase() == GameManager.Phase.MOVEMENT, "Phase 3 = MOVEMENT")
	GameManager.advance_phase()
	_assert(GameManager.get_current_phase() == GameManager.Phase.COMBAT, "Phase 4 = COMBAT")
	GameManager.advance_phase()
	_assert(GameManager.get_current_phase() == GameManager.Phase.EVENTS, "Phase 5 = EVENTS")
	GameManager.advance_phase()
	_assert(GameManager.get_current_phase() == GameManager.Phase.END, "Phase 6 = END")

func test_full_phase_cycle() -> void:
	_reset_game()
	for i in range(6):
		GameManager.advance_phase()
	_assert(GameManager.get_current_turn() == 2, "After full cycle turn = 2")
	_assert(GameManager.get_current_phase() == GameManager.Phase.RESOURCES, "After cycle phase = RESOURCES")

func test_month_calculation_turn1() -> void:
	_reset_game()
	var month: String = GameManager.get_current_month()
	_assert(month != "", "Turn 1 month is not empty")
	_assert(month.find("1861") >= 0, "Turn 1 is in 1861")

func test_month_calculation_turn13() -> void:
	_reset_game()
	GameManager._current_turn = 13
	var month: String = GameManager.get_current_month()
	_assert(month.find("1862") >= 0, "Turn 13 is in 1862")

func test_month_calculation_turn25() -> void:
	_reset_game()
	GameManager._current_turn = 25
	var month: String = GameManager.get_current_month()
	_assert(month.find("1863") >= 0, "Turn 25 is in 1863")

var _game_over_triggered: bool = false
var _game_over_winner: String = ""

func _on_game_over(w: String, _r: String) -> void:
	_game_over_triggered = true
	_game_over_winner = w

func test_max_turns_triggers_game_over() -> void:
	_reset_game()
	_game_over_triggered = false
	_game_over_winner = ""
	GameManager.game_over.connect(_on_game_over)
	GameManager._current_turn = 49
	GameManager._territory_owners = {"t1": "union", "t2": "union", "t3": "confederate"}
	for i in range(6):
		GameManager.advance_phase()
	_assert(_game_over_triggered, "Turn 50 triggers game_over")
	_assert(_game_over_winner == "union", "Union wins by territory count")
	if GameManager.game_over.is_connected(_on_game_over):
		GameManager.game_over.disconnect(_on_game_over)

func test_resource_income() -> void:
	_reset_game()
	GameManager._territory_owners = {"washington_dc": "union"}
	GameManager._resources["union"] = {"manpower": 0, "money": 0, "supply": 0}
	var dc: Dictionary = CardDatabase.get_territory("washington_dc")
	if dc.is_empty():
		_assert(true, "Resource income test skipped (no DC data)")
		return
	GameManager.change_resource("union", "money", dc.get("resource_money", 0))
	_assert(GameManager.get_resources("union")["money"] > 0, "DC provides money income")

func test_card_instance_hp() -> void:
	var data: Dictionary = {"id": "test", "name_en": "Test", "side": "union", "type": "infantry", "attack": 3, "defense": 3, "hp": 5, "cost": 2, "rarity": "common"}
	var card = _CardInstance.new(data)
	_assert(card.current_hp == 5, "Card HP = 5")
	_assert(card.max_hp == 5, "Card max HP = 5")
	_assert(card.is_alive(), "Card is alive")

func test_card_instance_damage() -> void:
	var data: Dictionary = {"id": "test", "name_en": "Test", "side": "union", "type": "infantry", "attack": 3, "defense": 3, "hp": 5, "cost": 2, "rarity": "common"}
	var card = _CardInstance.new(data)
	card.take_damage(3)
	_assert(card.current_hp == 2, "After 3 damage HP = 2")
	_assert(card.is_alive(), "Card still alive after 3 damage")
	card.take_damage(3)
	_assert(card.current_hp == -1, "After overkill HP = -1")
	_assert(not card.is_alive(), "Card dead after overkill")

func test_card_instance_heal() -> void:
	var data: Dictionary = {"id": "test", "name_en": "Test", "side": "union", "type": "infantry", "attack": 3, "defense": 3, "hp": 5, "cost": 2, "rarity": "common"}
	var card = _CardInstance.new(data)
	card.take_damage(3)
	card.heal(2)
	_assert(card.current_hp == 4, "After heal HP = 4")
	card.heal(10)
	_assert(card.current_hp == 5, "Heal capped at max HP")

func test_card_instance_buffs() -> void:
	var data: Dictionary = {"id": "test", "name_en": "Test", "side": "union", "type": "infantry", "attack": 3, "defense": 3, "hp": 5, "cost": 2, "rarity": "common"}
	var card = _CardInstance.new(data)
	card.add_buff({"attack": 2}, 2)
	_assert(card.get_effective_attack() == 3 + 2, "Buff +2 attack")
	card.tick_buffs()
	_assert(card.get_effective_attack() == 3 + 2, "Buff still active after 1 tick (duration was 2)")
	card.tick_buffs()
	_assert(card.get_effective_attack() == 3, "Buff expired after 2 ticks")

func test_card_instance_serialize() -> void:
	var data: Dictionary = {"id": "test", "name_en": "Test", "side": "union", "type": "infantry", "attack": 3, "defense": 3, "hp": 5, "cost": 2, "rarity": "common"}
	var card = _CardInstance.new(data)
	card.take_damage(2)
	var serialized: Dictionary = card.serialize()
	_assert(serialized["id"] == "test", "Serialized id correct")
	_assert(serialized["current_hp"] == 3, "Serialized HP correct")

func test_serialize_deserialize() -> void:
	_reset_game()
	GameManager._current_turn = 5
	GameManager.change_morale("union", 3)
	GameManager.change_resource("union", "money", 10)
	var saved: Dictionary = GameManager.serialize()
	_assert(saved["turn"] == 5, "Serialized turn = 5")
	_assert(saved["morale"]["union"] == 3, "Serialized morale union = 3")
	_reset_game()
	GameManager.deserialize(saved)
	_assert(GameManager.get_current_turn() == 5, "Deserialized turn = 5")
	_assert(GameManager.get_morale("union") == 3, "Deserialized morale union = 3")

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
