extends Control

@onready var _title: Label = $TitleLabel
@onready var _lang_label: Label = $VBoxContainer/LanguageLabel
@onready var _lang_btn: Button = $VBoxContainer/LanguageButton
@onready var _vol_label: Label = $VBoxContainer/VolumeLabel
@onready var _vol_slider: HSlider = $VBoxContainer/VolumeSlider
@onready var _fullscreen: CheckBox = $VBoxContainer/FullscreenCheck
@onready var _back_btn: Button = $VBoxContainer/BackButton

func _ready() -> void:
	_localize()
	_lang_btn.pressed.connect(_on_language)
	_back_btn.pressed.connect(_on_back)
	_fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_fullscreen.toggled.connect(_on_fullscreen)

func _localize() -> void:
	_title.text = Localization.t("game.settings")
	_lang_btn.text = "Русский / English"
	_back_btn.text = Localization.t("game.back")

func _on_language() -> void:
	var current: String = Localization.get_language()
	Localization.set_language("en" if current == "ru" else "ru")
	_localize()

func _on_fullscreen(is_on: bool) -> void:
	if is_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
