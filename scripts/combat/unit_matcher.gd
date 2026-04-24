extends RefCounted

func match_units_for_battle(territory_id: String) -> Dictionary:
	var result: Dictionary = {
		"territory": territory_id,
		"attacker_side": "",
		"defender_side": "",
		"attacker_units": [],
		"defender_units": [],
		"has_battle": false
	}
	var owner: String = GameManager.get_territory_owner(territory_id)
	var attacker_side: String = ""
	if owner == "union":
		attacker_side = "confederate"
	elif owner == "confederate":
		attacker_side = "union"
	else:
		return result
	var attacker_units: Array = _get_units_on_territory(territory_id, attacker_side)
	var defender_units: Array = _get_units_on_territory(territory_id, owner)
	if attacker_units.is_empty():
		return result
	result["attacker_side"] = attacker_side
	result["defender_side"] = owner
	result["attacker_units"] = attacker_units
	result["defender_units"] = defender_units
	result["has_battle"] = true
	return result

func _get_units_on_territory(territory_id: String, side: String) -> Array:
	var units: Array = []
	if not GameManager._units_on_map.has(territory_id):
		return units
	for unit in GameManager._units_on_map[territory_id]:
		if unit is CardInstance and unit.side == side:
			units.append(unit)
	return units

func find_all_contested_territories() -> Array:
	var contested: Array = []
	for t_id in GameManager._units_on_map:
		var owner: String = GameManager.get_territory_owner(t_id)
		if owner == "neutral":
			continue
		var attacker_side: String = "confederate" if owner == "union" else "union"
		var has_attacker: bool = false
		var has_defender: bool = false
		for unit in GameManager._units_on_map[t_id]:
			if unit is CardInstance:
				if unit.side == attacker_side:
					has_attacker = true
				elif unit.side == owner:
					has_defender = true
		if has_attacker and has_defender:
			contested.append(t_id)
	return contested

func get_combat_strength(units: Array) -> Dictionary:
	var total_atk: int = 0
	var total_def: int = 0
	var total_hp: int = 0
	var count_by_type: Dictionary = {}
	for unit in units:
		if unit is CardInstance:
			total_atk += unit.get_effective_attack()
			total_def += unit.get_effective_defense()
			total_hp += unit.current_hp
			count_by_type[unit.type] = count_by_type.get(unit.type, 0) + 1
	return {
		"total_attack": total_atk,
		"total_defense": total_def,
		"total_hp": total_hp,
		"unit_count": units.size(),
		"by_type": count_by_type
	}
