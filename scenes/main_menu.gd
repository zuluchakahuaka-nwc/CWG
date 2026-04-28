extends Control

@onready var _title: Label = $VBoxContainer/TitleLabel
@onready var _subtitle: Label = $VBoxContainer/SubtitleLabel
@onready var _new_game_btn: Button = $VBoxContainer/NewGameButton
@onready var _continue_btn: Button = $VBoxContainer/ContinueButton
@onready var _settings_btn: Button = $VBoxContainer/SettingsButton
@onready var _quit_btn: Button = $VBoxContainer/QuitButton
@onready var _lang_btn: Button = $VBoxContainer/LanguageButton
@onready var _gear_btn: Button = $SettingsGear

func _ready() -> void:
	_localize()
	_new_game_btn.pressed.connect(_on_new_game)
	_continue_btn.pressed.connect(_on_continue)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	_lang_btn.pressed.connect(_on_language_cycle)
	_gear_btn.pressed.connect(_on_settings)
	_continue_btn.disabled = not _has_save()
	Localization.language_changed.connect(_localize)

func _localize() -> void:
	_title.text = Localization.t("game.title")
	_subtitle.text = Localization.t("game.subtitle")
	_new_game_btn.text = Localization.t("game.new_game")
	_continue_btn.text = Localization.t("game.continue")
	_settings_btn.text = Localization.t("game.settings")
	_quit_btn.text = Localization.t("game.quit")
	var current: String = Localization.get_language()
	_lang_btn.text = Localization.t("game.language") + ": " + Localization.get_language_native_name(current)

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")

func _on_continue() -> void:
	_load_game()

func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _on_language_cycle() -> void:
	var langs: PackedStringArray = Localization.get_available_languages()
	var current: String = Localization.get_language()
	var idx: int = langs.find(current)
	idx = (idx + 1) % langs.size()
	Localization.set_language(langs[idx])
	_localize()

func _has_save() -> bool:
	return FileAccess.file_exists("user://save_game.json")

func _load_game() -> void:
	if not _has_save():
		return
	var file: FileAccess = FileAccess.open("user://save_game.json", FileAccess.READ)
	if file == null:
		return
	var json: JSON = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data: Dictionary = json.get_data()
	GameManager.deserialize(data)
	get_tree().change_scene_to_file("res://scenes/game_map.tscn")
