extends Node

var _units: Dictionary = {}
var _commanders: Dictionary = {}
var _situations: Dictionary = {}
var _territories: Dictionary = {}
var _connections: Array = []
var _battles: Array = []
var _music_tracks: Array = []

signal database_loaded

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	_load_json_array("res://data/cards/units_union.json", _units)
	_load_json_array("res://data/cards/units_confederate.json", _units)
	_load_json_array("res://data/cards/commanders.json", _commanders)
	_load_json_array("res://data/cards/situations.json", _situations)
	_load_json_dict("res://data/maps/territories.json", _territories)
	_load_connections()
	_load_json_raw("res://data/maps/battles.json", _battles)
	_load_json_raw("res://data/music/tracks.json", _music_tracks)
	Logger.info("CardDatabase", "Loaded %d units, %d commanders, %d situations, %d territories" % [_units.size(), _commanders.size(), _situations.size(), _territories.size()])
	database_loaded.emit()

func _load_json_array(path: String, target: Dictionary) -> void:
	var data = _read_json(path)
	if data == null:
		return
	if data is Array:
		for item in data:
			if item.has("id"):
				target[item["id"]] = item

func _load_json_dict(path: String, target: Dictionary) -> void:
	var data = _read_json(path)
	if data == null:
		return
	if data is Array:
		for item in data:
			if item.has("id"):
				target[item["id"]] = item
	elif data is Dictionary:
		for key in data:
			target[key] = data[key]

func _load_connections() -> void:
	var data = _read_json("res://data/maps/connections.json")
	if data is Array:
		_connections = data

func _load_json_raw(path: String, target: Array) -> void:
	var data = _read_json(path)
	if data is Array:
		target.append_array(data)

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		Logger.warn("CardDatabase", "File not found: " + path)
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		Logger.error("CardDatabase", "Cannot open: " + path)
		return null
	var json: JSON = JSON.new()
	var err: Error = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		Logger.error("CardDatabase", "Parse error in %s: %s" % [path, json.get_error_message()])
		return null
	return json.get_data()

func get_unit(id: String) -> Dictionary:
	if _units.has(id):
		return _units[id]
	if _commanders.has(id):
		return _commanders[id]
	return {}

func get_situation(id: String) -> Dictionary:
	if _situations.has(id):
		return _situations[id]
	return {}

func get_territory(id: String) -> Dictionary:
	return _territories.get(id, {})

func get_all_units_for_side(side: String) -> Array:
	var result: Array = []
	for id in _units:
		if _units[id].get("side", "") == side:
			result.append(_units[id])
	return result

func get_all_commanders_for_side(side: String) -> Array:
	var result: Array = []
	for id in _commanders:
		if _commanders[id].get("side", "") == side:
			result.append(_commanders[id])
	return result

func get_all_situations_for_side(side: String) -> Array:
	var result: Array = []
	for id in _situations:
		var s: Dictionary = _situations[id]
		if s.get("side", "both") == side or s.get("side", "both") == "both":
			result.append(s)
	return result

func get_connections_for_territory(territory_id: String) -> Array:
	var result: Array = []
	for conn in _connections:
		if conn.get("from", "") == territory_id:
			result.append(conn)
		elif conn.get("to", "") == territory_id:
			result.append(conn)
	return result

func get_adjacent_territories(territory_id: String) -> Array:
	var result: Array = []
	for conn in _connections:
		if conn.get("from", "") == territory_id:
			if not result.has(conn["to"]):
				result.append(conn["to"])
		elif conn.get("to", "") == territory_id:
			if not result.has(conn["from"]):
				result.append(conn["from"])
	return result

func get_battles_for_territory(territory_id: String) -> Array:
	var result: Array = []
	for b in _battles:
		if b.get("territory", "") == territory_id:
			result.append(b)
	return result

func get_music_tracks(category: String = "") -> Array:
	if category == "":
		return _music_tracks
	var result: Array = []
	for track in _music_tracks:
		if track.get("category", "") == category:
			result.append(track)
	return result

func get_music_tracks_for_side(side: String) -> Array:
	var style: String = GameManager.get_music_style(side)
	return get_music_tracks(style)

func get_all_card_ids() -> Dictionary:
	return {
		"units": _units.keys(),
		"commanders": _commanders.keys(),
		"situations": _situations.keys()
	}
