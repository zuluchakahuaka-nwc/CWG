extends RefCounted

func check_triggered_events(context: Dictionary) -> Array:
	var triggered: Array = []
	var side: String = context.get("side", "")
	var territory_id: String = context.get("territory", "")
	var turn: int = GameManager.get_current_turn()
	var month_year: String = GameManager.get_current_month()
	var all_situations: Dictionary = CardDatabase._situations
	for event_id in all_situations:
		var evt: Dictionary = all_situations[event_id]
		if evt.get("type", "") != "situation":
			continue
		if evt.get("one_time_use", false) and GameManager.is_event_used(event_id):
			continue
		var evt_side: String = evt.get("side", "both")
		if evt_side != "both" and evt_side != side:
			continue
		var hist_date: String = evt.get("historical_date", "")
		if hist_date != "" and hist_date != null:
			if not _is_date_active(hist_date, turn):
				continue
		if _check_event_conditions(event_id, evt, context):
			triggered.append({"id": event_id, "data": evt})
	return triggered

func _is_date_active(date_str: String, turn: int) -> bool:
	if date_str == "" or date_str == null:
		return true
	var month_names: PackedStringArray = [
		"april", "may", "june", "july", "august", "september",
		"october", "november", "december", "january", "february", "march"
	]
	var turn_month: String = month_names[(turn - 1) % 12]
	var turn_year: int = 1861 + (turn - 1) / 12
	var parts: PackedStringArray = date_str.split("-")
	if parts.size() < 2:
		return true
	var event_year: int = int(parts[0])
	var event_month: int = int(parts[1])
	var event_month_name: String = ""
	if event_month >= 4:
		event_month_name = month_names[event_month - 4]
	else:
		event_month_name = month_names[event_month + 8]
	if event_year < turn_year:
		return true
	if event_year == turn_year:
		return turn_month == event_month_name
	return false

func _check_event_conditions(event_id: String, evt: Dictionary, context: Dictionary) -> bool:
	var mechanic: String = evt.get("effect_mechanic", "")
	match event_id:
		"EVENT_PICKETTS_CHARGE":
			var brigade_count: int = context.get("pickett_brigade_count", 0)
			var has_pickett: bool = context.get("has_pickett", false)
			var has_lee: bool = context.get("has_lee", false)
			return has_pickett and has_lee and brigade_count >= 5
		"EVENT_MOBILE_BAY":
			return context.get("union_ship_count", 0) >= 3
		"EVENT_LAST_SHOT":
			return GameManager.get_current_turn() >= 49
		"EVENT_MARCH_TO_SEA":
			return context.get("sherman_in_georgia", false)
		"EVENT_ATLANTA_FALL":
			return context.get("sherman_controls_georgia", false)
		"EVENT_VICKSBURG":
			return context.get("grant_at_vicksburg", false)
		"EVENT_APPOMATTOX":
			var conf_resources: Dictionary = GameManager.get_resources("confederate")
			var total: int = 0
			for v in conf_resources.values():
				total += v
			return total < 30 and context.get("grant_besieges_lee", false)
		"EVENT_LINCOLN_ASSASS":
			return GameManager.get_current_turn() >= 48 and context.get("lincoln_active", false)
		"EVENT_NY_DRAFT_RIOT":
			return GameManager.get_morale("union") <= -5 and GameManager.get_conscription_streak("union") >= 2
		"EVENT_BREAD_RIOT":
			return GameManager.get_morale("confederate") <= -8
		"EVENT_LEE_REFUSAL":
			return not GameManager.is_event_used("EVENT_LEE_REFUSAL") and not context.get("lee_played", false)
		"EVENT_STONEWALL_NAME":
			return context.get("stonewall_brigade_present", false)
		"EVENT_IRON_BRIGADE":
			return context.get("iron_brigade_count", 0) >= 3
		"EVENT_FRIENDLY_FIRE":
			return context.get("stonewall_on_table", false)
	return true

func apply_event(event_id: String, context: Dictionary = {}) -> Dictionary:
	var card_effect: CardEffect = CardEffect.new()
	return card_effect.resolve_event(event_id, context)
