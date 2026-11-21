extends Node
## Suite: game invariants (hub law "verifiability of behavior" 21-22.11).
## A full AI-vs-AI run must never break the laws of the game state -
## even a "playing fine" game with a broken state is a bug. Doctrine
## asserts (snowball: captures must happen) ride along.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []
var _ai_union: Node
var _ai_confed: Node
var _invariant_checks: int = 0

func _ready() -> void:
	print("\n=== TEST: Game invariants ===")
	_run()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func _run() -> void:
	_ai_union = Node.new()
	_ai_union.set_script(load("res://scripts/ai/ai_controller.gd"))
	_ai_union.set_side("union")
	add_child(_ai_union)
	_ai_confed = Node.new()
	_ai_confed.set_script(load("res://scripts/ai/ai_controller.gd"))
	_ai_confed.set_side("confederate")
	add_child(_ai_confed)
	GameManager.start_game("civil_war", "union")
	var hands: Dictionary = {"union": [], "confederate": []}
	_ai_union.set_hands(hands)
	_ai_confed.set_hands(hands)
	var captures_by_turn: Array = []
	for turn in range(1, 13):
		for side in ["union", "confederate"]:
			var ai: Node = _ai_union if side == "union" else _ai_confed
			ai.set_side(side)
			ai.play_resources()
			ai.play_draw()
			ai.play_cards()
			ai.play_movement()
		_resolve_combat()
		for side in ["union", "confederate"]:
			var ai: Node = _ai_union if side == "union" else _ai_confed
			ai.set_side(side)
			ai.play_end_turn()
		_assert_invariants(turn)
		captures_by_turn.append(_total_captures())
		if GameManager.get_morale("union") <= -20 or GameManager.get_morale("confederate") <= -20:
			break
	_assert(captures_by_turn.size() >= 3 and captures_by_turn[captures_by_turn.size() - 1] > captures_by_turn[2],
		"snowball doctrine: captures grow by turn 12 (%d -> %d)" % [captures_by_turn[2] if captures_by_turn.size() > 2 else -1, captures_by_turn[captures_by_turn.size() - 1]])
	_assert(_invariant_checks > 0, "invariant sweep actually ran (%d checks)" % _invariant_checks)

## The combat resolution of game_map._phase_combat (post-pass claim
## included) - mirrored here as the minimal standalone form.
func _resolve_combat() -> void:
	for t_id in GameManager._units_on_map.keys():
		var units: Array = GameManager._units_on_map[t_id]
		var sides: Dictionary = {}
		for u in units:
			if u.has_method("is_alive") and u.is_alive():
				sides[u.side] = sides.get(u.side, 0) + 1
		if sides.keys().size() >= 2:
			var attackers: Array = []
			var defenders: Array = []
			var defender_side: String = GameManager.get_territory_owner(t_id)
			for u in units:
				if u.has_method("is_alive") and u.is_alive():
					if u.side == defender_side:
						defenders.append(u)
					else:
						attackers.append(u)
			if attackers.is_empty() or defenders.is_empty():
				continue
			var resolver = load("res://scripts/combat/battle_resolver.gd").new()
			var result: Dictionary = resolver.resolve_territory_battle(attackers, defenders, CardDatabase.get_territory(t_id))
			if result.get("territory_captured", false) and attackers.size() > 0:
				GameManager.set_territory_owner(t_id, attackers[0].side)
	# Post-battle claim (single-side-held land flips).
	for t_id in GameManager._units_on_map.keys():
		var holder: String = ""
		var contested: bool = false
		for u in GameManager._units_on_map[t_id]:
			if not (u.has_method("is_alive") and u.is_alive()):
				continue
			if holder == "":
				holder = u.side
			elif u.side != holder:
				contested = true
				break
		if not contested and holder != "":
			GameManager.try_bloodless_capture(t_id, holder)

func _total_captures() -> int:
	var total: int = 0
	for t_id in GameManager._territory_owners:
		var td: Dictionary = CardDatabase.get_territory(t_id)
		var initial: String = str(td.get("initial_owner", "neutral"))
		if initial != "neutral" and GameManager._territory_owners[t_id] != initial:
			total += 1
	return total

func _assert_invariants(turn: int) -> void:
	for side in ["union", "confederate"]:
		var morale: int = GameManager.get_morale(side)
		if morale < -20 or morale > 20:
			_assert(false, "turn %d: %s morale %d out of [-20..20]" % [turn, side, morale])
			return
		var res: Dictionary = GameManager.get_resources(side)
		for key in ["manpower", "money", "supply"]:
			if int(res.get(key, 0)) < 0:
				_assert(false, "turn %d: %s %s negative (%d)" % [turn, side, key, int(res.get(key, 0))])
				return
	for t_id in GameManager._territory_owners:
		var owner: String = str(GameManager._territory_owners[t_id])
		if not (owner == "union" or owner == "confederate" or owner == "neutral"):
			_assert(false, "turn %d: territory %s owned by '%s'" % [turn, t_id, owner])
			return
	var territories: Dictionary = CardDatabase._territories
	for t_id in GameManager._units_on_map:
		if not territories.has(t_id):
			_assert(false, "turn %d: units stand on unknown territory %s" % [turn, t_id])
			return
		for u in GameManager._units_on_map[t_id]:
			if u.has_method("is_alive") and u.is_alive() and u.current_hp <= 0:
				_assert(false, "turn %d: alive unit %s has hp %d" % [turn, u.id, u.current_hp])
				return
	_assert(true, "turn %d: state invariants hold" % turn)
	_invariant_checks += 1

func _print_summary() -> void:
	for line in _test_results:
		print(line)
	print("=== INVARIANTS: %d passed, %d failed ===" % [_pass_count, _fail_count])
