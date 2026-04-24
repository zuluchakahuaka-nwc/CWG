extends RefCounted

enum Strategy { CONSERVATIVE, AGGRESSIVE, BALANCED }

var _strategy: Strategy = Strategy.BALANCED
var _side: String = ""
var _weights: Dictionary = {
	Strategy.CONSERVATIVE: {"territory": 3.0, "morale": 2.0, "resources": 2.0, "army": 1.0, "commander": 1.0},
	Strategy.AGGRESSIVE: {"territory": 1.0, "morale": 1.0, "resources": 1.0, "army": 3.0, "commander": 2.0},
	Strategy.BALANCED: {"territory": 2.0, "morale": 2.0, "resources": 2.0, "army": 2.0, "commander": 1.5}
}

func _init(side: String, strategy: Strategy = Strategy.BALANCED) -> void:
	_side = side
	_strategy = strategy

func evaluate_position() -> float:
	var w: Dictionary = _weights[_strategy]
	var my_territories: int = 0
	var enemy_territories: int = 0
	var enemy_side: String = "confederate" if _side == "union" else "union"
	for t_id in GameManager._territory_owners:
		match GameManager._territory_owners[t_id]:
			_side: my_territories += 1
			enemy_side: enemy_territories += 1
	var territory_score: float = (my_territories - enemy_territories) * w["territory"]
	var morale_score: float = (GameManager.get_morale(_side) - GameManager.get_morale(enemy_side)) * w["morale"]
	var my_res: Dictionary = GameManager.get_resources(_side)
	var enemy_res: Dictionary = GameManager.get_resources(enemy_side)
	var resource_diff: int = 0
	for key in my_res:
		resource_diff += int(my_res[key]) - int(enemy_res.get(key, 0))
	var resource_score: float = resource_diff * w["resources"]
	var army_score: float = _count_my_units() * w["army"]
	return territory_score + morale_score + resource_score + army_score

func choose_card_to_play(hand: Array, available_money: int) -> Dictionary:
	var best_card: Dictionary = {}
	var best_score: float = -999.0
	for card in hand:
		var cost: int = card.get("cost", 0)
		if cost > available_money:
			continue
		var score: float = _evaluate_card(card)
		if score > best_score:
			best_score = score
			best_card = card
	return best_card

func choose_territory_to_attack(available_units: Array) -> String:
	var best_target: String = ""
	var best_score: float = -999.0
	for t_id in GameManager._territory_owners:
		var owner: String = GameManager._territory_owners[t_id]
		if owner == _side or owner == "neutral":
			continue
		var adjacent: Array = CardDatabase.get_adjacent_territories(t_id)
		var is_adjacent: bool = false
		for adj in adjacent:
			if GameManager.get_territory_owner(adj) == _side:
				is_adjacent = true
				break
		if not is_adjacent:
			continue
		var t: Dictionary = CardDatabase.get_territory(t_id)
		var score: float = _evaluate_target_territory(t)
		if t.get("is_capital", false):
			score += 5.0
		if t.get("is_port", false):
			score += 2.0
		if t.get("special_bonus", "") != "":
			score += 1.5
		if score > best_score:
			best_score = score
			best_target = t_id
	return best_target

func choose_territory_to_defend(threatened: Array) -> String:
	if threatened.is_empty():
		return ""
	var best: String = ""
	var best_score: float = -999.0
	for t_id in threatened:
		var t: Dictionary = CardDatabase.get_territory(t_id)
		var score: float = 2.0
		if t.get("is_capital", false):
			score += 10.0
		if t.get("special_bonus", "") != "":
			score += 3.0
		if t.get("is_railroad", false):
			score += 2.0
		if score > best_score:
			best_score = score
			best = t_id
	return best

func _evaluate_card(card: Dictionary) -> float:
	var score: float = 0.0
	var type: String = card.get("type", "")
	var rarity: String = card.get("rarity", "common")
	var atk: int = card.get("attack", 0)
	var def: int = card.get("defense", 0)
	var hp: int = card.get("hp", 0)
	score += (atk + def + hp) * 0.5
	match rarity:
		"legendary": score += 3.0
		"rare": score += 1.5
		"uncommon": score += 0.5
	match type:
		"commander": score += 4.0
		"situation": score += 2.0
		"ship": score += 1.5
	if card.get("linked_events", []).size() > 0:
		score += 1.0
	return score

func _evaluate_target_territory(t: Dictionary) -> float:
	var score: float = 0.0
	var terrain: String = t.get("terrain", "plains")
	match terrain:
		"plains": score += 1.0
		"hills": score -= 0.5
		"forest": score -= 0.3
		"city": score -= 1.0
		"mountain": score -= 1.5
		"river": score -= 1.0
	score += t.get("resource_money", 0) * 0.5
	score += t.get("resource_supply", 0) * 0.3
	return score

func _count_my_units() -> int:
	var count: int = 0
	for t_id in GameManager._units_on_map:
		for unit in GameManager._units_on_map[t_id]:
			if unit is CardInstance and unit.side == _side:
				count += 1
	return count
