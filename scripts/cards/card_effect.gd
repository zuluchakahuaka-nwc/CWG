extends RefCounted

enum EffectType {
	INSTANT_DESTROY,
	MUTUAL_DESTROY,
	DESTROY_TARGET_SELF_DAMAGE,
	CANCEL_BATTLE,
	SURRENDER_IF_OUTNUMBERED,
	DOUBLE_COMMERCE_DAMAGE,
	FREE_SHIP_TRANSFORM,
	IGNORE_MINES,
	NAVAL_SUPERIORITY_CARD,
	ELIMINATE_COMMANDER,
	SELF_DESTROY_STOP_ATTACK,
	MASS_ASSAULT,
	STATUS_UNBREAKABLE,
	BUFF_ATTACK_IF_COUNT,
	STEAL_SUPPLY_CARD,
	STEAL_RESOURCES,
	DOUBLE_FIRST_VOLLEY,
	BLOCK_INFANTRY_ADVANCE,
	LOSE_COMMANDER,
	DOUBLE_STRENGTH_OUTNUMBERED,
	BUFF_ATTACK,
	BUFF_DEFENSE,
	BUFF_ALL_ARTILLERY,
	DRAW_CARDS,
	MORALE_CHANGE,
	RESOURCE_CHANGE,
	MOVEMENT_CHANGE,
	MOVE_UNIT_ANYWHERE,
	REVEAL_ENEMY_CARDS,
	CANCEL_EVENT,
	RISK_DESERTION,
	DEBUFF_REGIMENT,
	EXTRA_ACTION,
	RESTORE_HP
}

func resolve_event(event_id: String, context: Dictionary = {}) -> Dictionary:
	var event_data: Dictionary = CardDatabase.get_situation(event_id)
	if event_data.is_empty():
		return {"success": false, "reason": "event_not_found"}
	if event_data.get("one_time_use", false) and GameManager.is_event_used(event_id):
		return {"success": false, "reason": "already_used"}
	var side: String = context.get("side", "union")
	if not _check_conditions(event_data, context):
		return {"success": false, "reason": "conditions_not_met"}
	var mechanic: String = event_data.get("effect_mechanic", "")
	var result: Dictionary = _apply_mechanic(mechanic, event_data, context)
	if result.get("success", false) and event_data.get("one_time_use", false):
		GameManager.mark_event_used(event_id)
	return result

func _check_conditions(event_data: Dictionary, context: Dictionary) -> bool:
	var mechanic: String = event_data.get("effect_mechanic", "")
	match mechanic:
		"INSTANT_DESTROY":
			var target_ids: Array = event_data.get("target_ids", [])
			if target_ids.is_empty():
				return false
		"MASS_ASSAULT":
			var brigade_count: int = context.get("brigade_count", 0)
			if brigade_count < 5:
				return false
		"SURRENDER_IF_OUTNUMBERED":
			var union_ships: int = context.get("union_ship_count", 0)
			if union_ships < 3:
				return false
	return true

func _apply_mechanic(mechanic: String, event_data: Dictionary, context: Dictionary) -> Dictionary:
	var result: Dictionary = {"success": true, "mechanic": mechanic}
	match mechanic:
		"INSTANT_DESTROY":
			result["destroyed"] = event_data.get("target_ids", [])
		"MUTUAL_DESTROY":
			result["destroyed"] = event_data.get("target_ids", [])
		"CANCEL_BATTLE":
			result["battle_cancelled"] = true
		"SELF_DESTROY_STOP_ATTACK":
			result["self_destroyed"] = true
			result["attack_stopped"] = true
		"STATUS_UNBREAKABLE":
			result["defense_bonus"] = 4
			result["duration"] = 1
		"BUFF_ATTACK_IF_COUNT":
			result["attack_bonus"] = 2
			result["condition_tag"] = context.get("tag", "")
			result["min_count"] = 3
		"STEAL_SUPPLY_CARD", "STEAL_RESOURCES":
			result["stolen"] = 1
		"DOUBLE_FIRST_VOLLEY":
			result["damage_multiplier"] = 2.0
		"BLOCK_INFANTRY_ADVANCE":
			result["advance_blocked"] = true
		"DOUBLE_STRENGTH_OUTNUMBERED":
			result["strength_doubled"] = true
		"BUFF_ATTACK":
			result["attack_bonus"] = context.get("amount", 1)
			result["targets"] = context.get("targets", [])
		"BUFF_DEFENSE":
			result["defense_bonus"] = context.get("amount", 3)
			result["targets"] = context.get("targets", [])
		"BUFF_ALL_ARTILLERY":
			result["attack_bonus"] = 2
			result["target_type"] = "artillery"
		"DRAW_CARDS":
			result["cards_drawn"] = context.get("count", 2)
		"MORALE_CHANGE":
			var amount: int = context.get("amount", 0)
			GameManager.change_morale(context.get("side", "union"), amount)
			result["morale_change"] = amount
		"IGNORE_MINES":
			result["mines_ignored"] = true
		"FREE_SHIP_TRANSFORM":
			result["transform_from"] = context.get("from_id", "")
			result["transform_to"] = context.get("to_id", "")
		_:
			result["success"] = false
			result["reason"] = "unknown_mechanic"
	return result
