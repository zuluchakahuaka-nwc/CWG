extends Node

enum Phase { RESOURCES, DRAW, MOVEMENT, COMBAT, EVENTS, END }

signal phase_changed(phase: Phase)
signal turn_changed(turn_number: int, month: String)
signal game_over(winner: String, reason: String)

var _current_turn: int = 1
var _current_phase: Phase = Phase.RESOURCES
var _max_turns: int = 49
var _scenario_id: String = "civil_war"
var _scenario_data: Dictionary = {}
var _turn_month_names: PackedStringArray = [
	"april", "may", "june", "july", "august", "september",
	"october", "november", "december", "january", "february", "march"
]

var _player_side: String = "union"
var _ai_side: String = "confederate"

var _morale: Dictionary = {"union": 0, "confederate": 0}
var _resources: Dictionary = {
	"union": {"manpower": 6, "money": 7, "supply": 5},
	"confederate": {"manpower": 4, "money": 4, "supply": 4}
}
var _territory_owners: Dictionary = {}
var _units_on_map: Dictionary = {}
var _player_hand: Array = []
var _ai_hand: Array = []
var _conscription_streak: Dictionary = {"union": 0, "confederate": 0}
var _used_one_time_events: Array = []

func _ready() -> void:
	pass

func start_game(scenario_id: String, player_side: String) -> void:
	_scenario_id = scenario_id
	_player_side = player_side
	_ai_side = "confederate" if player_side == "union" else "union"
	_current_turn = 1
	_current_phase = Phase.RESOURCES
	_conscription_streak = {"union": 0, "confederate": 0}
	_used_one_time_events = []
	_load_scenario()
	turn_changed.emit(_current_turn, get_current_month())

func _load_scenario() -> void:
	var path: String = "res://data/scenarios/" + _scenario_id + ".json"
	var data = _read_scenario_json(path)
	if data.is_empty():
		_load_territory_owners()
		return
	_scenario_data = data
	if data.has("initial_morale"):
		_morale = data["initial_morale"].duplicate(true)
	if data.has("initial_resources"):
		_resources = data["initial_resources"].duplicate(true)
	_load_scenario_territories(data)

func _read_scenario_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json: JSON = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	return json.get_data() if json.get_data() is Dictionary else {}

func _load_scenario_territories(data: Dictionary) -> void:
	_territory_owners.clear()
	var owners: Dictionary = data.get("initial_territory_owners", {})
	if owners.is_empty():
		_load_territory_owners()
		return
	for t_id in owners:
		_territory_owners[t_id] = owners[t_id]

func get_scenario_data() -> Dictionary:
	return _scenario_data

func _load_territory_owners() -> void:
	_territory_owners.clear()
	var all_ids: Dictionary = CardDatabase.get_all_card_ids()
	for t_id in CardDatabase._territories:
		var t: Dictionary = CardDatabase.get_territory(t_id)
		_territory_owners[t_id] = t.get("initial_owner", "neutral")

func get_current_turn() -> int:
	return _current_turn

func get_current_phase() -> Phase:
	return _current_phase

func get_current_month() -> String:
	var year_offset: int = (_current_turn - 1) / 12
	var month_idx: int = (_current_turn - 1) % 12
	var year: int = 1861 + year_offset
	var month_key: String = "month." + _turn_month_names[month_idx]
	return Localization.t(month_key) + " " + str(year)

func get_morale(side: String) -> int:
	return _morale.get(side, 0)

func change_morale(side: String, amount: int) -> void:
	_morale[side] = clampi(_morale[side] + amount, -20, 20)
	if _morale[side] <= -20:
		game_over.emit("confederate" if side == "union" else "union", "morale_collapse")

func get_resources(side: String) -> Dictionary:
	return _resources.get(side, {})

func change_resource(side: String, resource: String, amount: int) -> void:
	if _resources.has(side) and _resources[side].has(resource):
		_resources[side][resource] = maxi(_resources[side][resource] + amount, 0)

func get_territory_owner(territory_id: String) -> String:
	return _territory_owners.get(territory_id, "neutral")

