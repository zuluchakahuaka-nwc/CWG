extends RefCounted

enum TerrainModifier { PLAINS, HILLS, FOREST, RIVER, CITY, SWAMP, MOUNTAIN }

var _terrain_defense: Dictionary = {
	"plains": 0, "hills": 2, "forest": 1, "river": 3,
	"city": 4, "swamp": 1, "mountain": 3
}
var _terrain_attack: Dictionary = {
	"plains": 0, "hills": -1, "forest": -1, "river": -2,
	"city": -2, "swamp": -2, "mountain": -3
}
var _type_advantage: Dictionary = {
	"infantry_vs_cavalry": -1,
	"cavalry_vs_infantry": 1,
	"cavalry_vs_artillery": 3,
	"artillery_vs_infantry_open": 2,
	"artillery_vs_infantry_cover": 0,
	"artillery_vs_artillery": 0,
	"ship_vs_ship": 0,
	"ship_vs_city": 1.5,
	"coastal_battery_vs_ship": 3
}

signal battle_result(attacker_card: Dictionary, defender_card: Dictionary, result: Dictionary)

func resolve_combat(attacker: CardInstance, defender: CardInstance, territory_data: Dictionary) -> Dictionary:
	var terrain: String = territory_data.get("terrain", "plains")
	var is_fortified: bool = territory_data.get("is_capital", false) or territory_data.get("is_railroad", false)
	var result: Dictionary = {
		"attacker_id": attacker.id,
		"defender_id": defender.id,
		"rounds": [],
		"attacker_won": false,
		"attacker_destroyed": false,
		"defender_destroyed": false
	}
	var attacker_atk: int = attacker.get_effective_attack()
	var defender_def: int = defender.get_effective_defense()
	attacker_atk += _terrain_attack.get(terrain, 0)
	defender_def += _terrain_defense.get(terrain, 0)
	if is_fortified:
		defender_def += 1
	attacker_atk += _get_type_modifier(attacker.type, defender.type, terrain)
	var round_data: Dictionary = _resolve_round(attacker_atk, defender_def, attacker.current_hp, defender.current_hp)
	result["rounds"].append(round_data)
	if round_data["damage_to_defender"] >= defender.current_hp:
		result["defender_destroyed"] = true
		result["attacker_won"] = true
		defender.take_damage(round_data["damage_to_defender"])
	else:
		defender.take_damage(round_data["damage_to_defender"])
		var counter_atk: int = defender.get_effective_attack()
		var counter_def: int = attacker.get_effective_defense()
		var counter_round: Dictionary = _resolve_round(counter_atk, counter_def, defender.current_hp, attacker.current_hp)
		result["rounds"].append(counter_round)
		attacker.take_damage(counter_round["damage_to_defender"])
		if not attacker.is_alive():
			result["attacker_destroyed"] = true
	return result

func _resolve_round(atk_value: int, def_value: int, atk_hp: int, def_hp: int) -> Dictionary:
	var roll: int = randi_range(1, 6)
	var raw_damage: int = (atk_value + roll) - def_value
	var damage: int = maxi(raw_damage, 0)
	return {
		"attack_value": atk_value,
		"defense_value": def_value,
		"dice_roll": roll,
		"damage_to_defender": damage
	}

func _get_type_modifier(attacker_type: String, defender_type: String, terrain: String) -> int:
	var key: String = attacker_type + "_vs_" + defender_type
	if _type_advantage.has(key):
		return _type_advantage[key]
	if attacker_type == "artillery" and defender_type == "infantry":
		if terrain == "plains":
			return _type_advantage["artillery_vs_infantry_open"]
		else:
			return _type_advantage["artillery_vs_infantry_cover"]
	return 0

func resolve_territory_battle(attacker_units: Array, defender_units: Array, territory_data: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"territory": territory_data.get("id", ""),
		"attacker_side": "",
		"defender_side": "",
		"individual_results": [],
		"attacker_losses": 0,
		"defender_losses": 0,
		"territory_captured": false
	}
	if attacker_units.is_empty() or defender_units.is_empty():
		return result
	result["attacker_side"] = attacker_units[0].side
	result["defender_side"] = defender_units[0].side
	var remaining_attackers: Array = attacker_units.duplicate()
	var remaining_defenders: Array = defender_units.duplicate()
	var atk_idx: int = 0
	var def_idx: int = 0
	while not remaining_attackers.is_empty() and not remaining_defenders.is_empty():
		var atk: CardInstance = remaining_attackers[0]
		var def: CardInstance = remaining_defenders[0]
		var combat: Dictionary = resolve_combat(atk, def, territory_data)
		result["individual_results"].append(combat)
		if combat["defender_destroyed"]:
			remaining_defenders.pop_at(0)
			result["defender_losses"] += 1
		if combat["attacker_destroyed"]:
			remaining_attackers.pop_at(0)
			result["attacker_losses"] += 1
		elif not combat["defender_destroyed"]:
			if not atk.is_alive():
				remaining_attackers.pop_at(0)
				result["attacker_losses"] += 1
			if not def.is_alive():
				remaining_defenders.pop_at(0)
				result["defender_losses"] += 1
	if remaining_defenders.is_empty() and not remaining_attackers.is_empty():
		result["territory_captured"] = true
	return result
