class_name AIController
extends Node

signal ai_turn_complete(side: String)

var _side: String = "union"
var _hands: Dictionary = {"union": [], "confederate": []}
var _ci: RefCounted
var _resolver: RefCounted
var _bug_count: int = 0
var _action_count: int = 0

func _init() -> void:
	_ci = load("res://scripts/cards/card_instance.gd")
	_resolver = load("res://scripts/combat/battle_resolver.gd").new()

func set_side(side: String) -> void:
	_side = side

func set_hands(hands: Dictionary) -> void:
	_hands = hands

func execute_turn() -> void:
	play_resources()
	play_draw()
	play_cards()
	play_movement()
	play_combat()
	play_events()
	play_end_turn()
	ai_turn_complete.emit(_side)

func _bug(msg: String) -> void:
	_bug_count += 1
	Logger.error("AI", "BUG #%d [%s]: %s" % [_bug_count, _side, msg])

func _act(msg: String) -> void:
	_action_count += 1
	Logger.info("AI", "#%d [%s] %s" % [_action_count, _side.to_upper(), msg])

func play_resources() -> void:
	_act("RESOURCES phase start")
	var res_before: Dictionary = GameManager.get_resources(_side).duplicate()
	var territory_count: int = 0
	for t_id in GameManager._territory_owners:
		if GameManager._territory_owners[t_id] == _side:
			territory_count += 1
			var t: Dictionary = CardDatabase.get_territory(t_id)
			if t.is_empty():
				_bug("Territory %s has no data!" % t_id)
				continue
			var mp: int = t.get("resource_manpower", 0)
			var mn: int = t.get("resource_money", 0)
			var sp: int = t.get("resource_supply", 0)
			if mp == 0 and mn == 0 and sp == 0:
				pass
			else:
				GameManager.change_resource(_side, "manpower", mp)
				GameManager.change_resource(_side, "money", mn)
				GameManager.change_resource(_side, "supply", sp)
	var res_after: Dictionary = GameManager.get_resources(_side)
	if res_after["manpower"] < res_before["manpower"]:
		_bug("Resources DECREASED after income! %s -> %s" % [str(res_before), str(res_after)])
	_act("Income from %d territories. Men:%d Gold:%d Supply:%d" % [territory_count, res_after["manpower"], res_after["money"], res_after["supply"]])

func play_draw() -> void:
	_act("DRAW phase start")
	var count: int = 3 + GameManager.get_morale_bonus_cards(_side)
	var all_units: Array = CardDatabase.get_all_units_for_side(_side)
	if all_units.is_empty():
		_bug("No unit cards available for %s!" % _side)
		return
	_act("Available cards: %d types" % all_units.size())
	var drawn_names: PackedStringArray = PackedStringArray()
	for i in range(count):
		var card_data: Dictionary = all_units[randi() % all_units.size()]
		if not card_data.has("id"):
			_bug("Card missing 'id' field: %s" % str(card_data.keys()))
			continue
		var card = _ci.new(card_data)
		if card.attack < 0:
			_bug("Card %s has negative attack: %d" % [card.id, card.attack])
		if card.max_hp <= 0:
			_bug("Card %s has zero HP!" % card.id)
		_hands[_side].append(card)
		drawn_names.append(card.id)
	_act("Drew %d cards: %s" % [count, " ".join(drawn_names)])

func play_cards() -> void:
	_act("PLAY CARDS phase start")
	var hand: Array = _hands[_side]
	var res: Dictionary = GameManager.get_resources(_side)
	_act("Hand: %d cards, Gold: %d" % [hand.size(), res["money"]])

	var played: int = 0
	var skipped: int = 0
	var to_remove: Array = []

	for card in hand:
		if res["money"] < card.cost:
			skipped += 1
			continue
		var my_territories: Array = []
		for t_id in GameManager._territory_owners:
			if GameManager._territory_owners[t_id] == _side:
				my_territories.append(t_id)
		if my_territories.is_empty():
			_bug("No owned territories to place card!")
			break
		var target: String = _pick_placement_target(my_territories, card)
		GameManager.change_resource(_side, "money", -card.cost)
		card.territory_id = target
		if not GameManager._units_on_map.has(target):
			GameManager._units_on_map[target] = []
		GameManager._units_on_map[target].append(card)
		to_remove.append(card)
		played += 1
		_act("Placed %s (%s ATK:%d DEF:%d HP:%d) -> %s (cost %d)" % [
			card.id, card.type, card.attack, card.defense, card.max_hp, target, card.cost])
		res = GameManager.get_resources(_side)

	for card in to_remove:
		hand.erase(card)

	if skipped > 0:
		_act("Skipped %d cards (not enough gold)" % skipped)
	if played > 0:
		_act("Played %d cards, %d remaining in hand" % [played, hand.size()])