func set_territory_owner(territory_id: String, side: String) -> void:
	var old: String = _territory_owners.get(territory_id, "")
	_territory_owners[territory_id] = side
	_check_capital_loss(territory_id, old)

func _check_capital_loss(territory_id: String, old_owner: String) -> void:
	if territory_id == "washington_dc" and old_owner == "union":
		change_morale("union", -5)
	elif territory_id == "richmond" and old_owner == "confederate":
		change_morale("confederate", -5)

func advance_phase() -> void:
	match _current_phase:
		Phase.RESOURCES:
			_current_phase = Phase.DRAW
		Phase.DRAW:
			_current_phase = Phase.MOVEMENT
		Phase.MOVEMENT:
			_current_phase = Phase.COMBAT
		Phase.COMBAT:
			_current_phase = Phase.EVENTS
		Phase.EVENTS:
			_current_phase = Phase.END
		Phase.END:
			_end_turn()
			return
	phase_changed.emit(_current_phase)

func _end_turn() -> void:
	_current_turn += 1
	if _current_turn > _max_turns:
		_check_time_victory()
		return
	_current_phase = Phase.RESOURCES
	turn_changed.emit(_current_turn, get_current_month())

func _check_time_victory() -> void:
	var u_count: int = 0
	var c_count: int = 0
	for t_id in _territory_owners:
		match _territory_owners[t_id]:
			"union": u_count += 1
			"confederate": c_count += 1
	if u_count > c_count:
		game_over.emit("union", "timeout")
	elif c_count > u_count:
		game_over.emit("confederate", "timeout")
	else:
		game_over.emit("draw", "timeout")

func get_morale_status(side: String) -> String:
	var m: int = _morale.get(side, 0)
	if m >= 15:
		return "morale.sacred_fervor"
	elif m >= 10:
		return "morale.uplift"
	elif m >= 1:
		return "morale.normal"
	elif m == 0:
		return "morale.neutral"
	elif m >= -9:
		return "morale.gloom"
	elif m >= -14:
		return "morale.unrest"
	elif m >= -19:
		return "morale.rebellion"
	else:
		return "morale.revolution"

func get_morale_bonus_cards(side: String) -> int:
	var m: int = _morale.get(side, 0)
	if m >= 15:
		return 1
	elif m >= 10:
		return 1
	return 0

func get_morale_attack_bonus(side: String) -> int:
	return 1 if _morale.get(side, 0) >= 15 else 0

func is_event_used(event_id: String) -> bool:
	return _used_one_time_events.has(event_id)

func mark_event_used(event_id: String) -> void:
	_used_one_time_events.append(event_id)

func get_conscription_streak(side: String) -> int:
	return _conscription_streak.get(side, 0)

func increment_conscription(side: String) -> void:
	_conscription_streak[side] = _conscription_streak.get(side, 0) + 1

func reset_conscription(side: String) -> void:
	_conscription_streak[side] = 0

func get_player_side() -> String:
	return _player_side

func get_ai_side() -> String:
	return _ai_side

func serialize() -> Dictionary:
	return {
		"turn": _current_turn,
		"phase": _current_phase,
		"scenario": _scenario_id,
		"player_side": _player_side,
		"morale": _morale.duplicate(true),
		"resources": _resources.duplicate(true),
		"territory_owners": _territory_owners.duplicate(true),
		"conscription_streak": _conscription_streak.duplicate(true),
		"used_one_time_events": _used_one_time_events.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	_current_turn = data.get("turn", 1)
	_current_phase = data.get("phase", 0) as Phase
	_scenario_id = data.get("scenario", "full")
	_player_side = data.get("player_side", "union")
	_ai_side = "confederate" if _player_side == "union" else "union"
	_morale = data.get("morale", {"union": 0, "confederate": 0})
	_resources = data.get("resources", _resources)
	_territory_owners = data.get("territory_owners", {})
	_conscription_streak = data.get("conscription_streak", {"union": 0, "confederate": 0})
	_used_one_time_events = data.get("used_one_time_events", [])
