class_name BattleResolver
extends RefCounted

## Combat resolution for territory battles.
##
## Design contract (AGENTS.md §12):
## - damage = (ATK + d6) - DEF, floored at 0
## - terrain adds to DEF of the defender and penalizes ATK of the attacker
## - unit-type modifiers (cavalry vs artillery +3, etc.)
## - ships besieging a city: ATK x1.5 (multiplicative)
## - ships attacking artillery in a city (coastal battery): battery +3 DEF
## - counterattack is a normal attack with swapped roles, including
##   terrain/type modifiers
## - a battle can stalemate (no side can pierce the other's DEF): the
##   pairing rotates, and after MAX_BATTLE_ROUNDS the assault fails with
##   the defender holding the territory - never an infinite loop.

const MAX_BATTLE_ROUNDS: int = 60

var _terrain_defense: Dictionary = {
	"plains": 0, "hills": 2, "forest": 1, "river": 3,
	"city": 4, "swamp": 1, "mountains": 3, "mountain": 3
}
var _terrain_attack: Dictionary = {
	"plains": 0, "hills": -1, "forest": -1, "river": -2,
	"city": -2, "swamp": -2, "mountains": -3, "mountain": -3
}
var _type_advantage: Dictionary = {
	"infantry_vs_cavalry": -1,
	"cavalry_vs_infantry": 1,
	"cavalry_vs_artillery": 3,
	"artillery_vs_infantry_open": 2,
	"artillery_vs_infantry_cover": 0,
	"artillery_vs_artillery": 0,
	"ship_vs_ship": 0
}

signal battle_result(attacker_card: Dictionary, defender_card: Dictionary, result: Dictionary)

func resolve_combat(attacker, defender, territory_data: Dictionary) -> Dictionary:
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
	# Ships besieging fortified positions fight at x1.5 ATK (design §12.2).
	if attacker.type == "ship" and terrain == "city":
		attacker_atk = int(round(attacker_atk * 1.5))
	attacker_atk += _get_type_modifier(attacker.type, defender.type, terrain)
	# Coastal battery: artillery defending a city against ships gets +3 DEF.
	if attacker.type == "ship" and defender.type == "artillery" and terrain == "city":
		defender_def += 3
	var round_data: Dictionary = _resolve_round(attacker_atk, defender_def)
	result["rounds"].append(round_data)
	if round_data["damage_to_defender"] >= defender.current_hp:
		result["defender_destroyed"] = true
		result["attacker_won"] = true
		defender.take_damage(round_data["damage_to_defender"])
	else:
		defender.take_damage(round_data["damage_to_defender"])
		# Counterattack: a normal attack with swapped roles - the defender
		# attacks out of the terrain (attack penalty applies), the assaulting
		# unit does not gain the terrain DEF bonus.
		var counter_atk: int = defender.get_effective_attack()
		var counter_def: int = attacker.get_effective_defense()
		counter_atk += _terrain_attack.get(terrain, 0)
		counter_atk += _get_type_modifier(defender.type, attacker.type, terrain)
		var counter_round: Dictionary = _resolve_round(counter_atk, counter_def)
		result["rounds"].append(counter_round)
		attacker.take_damage(counter_round["damage_to_defender"])
		if not attacker.is_alive():
			result["attacker_destroyed"] = true
	return result

func _resolve_round(atk_value: int, def_value: int) -> Dictionary:
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
		"territory_captured": false,
		"stalemate": false
	}
	if attacker_units.is_empty() or defender_units.is_empty():
		return result
	result["attacker_side"] = attacker_units[0].side
	result["defender_side"] = defender_units[0].side
	Logger.info("Battle", "Battle at %s: %d %s vs %d %s" % [territory_data.get("id", "?"), attacker_units.size(), result["attacker_side"], defender_units.size(), result["defender_side"]])
	var remaining_attackers: Array = attacker_units.duplicate()
	var remaining_defenders: Array = defender_units.duplicate()
	var rounds_fought: int = 0
	while not remaining_attackers.is_empty() and not remaining_defenders.is_empty():
		rounds_fought += 1
		if rounds_fought > MAX_BATTLE_ROUNDS:
			# Stalemate: nobody can pierce the other side's DEF. The
			# defender holds the territory; the assault is called off.
			result["stalemate"] = true
			Logger.warn("Battle", "Stalemate at %s after %d rounds: defender holds" % [result["territory"], MAX_BATTLE_ROUNDS])
			break
		var atk = remaining_attackers[0]
		var def = remaining_defenders[0]
		var atk_hp_before: int = atk.current_hp
		var def_hp_before: int = def.current_hp
		var combat: Dictionary = resolve_combat(atk, def, territory_data)
		result["individual_results"].append(combat)
		if combat["defender_destroyed"]:
			remaining_defenders.pop_at(0)
			result["defender_losses"] += 1
		if combat["attacker_destroyed"]:
			remaining_attackers.pop_at(0)
			result["attacker_losses"] += 1
		elif not combat["defender_destroyed"]:
			# No progress in this duel (both alive): rotate the attacker so
			# the next round tries a different pairing instead of looping
			# on the same one forever.
			if atk.current_hp == atk_hp_before and def.current_hp == def_hp_before:
				remaining_attackers.pop_at(0)
				remaining_attackers.append(atk)
			else:
				if not atk.is_alive():
					remaining_attackers.pop_at(0)
					result["attacker_losses"] += 1
				if not def.is_alive():
					remaining_defenders.pop_at(0)
					result["defender_losses"] += 1
	if remaining_defenders.is_empty() and not remaining_attackers.is_empty():
		result["territory_captured"] = true
	Logger.info("Battle", "Battle result at %s: losses %d/%d captured=%s stalemate=%s" % [result["territory"], result["attacker_losses"], result["defender_losses"], str(result["territory_captured"]), str(result["stalemate"])])
	return result
