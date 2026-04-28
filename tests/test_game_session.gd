extends Node

var _turn_log: String = ""
var _ci: RefCounted
var _resolver: RefCounted
var _hands: Dictionary = {"union": [], "confederate": []}

func _process(_delta: float) -> void:
	set_process(false)
	_ci = load("res://scripts/cards/card_instance.gd")
	_resolver = load("res://scripts/combat/battle_resolver.gd").new()
	_play_full_game()

func _log(msg: String) -> void:
	_turn_log += msg + "\n"
	Logger.info("Game", msg)

func _play_full_game() -> void:
	_log("========================================")
	_log("  CIVIL WAR: BLUE & GRAY - TEST MATCH")
	_log("  Union (Player 1) vs Confederate (Player 2)")
	_log("========================================")

	GameManager.start_game("civil_war", "union")
	_log("Game started. Map: %d territories" % CardDatabase._territories.size())
	_log("")

	var _territory_counts: Dictionary = _count_territories()
	_log("Union: %d territories | Confederate: %d | Neutral: %d" % [
		_territory_counts.get("union", 0), _territory_counts.get("confederate", 0), _territory_counts.get("neutral", 0)])

	for turn in range(1, 9):
		_play_turn(turn, "union")
		_play_turn(turn, "confederate")
		if _check_victory():
			break

	_log("")
	_log("========================================")
	_log("  FINAL SCOREBOARD")
	_log("========================================")
	_log("Turn reached: %d" % GameManager.get_current_turn())
	_log("Union morale: %d (%s)" % [GameManager.get_morale("union"), GameManager.get_morale_status("union")])
	_log("Confed morale: %d (%s)" % [GameManager.get_morale("confederate"), GameManager.get_morale_status("confederate")])
	_log("Union resources: %s" % str(GameManager.get_resources("union")))
	_log("Confed resources: %s" % str(GameManager.get_resources("confederate")))
	var final_counts: Dictionary = _count_territories()
	_log("Union territories: %d | Confed: %d | Neutral: %d" % [final_counts.get("union", 0), final_counts.get("confederate", 0), final_counts.get("neutral", 0)])
	var total_units: int = 0
	for t_id in GameManager._units_on_map:
		for u in GameManager._units_on_map[t_id]:
			if u.is_alive():
				total_units += 1
	_log("Total units alive: %d" % total_units)
	_log("")

	Logger.info("GameLog", _turn_log)
	var f: FileAccess = FileAccess.open("user://game_session.log", FileAccess.WRITE)
	if f:
		f.store_string(_turn_log)
		f.close()
	Logger.info("Game", "Session log saved to user://game_session.log")
	get_tree().quit()

func _count_territories() -> Dictionary:
	var counts: Dictionary = {}
	for t_id in GameManager._territory_owners:
		var owner: String = GameManager._territory_owners[t_id]
		counts[owner] = counts.get(owner, 0) + 1
	return counts

func _play_turn(turn_num: int, side: String) -> void:
	if GameManager.get_current_turn() != turn_num:
		return

	_log("--- TURN %d | %s | %s ---" % [turn_num, GameManager.get_current_month(), side.to_upper()])

	_phase_resources(side)
	_phase_draw(side)
	_phase_play_cards(side)
	_phase_movement(side)
	_phase_combat(side)

	if side == "confederate":
		_phase_events()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		GameManager.advance_phase()
		_log("")

func _phase_resources(side: String) -> void:
	var res_before: Dictionary = GameManager.get_resources(side)
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == side:
			var t: Dictionary = CardDatabase.get_territory(t_id)
			GameManager.change_resource(side, "manpower", t.get("resource_manpower", 0))
			GameManager.change_resource(side, "money", t.get("resource_money", 0))
			GameManager.change_resource(side, "supply", t.get("resource_supply", 0))
	var res_after: Dictionary = GameManager.get_resources(side)
	_log("  [RESOURCES] %s: Men %d->%d  Gold %d->%d  Supply %d->%d" % [
		side, res_before["manpower"], res_after["manpower"],
		res_before["money"], res_after["money"],
		res_before["supply"], res_after["supply"]])

