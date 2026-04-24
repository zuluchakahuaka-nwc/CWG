extends "res://tests/test_base.gd"

func test_morale_range() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager.change_morale("union", 20)
	assert(GameManager.get_morale("union") == 20, "Should cap at 20")
	GameManager.change_morale("union", -50)
	assert(GameManager.get_morale("union") == -20, "Should cap at -20")

func test_morale_status() -> void:
	GameManager.start_game("civil_war", "union")
	var statuses: Dictionary = {
		15: "morale.sacred_fervor",
		10: "morale.uplift",
		5: "morale.normal",
		0: "morale.neutral",
		-5: "morale.gloom",
		-12: "morale.unrest",
		-17: "morale.rebellion"
	}
	for val in statuses:
		GameManager._morale["union"] = val
		assert(GameManager.get_morale_status("union") == statuses[val],
			"Morale " + str(val) + " should be " + statuses[val] + " got " + GameManager.get_morale_status("union"))

func test_morale_bonus_cards() -> void:
	GameManager._morale["union"] = 15
	assert(GameManager.get_morale_bonus_cards("union") == 1, "+15 should give 1 bonus card")
	GameManager._morale["union"] = 10
	assert(GameManager.get_morale_bonus_cards("union") == 1, "+10 should give 1 bonus card")
	GameManager._morale["union"] = 5
	assert(GameManager.get_morale_bonus_cards("union") == 0, "+5 should give 0 bonus cards")
	GameManager._morale["union"] = -5
	assert(GameManager.get_morale_bonus_cards("union") == 0, "-5 should give 0 bonus cards")

func test_morale_attack_bonus() -> void:
	GameManager._morale["union"] = 15
	assert(GameManager.get_morale_attack_bonus("union") == 1, "+15 should give +1 attack")
	GameManager._morale["union"] = 10
	assert(GameManager.get_morale_attack_bonus("union") == 0, "+10 should give 0 attack bonus")

func test_capital_loss() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager._morale["union"] = 0
	GameManager.set_territory_owner("washington_dc", "confederate")
	assert(GameManager.get_morale("union") == -5, "Losing DC should be -5 morale")

func test_conscription_cascade() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager.increment_conscription("union")
	GameManager.increment_conscription("union")
	GameManager.increment_conscription("union")
	assert(GameManager.get_conscription_streak("union") == 3, "Should track 3 consecutive")
	GameManager.reset_conscription("union")
	assert(GameManager.get_conscription_streak("union") == 0, "Should reset to 0")
