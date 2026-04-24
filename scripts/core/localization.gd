extends Node

signal language_changed(lang: String)

var _current_lang: String = "ru"
var _translations: Dictionary = {}

func _ready() -> void:
	_load_translations()

func _load_translations() -> void:
	var path: String = "res://data/localization/translations.csv"
	if not FileAccess.file_exists(path):
		push_error("Localization: file not found: " + path)
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Localization: cannot open: " + path)
		return
	var header: PackedStringArray = file.get_csv_line()
	var lang_idx: Dictionary = {}
	for i in range(1, header.size()):
		lang_idx[header[i].strip_edges()] = i
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		if line.size() < 2 or line[0].strip_edges() == "":
			continue
		var key: String = line[0].strip_edges()
		for lang in lang_idx:
			var idx: int = lang_idx[lang]
			if idx < line.size():
				if not _translations.has(lang):
					_translations[lang] = {}
				_translations[lang][key] = line[idx].strip_edges()
	file.close()

func set_language(lang: String) -> void:
	if lang == _current_lang:
		return
	_current_lang = lang
	language_changed.emit(lang)

func get_language() -> String:
	return _current_lang

func t(key: String) -> String:
	if _translations.has(_current_lang) and _translations[_current_lang].has(key):
		return _translations[_current_lang][key]
	if _translations.has("en") and _translations["en"].has(key):
		return _translations["en"][key]
	return key

func get_card_name(card_data: Dictionary) -> String:
	var field: String = "name_" + _current_lang
	if card_data.has(field):
		return card_data[field]
	if card_data.has("name_en"):
		return card_data["name_en"]
	return card_data.get("id", "???")

func get_card_description(card_data: Dictionary) -> String:
	var field: String = "description_" + _current_lang
	if card_data.has(field):
		return card_data[field]
	if card_data.has("description_en"):
		return card_data["description_en"]
	return ""

func get_card_flavor(card_data: Dictionary) -> String:
	var field: String = "flavor_" + _current_lang
	if card_data.has(field):
		return card_data[field]
	if card_data.has("flavor_en"):
		return card_data["flavor_en"]
	return ""