func _phase_draw(side: String) -> void:
	var count: int = 3 + GameManager.get_morale_bonus_cards(side)
	var all_units: Array = CardDatabase.get_all_units_for_side(side)
	for i in range(count):
		var card_data: Dictionary = all_units[randi() % all_units.size()]
		_hands[side].append(_ci.new(card_data))
	var card_names: PackedStringArray = PackedStringArray()
	for card in _hands[side]:
		card_names.append(card.id)
	_log("  [DRAW] %s drew %d cards. Hand: %s" % [side, count, " ".join(card_names)])

func _phase_play_cards(side: String) -> void:
	var hand: Array = _hands[side]
	var played: int = 0
	var to_play: Array = []
	for card in hand:
		var cost: int = card.cost
		if GameManager.get_resources(side)["money"] >= cost:
			to_play.append(card)

	for card in to_play:
		var best_territory: String = ""
		for t_id in GameManager._territory_owners:
			if GameManager._territory_owners[t_id] == side:
				best_territory = t_id
				if t_id == "washington_dc" or t_id == "richmond":
					best_territory = t_id
					break
		if best_territory == "":
			continue
		GameManager.change_resource(side, "money", -card.cost)
		card.territory_id = best_territory
		if not GameManager._units_on_map.has(best_territory):
			GameManager._units_on_map[best_territory] = []
		GameManager._units_on_map[best_territory].append(card)
		hand.erase(card)
		played += 1
		_log("  [PLAY] %s placed %s (ATK:%d DEF:%d HP:%d) at %s (cost %d gold)" % [
			side, card.id, card.attack, card.defense, card.max_hp, best_territory, card.cost])
	if played == 0:
		_log("  [PLAY] %s: no cards played (need gold)" % side)

func _phase_movement(side: String) -> void:
	var moves: int = 0
	var to_move: Array = []
	for t_id in GameManager._units_on_map:
		var units: Array = GameManager._units_on_map[t_id]
		for u in units:
			if u.side == side and u.is_alive() and not u.is_exhausted:
				var adj: Array = CardDatabase.get_adjacent_territories(t_id)
				if adj.size() > 0:
					var neighbors_owned: Array = []
					var enemies: Array = []
					for a in adj:
						var a_owner: String = GameManager.get_territory_owner(a)
						if a_owner == side:
							neighbors_owned.append(a)
						elif a_owner != "neutral":
							enemies.append(a)
					if enemies.size() > 0 and randf() > 0.4:
						to_move.append({"from": t_id, "to": enemies[randi() % enemies.size()], "unit": u})
					elif neighbors_owned.size() > 0 and randf() > 0.6:
						to_move.append({"from": t_id, "to": neighbors_owned[randi() % neighbors_owned.size()], "unit": u})

	for move in to_move:
		var from_id: String = move["from"]
		var to_id: String = move["to"]
		var unit = move["unit"]
		var units_from: Array = GameManager._units_on_map.get(from_id, [])
		if not unit in units_from:
			continue
		units_from.erase(unit)
		if units_from.is_empty():
			GameManager._units_on_map.erase(from_id)
		else:
			GameManager._units_on_map[from_id] = units_from
		if not GameManager._units_on_map.has(to_id):
			GameManager._units_on_map[to_id] = []
		unit.territory_id = to_id
		unit.is_exhausted = true
		GameManager._units_on_map[to_id].append(unit)
		var to_name: String = CardDatabase.get_territory(to_id).get("name_en", to_id)
		_log("  [MOVE] %s %s -> %s" % [unit.id.left(16), from_id, to_id])
		moves += 1

	for t_id in GameManager._units_on_map:
		for u in GameManager._units_on_map[t_id]:
			u.is_exhausted = false

	if moves == 0:
		_log("  [MOVE] %s: no moves this turn" % side)