func _pick_placement_target(territories: Array, card) -> String:
	var border_territories: Array = []
	var interior_territories: Array = []
	for t_id in territories:
		var adj: Array = CardDatabase.get_adjacent_territories(t_id)
		for a in adj:
			var a_owner: String = GameManager.get_territory_owner(a)
			if a_owner != _side and a_owner != "neutral":
				border_territories.append(t_id)
				break
		if not t_id in border_territories:
			interior_territories.append(t_id)
	if not border_territories.is_empty():
		return border_territories[randi() % border_territories.size()]
	if not interior_territories.is_empty():
		return interior_territories[randi() % interior_territories.size()]
	return territories[randi() % territories.size()]

func play_movement() -> void:
	_act("MOVEMENT phase start")
	var moves_made: int = 0
	var my_movable: Array = []

	for t_id in GameManager._units_on_map:
		var units: Array = GameManager._units_on_map[t_id]
		for u in units:
			if u.side == _side and u.is_alive() and not u.is_exhausted:
				my_movable.append({"unit": u, "from": t_id})

	if my_movable.is_empty():
		_act("No movable units")
		return

	_act("Movable units: %d" % my_movable.size())

	var moved_from: Dictionary = {}

	for entry in my_movable:
		var unit = entry["unit"]
		var from_id: String = entry["from"]
		var units_at_from: int = 0
		for u2 in GameManager._units_on_map.get(from_id, []):
			if u2.side == _side and u2.is_alive() and not u2.is_exhausted:
				units_at_from += 1
		var already_moved: int = moved_from.get(from_id, 0)
		if units_at_from > 1 and already_moved >= units_at_from - 1:
			continue

		var adj: Array = CardDatabase.get_adjacent_territories(from_id)
		if adj.is_empty():
			_bug("Territory %s has no connections!" % from_id)
			continue
		var best_target: String = ""
		var best_priority: int = -1
		for a in adj:
			var a_owner: String = GameManager.get_territory_owner(a)
			var enemy_units: Array = GameManager._units_on_map.get(a, [])
			var has_enemy: bool = false
			for eu in enemy_units:
				if eu.side != _side and eu.is_alive():
					has_enemy = true
					break
			var priority: int = 0
			if has_enemy:
				priority = 5
			elif a_owner != _side and a_owner != "neutral":
				priority = 3
			elif a_owner == "neutral":
				priority = 2
			elif a_owner == _side:
				var friend_count: int = 0
				for fu in enemy_units:
					if fu.is_alive():
						friend_count += 1
				if friend_count < 2:
					priority = 1
			if priority > best_priority:
				best_priority = priority
				best_target = a

		if best_target == "":
			continue
		if not _do_move(from_id, best_target, unit):
			_bug("Move failed: %s -> %s for unit %s" % [from_id, best_target, unit.id])
		else:
			moves_made += 1
			moved_from[from_id] = moved_from.get(from_id, 0) + 1

	_act("Moved %d units" % moves_made)

	for t_id in GameManager._units_on_map:
		for u in GameManager._units_on_map[t_id]:
			u.is_exhausted = false

func _do_move(from_id: String, to_id: String, unit) -> bool:
	var from_units: Array = GameManager._units_on_map.get(from_id, [])
	if not unit in from_units:
		return false
	from_units.erase(unit)
	if from_units.is_empty():
		GameManager._units_on_map.erase(from_id)
	else:
		GameManager._units_on_map[from_id] = from_units
	if not GameManager._units_on_map.has(to_id):
		GameManager._units_on_map[to_id] = []
	unit.territory_id = to_id
	GameManager._units_on_map[to_id].append(unit)
	var to_name: String = CardDatabase.get_territory(to_id).get("name_en", to_id)
	_act("Move %s -> %s" % [unit.id.left(16), to_name])
	return true

func play_combat() -> void:
	_act("COMBAT phase start")
	var battles_fought: int = 0
	var checked: Dictionary = {}
	var contested_count: int = 0

	for t_id in GameManager._units_on_map.keys():
		if checked.has(t_id):
			continue
		checked[t_id] = true
		var units: Array = GameManager._units_on_map[t_id]
		if units.size() < 2:
			continue
		var sides_present: Dictionary = {}
		for u in units:
			if u.is_alive():
				sides_present[u.side] = sides_present.get(u.side, 0) + 1
		if sides_present.keys().size() < 2:
			continue
		if sides_present.keys().size() > 2:
			_bug("More than 2 sides at %s: %s" % [t_id, str(sides_present)])
		contested_count += 1
		battles_fought += 1
		_resolve_battle(t_id)

	if contested_count > 0:
		_act("Contested territories: %d" % contested_count)
	_act("Battles fought: %d" % battles_fought)

	var territory_units: Dictionary = {}
	for t_id in GameManager._units_on_map:
		var units_here: Array = GameManager._units_on_map[t_id]
		var side_count: Dictionary = {}
		for u in units_here:
			if u.is_alive():
				side_count[u.side] = side_count.get(u.side, 0) + 1
		if side_count.keys().size() > 0:
			territory_units[t_id] = side_count
	var contested_debug: PackedStringArray = PackedStringArray()
	for t_id in territory_units:
		if territory_units[t_id].keys().size() > 1:
			contested_debug.append("%s(%s)" % [t_id, str(territory_units[t_id])])
	if contested_debug.size() > 0:
		_act("CONTESTED NOW: %s" % " ".join(contested_debug))
	else:
		_act("No contested territories found")
		var sample: PackedStringArray = PackedStringArray()
		for t_id in territory_units:
			sample.append("%s:%s" % [t_id, str(territory_units[t_id])])
			if sample.size() >= 5:
				break
		_act("Sample territories: %s" % " ".join(sample))

