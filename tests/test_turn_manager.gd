extends "res://tests/test_base.gd"

func test_turn_starts_at_1() -> void:
	GameManager.start_game("civil_war", "union")
	assert(GameManager.get_current_turn() == 1, "Should start at turn 1")

func test_phase_order() -> void:
	GameManager.start_game("civil_war", "union")
	var phases: Array = [
		GameManager.Phase.RESOURCES,
		GameManager.Phase.DRAW,
		GameManager.Phase.MOVEMENT,
		GameManager.Phase.COMBAT,
		GameManager.Phase.EVENTS,
		GameManager.Phase.END
	]
	for expected in phases:
		assert(GameManager.get_current_phase() == expected,
			"Phase should be " + str(expected) + " got " + str(GameManager.get_current_phase()))
		GameManager.advance_phase()

func test_turn_advances() -> void:
	GameManager.start_game("civil_war", "union")
	for i in range(6):
		GameManager.advance_phase()
	assert(GameManager.get_current_turn() == 2, "After 6 phases should be turn 2")

func test_max_turns() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager._current_turn = 49
	for i in range(6):
		GameManager.advance_phase()
	assert(GameManager.get_current_turn() <= 49, "Should not exceed max turns")

func test_player_side() -> void:
	GameManager.start_game("civil_war", "union")
	assert(GameManager.get_player_side() == "union", "Player should be union")
	assert(GameManager.get_ai_side() == "confederate", "AI should be confederate")
	GameManager.start_game("civil_war", "confederate")
	assert(GameManager.get_player_side() == "confederate", "Player should be confederate")
	assert(GameManager.get_ai_side() == "union", "AI should be union")

func test_serialize_deserialize() -> void:
	GameManager.start_game("civil_war", "union")
	GameManager.change_morale("union", 5)
	GameManager._current_turn = 10
	var data: Dictionary = GameManager.serialize()
	assert(data["turn"] == 10, "Serialized turn should be 10")
	assert(data["morale"]["union"] == 5, "Serialized union morale should be 5")
	GameManager.start_game("civil_war", "confederate")
	GameManager.deserialize(data)
	assert(GameManager.get_current_turn() == 10, "Deserialized turn should be 10")
	assert(GameManager.get_morale("union") == 5, "Deserialized union morale should be 5")
	assert(GameManager.get_player_side() == "union", "Deserialized player side should be union")