func _phase_combat(side: String) -> void:
	var battles: int = 0
	var to_check: Array = GameManager._units_on_map.keys().duplicate()

	for t_id in to_check:
		if not GameManager._units_on_map.has(t_id):
			continue
		var units: Array = GameManager._units_on_map[t_id]
		if units.size() < 2:
			continue
		var sides_present: Dictionary = {}
		for u in units:
			if u.is_alive():
				sides_present[u.side] = sides_present.get(u.side, 0) + 1
		if sides_present.keys().size() < 2:
			continue

		var defender_side: String = GameManager.get_territory_owner(t_id)
		var attackers: Array = []
		var defenders: Array = []
		for u in units:
			if not u.is_alive():
				continue
			if u.side == defender_side:
				defenders.append(u)
			else:
				attackers.append(u)
		if attackers.is_empty() or defenders.is_empty():
			continue

		var t_data: Dictionary = CardDatabase.get_territory(t_id)
		var t_name: String = t_data.get("name_en", t_id)
		var terrain: String = t_data.get("terrain", "?")
		_log("  [BATTLE] %s (%s): %d %s vs %d %s" % [t_name, terrain, attackers.size(), attackers[0].side, defenders.size(), defenders[0].side])

		var atk_names: PackedStringArray = PackedStringArray()
		for a in attackers:
			atk_names.append("%s(HP:%d)" % [a.id.left(10), a.current_hp])
		_log("    Attackers: %s" % " ".join(atk_names))
		var def_names: PackedStringArray = PackedStringArray()
		for d in defenders:
			def_names.append("%s(HP:%d)" % [d.id.left(10), d.current_hp])
		_log("    Defenders: %s" % " ".join(def_names))

		var result: Dictionary = _resolver.resolve_territory_battle(attackers, defenders, t_data)

		for r in result["individual_results"]:
			_log("    Round: ATK(%d)+d%d vs DEF(%d) -> dmg %d | atk_dead=%s def_dead=%s" % [
				r.get("attacker_id", "?"),
				r["rounds"][0].get("dice_roll", 0) if r.get("rounds", []).size() > 0 else 0,
				r.get("defender_id", "?"),
				r["rounds"][0].get("damage_to_defender", 0) if r.get("rounds", []).size() > 0 else 0,
				str(r.get("attacker_destroyed", false)),
				str(r.get("defender_destroyed", false))])

		_log("    Result: ATK lost %d | DEF lost %d | Captured: %s" % [
			result["attacker_losses"], result["defender_losses"], str(result["territory_captured"])])

		if result["territory_captured"]:
			var new_owner: String = attackers[0].side if attackers[0].is_alive() else "neutral"
			GameManager.set_territory_owner(t_id, new_owner)
			_log("    %s CAPTURED %s!" % [new_owner.to_upper(), t_name])
			if t_data.get("is_capital", false):
				GameManager.change_morale(new_owner, 5)
				GameManager.change_morale("confederate" if new_owner == "union" else "union", -5)

		var alive: Array = []
		for u in GameManager._units_on_map.get(t_id, []):
			if u.is_alive():
				alive.append(u)
		if alive.is_empty():
			GameManager._units_on_map.erase(t_id)
		else:
			GameManager._units_on_map[t_id] = alive
		battles += 1

	if battles == 0:
		_log("  [COMBAT] %s: no battles" % side)

func _phase_events() -> void:
	for side in ["union", "confederate"]:
		var m: int = GameManager.get_morale(side)
		if m <= -10 and randi_range(1, 10) == 1:
			_log("  [EVENT] DESERTION in %s! (morale=%d)" % [side, m])
			GameManager.change_morale(side, -1)

func _check_victory() -> bool:
	for side in ["union", "confederate"]:
		if GameManager.get_morale(side) <= -20:
			var winner: String = "confederate" if side == "union" else "union"
			_log("")
			_log("*** VICTORY: %s wins! %s morale collapsed! ***" % [winner.to_upper(), side.to_upper()])
			return true

	var dc_owner: String = GameManager.get_territory_owner("washington_dc")
	var r_owner: String = GameManager.get_territory_owner("richmond")
	if dc_owner == "confederate":
		_log("")
		_log("*** VICTORY: CONFEDERACY captures Washington D.C.! ***")
		return true
	if r_owner == "union":
		_log("")
		_log("*** VICTORY: UNION captures Richmond! ***")
		return true
	return false
