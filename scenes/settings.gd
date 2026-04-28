extends Control

@onready var _title: Label = $MarginContainer/VBox/TitleLabel
@onready var _lang_label: Label = $MarginContainer/VBox/LangSection/LangLabel
@onready var _lang_option: OptionButton = $MarginContainer/VBox/LangSection/LangOption
@onready var _audio_label: Label = $MarginContainer/VBox/AudioSection/AudioLabel
@onready var _vol_label: Label = $MarginContainer/VBox/AudioSection/VolumeRow/VolumeLabel
@onready var _vol_slider: HSlider = $MarginContainer/VBox/AudioSection/VolumeRow/VolumeSlider
@onready var _vol_value: Label = $MarginContainer/VBox/AudioSection/VolumeRow/VolumeValue
@onready var _fullscreen: CheckBox = $MarginContainer/VBox/DisplaySection/FullscreenCheck
@onready var _back_btn: Button = $MarginContainer/VBox/ButtonRow/BackButton
@onready var _union_music_label: Label = $MarginContainer/VBox/MusicSection/UnionMusicRow/UnionMusicLabel
@onready var _union_music_option: OptionButton = $MarginContainer/VBox/MusicSection/UnionMusicRow/UnionMusicOption
@onready var _confed_music_label: Label = $MarginContainer/VBox/MusicSection/ConfedMusicRow/ConfedMusicLabel
@onready var _confed_music_option: OptionButton = $MarginContainer/VBox/MusicSection/ConfedMusicRow/ConfedMusicOption
@onready var _music_label: Label = $MarginContainer/VBox/MusicSection/MusicLabel

var _return_scene: String = "res://scenes/main_menu.tscn"

func _ready() -> void:
	if GameManager.get_current_turn() > 0:
		_return_scene = "res://scenes/game_map.tscn"
	_populate_languages()
	_populate_music_options()
	_lang_option.item_selected.connect(_on_language_selected)
	_back_btn.pressed.connect(_on_back)
	_vol_slider.value_changed.connect(_on_volume_changed)
	_fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_fullscreen.toggled.connect(_on_fullscreen)
	_union_music_option.item_selected.connect(_on_union_music_selected)
	_confed_music_option.item_selected.connect(_on_confed_music_selected)
	Localization.language_changed.connect(_localize)
	_localize()

func _populate_languages() -> void:
	_lang_option.clear()
	var langs: PackedStringArray = Localization.get_available_languages()
	var current: String = Localization.get_language()
	for i in range(langs.size()):
		var lang: String = langs[i]
		var native_name: String = Localization.get_language_native_name(lang)
		_lang_option.add_item(native_name, i)
		if lang == current:
			_lang_option.select(i)

func _populate_music_options() -> void:
	_union_music_option.clear()
	_confed_music_option.clear()
	var options: PackedStringArray = GameManager.get_music_style_options()
	var union_style: String = GameManager.get_music_style("union")
	var confed_style: String = GameManager.get_music_style("confederate")
	for i in range(options.size()):
		var label: String = GameManager.get_music_style_label(options[i])
		_union_music_option.add_item(label, i)
		_confed_music_option.add_item(label, i)
		if options[i] == union_style:
			_union_music_option.select(i)
		if options[i] == confed_style:
			_confed_music_option.select(i)

func _localize() -> void:
	_title.text = Localization.t("game.settings")
	_lang_label.text = Localization.t("game.language")
	_audio_label.text = Localization.t("ui.settings.audio")
	_vol_label.text = Localization.t("ui.music_volume")
	_fullscreen.text = Localization.t("ui.fullscreen")
	_back_btn.text = Localization.t("game.back")
	if _music_label:
		_music_label.text = Localization.t("ui.music_style_title")
	if _union_music_label:
		_union_music_label.text = Localization.t("ui.union_music")
	if _confed_music_label:
		_confed_music_label.text = Localization.t("ui.confed_music")

func _on_language_selected(idx: int) -> void:
	var langs: PackedStringArray = Localization.get_available_languages()
	if idx >= 0 and idx < langs.size():
		Localization.set_language(langs[idx])
		_localize()

func _on_volume_changed(value: float) -> void:
	_vol_value.text = "%d%%" % int(value)
	var bus_idx: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))

func _on_fullscreen(is_on: bool) -> void:
	if is_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_union_music_selected(idx: int) -> void:
	var options: PackedStringArray = GameManager.get_music_style_options()
	if idx >= 0 and idx < options.size():
		GameManager.set_music_style("union", options[idx])

func _on_confed_music_selected(idx: int) -> void:
	var options: PackedStringArray = GameManager.get_music_style_options()
	if idx >= 0 and idx < options.size():
		GameManager.set_music_style("confederate", options[idx])

func set_return_scene(scene_path: String) -> void:
	_return_scene = scene_path

func _on_back() -> void:
	get_tree().change_scene_to_file(_return_scene)
