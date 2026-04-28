extends Node

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

func _ready() -> void:
	print("\n=== TEST: MoraleSystem ===")
	test_initial_morale()
	test_morale_change_positive()
	test_morale_change_negative()
	test_morale_clamp_max()
	test_morale_clamp_min()
	test_morale_collapse_triggers_game_over()
	test_morale_status_sacred_fervor()
	test_morale_status_uplift()
	test_morale_status_normal()
	test_morale_status_gloom()
	test_morale_status_unrest()
	test_morale_status_rebellion()
	test_morale_status_revolution()
	test_morale_bonus_cards_sacred()
	test_morale_bonus_cards_uplift()
	test_morale_bonus_cards_normal()
	test_morale_attack_bonus()
	test_conscription_streak()
	test_capital_loss_morale()
	_print_summary()

func _reset_game() -> void:
	for conn in GameManager.game_over.get_connections():
		GameManager.game_over.disconnect(conn["callable"])
	GameManager._morale = {"union": 0, "confederate": 0}
	GameManager._resources = {
		"union": {"manpower": 6, "money": 7, "supply": 5},
		"confederate": {"manpower": 4, "money": 4, "supply": 4}
	}
	GameManager._territory_owners = {
		"washington_dc": "union",
		"richmond": "confederate"
	}

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_initial_morale() -> void:
	_reset_game()
	_assert(GameManager.get_morale("union") == 0, "Union starts at 0 morale")
	_assert(GameManager.get_morale("confederate") == 0, "Confederate starts at 0 morale")

func test_morale_change_positive() -> void:
	_reset_game()
	GameManager.change_morale("union", 5)
	_assert(GameManager.get_morale("union") == 5, "Union morale +5 = 5")

func test_morale_change_negative() -> void:
	_reset_game()
	GameManager.change_morale("confederate", -7)
	_assert(GameManager.get_morale("confederate") == -7, "Confederate morale -7 = -7")

func test_morale_clamp_max() -> void:
	_reset_game()
	GameManager.change_morale("union", 50)
	_assert(GameManager.get_morale("union") == 20, "Morale clamped at +20")

func test_morale_clamp_min() -> void:
	_reset_game()
	GameManager.change_morale("union", -50)
	_assert(GameManager.get_morale("union") == -20, "Morale clamped at -20")

var _game_over_triggered: bool = false
var _game_over_winner: String = ""

func _on_game_over(w: String, _r: String) -> void:
	_game_over_triggered = true
	_game_over_winner = w

func test_morale_collapse_triggers_game_over() -> void:
	_reset_game()
	_game_over_triggered = false
	_game_over_winner = ""
	GameManager.game_over.connect(_on_game_over)
	GameManager._morale["union"] = -19
	GameManager.change_morale("union", -1)
	_assert(_game_over_triggered, "Morale -20 triggers game_over signal")
	_assert(_game_over_winner == "confederate", "Confederate wins when Union morale collapses")
	if GameManager.game_over.is_connected(_on_game_over):
		GameManager.game_over.disconnect(_on_game_over)

func test_morale_status_sacred_fervor() -> void:
	_reset_game()
	GameManager.change_morale("union", 15)
	_assert(GameManager.get_morale_status("union") == "morale.sacred_fervor", "+15 = sacred_fervor")

func test_morale_status_uplift() -> void:
	_reset_game()
	GameManager.change_morale("union", 10)
	_assert(GameManager.get_morale_status("union") == "morale.uplift", "+10 = uplift")

func test_morale_status_normal() -> void:
	_reset_game()
	GameManager.change_morale("union", 5)
	_assert(GameManager.get_morale_status("union") == "morale.normal", "+5 = normal")

func test_morale_status_gloom() -> void:
	_reset_game()
	GameManager.change_morale("union", -5)
	_assert(GameManager.get_morale_status("union") == "morale.gloom", "-5 = gloom")

func test_morale_status_unrest() -> void:
	_reset_game()
	GameManager.change_morale("union", -10)
	_assert(GameManager.get_morale_status("union") == "morale.unrest", "-10 = unrest")

func test_morale_status_rebellion() -> void:
	_reset_game()
	GameManager.change_morale("union", -15)
	_assert(GameManager.get_morale_status("union") == "morale.rebellion", "-15 = rebellion")

func test_morale_status_revolution() -> void:
	_reset_game()
	GameManager.change_morale("confederate", -19)
	_assert(GameManager.get_morale_status("confederate") == "morale.rebellion", "-19 = rebellion (not revolution)")

func test_morale_bonus_cards_sacred() -> void:
	_reset_game()
	GameManager.change_morale("union", 16)
	_assert(GameManager.get_morale_bonus_cards("union") == 1, "Sacred fervor gives +1 card")

func test_morale_bonus_cards_uplift() -> void:
	_reset_game()
	GameManager.change_morale("union", 12)
	_assert(GameManager.get_morale_bonus_cards("union") == 1, "Uplift gives +1 card")

func test_morale_bonus_cards_normal() -> void:
	_reset_game()
	_assert(GameManager.get_morale_bonus_cards("union") == 0, "Normal morale gives 0 bonus cards")

func test_morale_attack_bonus() -> void:
	_reset_game()
	GameManager.change_morale("union", 14)
	_assert(GameManager.get_morale_attack_bonus("union") == 0, "Uplift gives no attack bonus")
	_reset_game()
	GameManager.change_morale("union", 15)
	_assert(GameManager.get_morale_attack_bonus("union") == 1, "Sacred fervor gives +1 attack")

func test_conscription_streak() -> void:
	_reset_game()
	_assert(GameManager.get_conscription_streak("union") == 0, "Initial streak = 0")
	GameManager.increment_conscription("union")
	GameManager.increment_conscription("union")
	GameManager.increment_conscription("union")
	_assert(GameManager.get_conscription_streak("union") == 3, "After 3 conscriptions streak = 3")
	GameManager.reset_conscription("union")
	_assert(GameManager.get_conscription_streak("union") == 0, "After reset streak = 0")

func test_capital_loss_morale() -> void:
	_reset_game()
	GameManager._territory_owners["washington_dc"] = "union"
	GameManager.set_territory_owner("washington_dc", "confederate")
	_assert(GameManager.get_morale("union") == -5, "Losing DC = -5 morale for Union")
	_reset_game()
	GameManager._territory_owners["richmond"] = "confederate"
	GameManager.set_territory_owner("richmond", "union")
	_assert(GameManager.get_morale("confederate") == -5, "Losing Richmond = -5 morale for Confederate")

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
