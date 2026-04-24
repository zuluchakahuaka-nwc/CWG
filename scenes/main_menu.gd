extends Control

@onready var _title: Label = $TitleLabel
@onready var _subtitle: Label = $SubtitleLabel
@onready var _new_game_btn: Button = $VBoxContainer/NewGameButton
@onready var _continue_btn: Button = $VBoxContainer/ContinueButton
@onready var _settings_btn: Button = $VBoxContainer/SettingsButton
@onready var _quit_btn: Button = $VBoxContainer/QuitButton
@onready var _lang_btn: Button = $VBoxContainer/LanguageButton

func _ready() -> void:
	_localize()
	_new_game_btn.pressed.connect(_on_new_game)
	_continue_btn.pressed.connect(_on_continue)
	_settings_btn.pressed.connect(_on_settings)
	_quit_btn.pressed.connect(_on_quit)
	_lang_btn.pressed.connect(_on_language)
	_continue_btn.disabled = not _has_save()

func _localize() -> void:
	_title.text = Localization.t("game.title")
	_new_game_btn.text = Localization.t("game.new_game")
	_continue_btn.text = Localization.t("game.continue")
	_settings_btn.text = Localization.t("game.settings")
	_quit_btn.text = Localization.t("game.quit")
	_lang_btn.text = Localization.t("game.language")

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/scenario_select.tscn")

func _on_continue() -> void:
	_load_game()

func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit() -> void:
	get_tree().quit()

func _on_language() -> void:
	var current: String = Localization.get_language()
	Localization.set_language("en" if current == "ru" else "ru")
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
