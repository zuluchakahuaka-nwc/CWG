extends Node

signal language_changed(lang: String)

const SAVE_PATH: String = "user://settings.json"

var _current_lang: String = "en"
var _translations: Dictionary = {}
var _available_languages: PackedStringArray = []

func _ready() -> void:
	_load_translations()
	_load_saved_language()

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
		var lang: String = header[i].strip_edges()
		lang_idx[lang] = i
		if not _available_languages.has(lang):
			_available_languages.append(lang)
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

func _load_saved_language() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		var sys_lang: String = TranslationServer.get_locale()
		if sys_lang.begins_with("ru"):
			_current_lang = "ru"
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data: Dictionary = json.get_data()
	if data.has("language"):
		var saved: String = data["language"]
		if _available_languages.has(saved):
			_current_lang = saved

func _save_settings() -> void:
	var data: Dictionary = {"language": _current_lang}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func set_language(lang: String) -> void:
	if lang == _current_lang:
		return
	_current_lang = lang
	_save_settings()
	language_changed.emit(lang)

func get_language() -> String:
	return _current_lang

func get_available_languages() -> PackedStringArray:
	return _available_languages

func get_language_native_name(lang: String) -> String:
	match lang:
		"ru": return "Русский"
		"en": return "English"
		"fr": return "Français"
		"es": return "Español"
		"de": return "Deutsch"
		"pt": return "Português"
		"zh": return "中文"
		"ja": return "日本語"
		"hi": return "हिन्दी"
		"ar": return "العربية"
		_: return lang

func has_key(key: String) -> bool:
	if _translations.has(_current_lang) and _translations[_current_lang].has(key):
		return true
	if _translations.has("en") and _translations["en"].has(key):
		return true
	return false

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