func _resolve_battle(t_id: String) -> void:
	var t_data: Dictionary = CardDatabase.get_territory(t_id)
	var t_name: String = t_data.get("name_en", t_id)
	var terrain: String = t_data.get("terrain", "plains")
	var defender_side: String = GameManager.get_territory_owner(t_id)
	var units: Array = GameManager._units_on_map.get(t_id, [])
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
		_bug("Battle at %s but no valid combatants! atk=%d def=%d" % [t_id, attackers.size(), defenders.size()])
		return
	_act("BATTLE at %s (%s): %d %s vs %d %s" % [t_name, terrain, attackers.size(), attackers[0].side, defenders.size(), defenders[0].side])
	var result: Dictionary = _resolver.resolve_territory_battle(attackers, defenders, t_data)
	if result["attacker_losses"] + result["defender_losses"] == 0:
		_bug("Battle at %s: 0 total losses! atk=%d def=%d" % [t_name, attackers.size(), defenders.size()])
	_act("Result: ATK lost %d, DEF lost %d, captured=%s" % [result["attacker_losses"], result["defender_losses"], str(result["territory_captured"])])

	if result["territory_captured"]:
		var winner_side: String = ""
		for u in GameManager._units_on_map.get(t_id, []):
			if u.is_alive():
				winner_side = u.side
				break
		if winner_side == "":
			winner_side = "neutral"
			_bug("Territory captured but no alive units! Setting neutral.")
		var old_owner: String = GameManager.get_territory_owner(t_id)
		GameManager.set_territory_owner(t_id, winner_side)
		_act("%s CAPTURED %s from %s!" % [winner_side.to_upper(), t_name, old_owner])
		if t_data.get("is_capital", false):
			GameManager.change_morale(winner_side, 5)
			var loser: String = "confederate" if winner_side == "union" else "union"
			GameManager.change_morale(loser, -5)
			_act("CAPITAL FELL! %s morale +5, %s morale -5" % [winner_side, loser])

	var alive_units: Array = []
	for u in GameManager._units_on_map.get(t_id, []):
		if u.is_alive():
			alive_units.append(u)
		else:
			_act("Unit destroyed: %s" % u.id)
	if alive_units.is_empty():
		GameManager._units_on_map.erase(t_id)
	else:
		GameManager._units_on_map[t_id] = alive_units

func play_events() -> void:
	_act("EVENTS phase")
	for side in ["union", "confederate"]:
		var m: int = GameManager.get_morale(side)
		if m <= -10:
			if randi_range(1, 10) == 1:
				_act("DESERTION event for %s (morale=%d)" % [side, m])
				GameManager.change_morale(side, -1)
		if m <= -15:
			if randi_range(1, 5) == 1:
				var owned: Array = []
				for t_id in GameManager._territory_owners:
					if GameManager._territory_owners[t_id] == side:
						owned.append(t_id)
				if owned.size() > 3:
					var lost: String = owned[randi() % owned.size()]
					GameManager.set_territory_owner(lost, "neutral")
					_act("REBELLION! %s lost %s" % [side, lost])

func play_end_turn() -> void:
	_act("END TURN - ticking buffs")
	for t_id in GameManager._units_on_map:
		for u in GameManager._units_on_map[t_id]:
			if u.has_method("tick_buffs"):
				u.tick_buffs()
	_verify_state()

func _verify_state() -> void:
	var total_units: int = 0
	for t_id in GameManager._units_on_map:
		for u in GameManager._units_on_map[t_id]:
			total_units += 1
			if not u.is_alive():
				_bug("Dead unit still on map at %s: %s HP=%d" % [t_id, u.id, u.current_hp])
			if u.territory_id != t_id:
				_bug("Unit territory mismatch: %s thinks it's at %s but found at %s" % [u.id, u.territory_id, t_id])
			var owner: String = GameManager.get_territory_owner(t_id)
			if owner == "neutral" and u.is_alive():
				var has_claim: bool = false
				for u2 in GameManager._units_on_map[t_id]:
					if u2.is_alive():
						has_claim = true
						break
				if not has_claim:
					_bug("Neutral territory %s has units but no alive claimant" % t_id)
	var counts: Dictionary = _count_territories()
	_act("State verify: %d units, territories U:%d C:%d N:%d" % [total_units, counts.get("union", 0), counts.get("confederate", 0), counts.get("neutral", 0)])

func _count_territories() -> Dictionary:
	var counts: Dictionary = {}
	for t_id in GameManager._territory_owners:
		var owner: String = GameManager._territory_owners[t_id]
		counts[owner] = counts.get(owner, 0) + 1
	return counts

func get_bug_count() -> int:
	return _bug_count

func get_action_count() -> int:
	return _action_count
