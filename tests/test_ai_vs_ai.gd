extends Node

var _ai_union: Node
var _ai_confed: Node
var _turn: int = 0
var _max_turns: int = 15

func _ready() -> void:
	_ai_union = Node.new()
	_ai_union.set_script(load("res://scripts/ai/ai_controller.gd"))
	_ai_union.set_side("union")
	add_child(_ai_union)

	_ai_confed = Node.new()
	_ai_confed.set_script(load("res://scripts/ai/ai_controller.gd"))
	_ai_confed.set_side("confederate")
	add_child(_ai_confed)

func _process(_delta: float) -> void:
	set_process(false)
	_run_test()

func _run_test() -> void:
	Logger.info("TEST", "============================================")
	Logger.info("TEST", "  AI vs AI STRESS TEST - 15 TURNS")
	Logger.info("TEST", "============================================")

	GameManager.start_game("civil_war", "union")

	var shared_hands: Dictionary = {"union": [], "confederate": []}
	_ai_union.set_hands(shared_hands)
	_ai_confed.set_hands(shared_hands)

	for turn in range(1, _max_turns + 1):
		_turn = turn
		var month: String = GameManager.get_current_month()
		Logger.info("TEST", "")
		Logger.info("TEST", "====== TURN %d | %s ======" % [turn, month])

		for side in ["union", "confederate"]:
			var ai: Node = _ai_union if side == "union" else _ai_confed
			Logger.info("TEST", "--- %s PLAYER ---" % side.to_upper())
			ai.set_side(side)

			ai.play_resources()
			ai.play_draw()
			ai.play_cards()
			ai.play_movement()

		_combat_for_both()
		_events_for_both()

		for side in ["union", "confederate"]:
			var ai: Node = _ai_union if side == "union" else _ai_confed
			ai.set_side(side)
			ai.play_end_turn()

			if _check_victory():
				_print_final()
				return

		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()

	_print_final()

func _combat_for_both() -> void:
	Logger.info("TEST", "--- COMBAT (both sides) ---")
	_ai_union.set_side("union")
	_ai_union.play_combat()

func _events_for_both() -> void:
	Logger.info("TEST", "--- EVENTS (both sides) ---")
	_ai_union.set_side("union")
	_ai_union.play_events()

func _check_victory() -> bool:
	for side in ["union", "confederate"]:
		if GameManager.get_morale(side) <= -20:
			var winner: String = "CONFEDERATE" if side == "union" else "UNION"
			Logger.info("TEST", "*** %s WINS! %s morale collapsed! ***" % [winner, side.to_upper()])
			return true
	var dc: String = GameManager.get_territory_owner("washington_dc")
	var r: String = GameManager.get_territory_owner("richmond")
	if dc == "confederate":
		Logger.info("TEST", "*** CONFEDERATE captures Washington D.C.! ***")
		return true
	if r == "union":
		Logger.info("TEST", "*** UNION captures Richmond! ***")
		return true
	return false

func _print_final() -> void:
	Logger.info("TEST", "")
	Logger.info("TEST", "============================================")
	Logger.info("TEST", "  FINAL REPORT")
	Logger.info("TEST", "============================================")
	Logger.info("TEST", "Turns played: %d" % _turn)
	Logger.info("TEST", "Union morale: %d (%s)" % [GameManager.get_morale("union"), GameManager.get_morale_status("union")])
	Logger.info("TEST", "Confed morale: %d (%s)" % [GameManager.get_morale("confederate"), GameManager.get_morale_status("confederate")])
	Logger.info("TEST", "Union res: %s" % str(GameManager.get_resources("union")))
	Logger.info("TEST", "Confed res: %s" % str(GameManager.get_resources("confederate")))
	var counts: Dictionary = {}
	for t_id in GameManager._territory_owners:
		var owner: String = GameManager._territory_owners[t_id]
		counts[owner] = counts.get(owner, 0) + 1
	Logger.info("TEST", "Territories: %s" % str(counts))
	var total_units: int = 0
	for t_id in GameManager._units_on_map:
		total_units += GameManager._units_on_map[t_id].size()
	Logger.info("TEST", "Units on map: %d" % total_units)
	Logger.info("TEST", "Union AI bugs: %d | actions: %d" % [_ai_union.get_bug_count(), _ai_union.get_action_count()])
	Logger.info("TEST", "Confed AI bugs: %d | actions: %d" % [_ai_confed.get_bug_count(), _ai_confed.get_action_count()])
	var total_bugs: int = _ai_union.get_bug_count() + _ai_confed.get_bug_count()
	Logger.info("TEST", "TOTAL BUGS FOUND: %d" % total_bugs)

	get_tree().quit()
