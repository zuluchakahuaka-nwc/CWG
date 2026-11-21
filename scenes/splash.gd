extends Control
## Boot splash: engraved title over a slowly zooming period map, menu-slot
## march playing. Any key/click or 5 seconds advances to the main menu.

const HOLD_SECONDS: float = 5.0

var _advanced: bool = false

@onready var _bg: TextureRect = $Bg
@onready var _dim: ColorRect = $Dim
@onready var _title: Label = $Title
@onready var _subtitle: Label = $Subtitle
@onready var _hint: Label = $Hint

func _ready() -> void:
	_apply_style()
	Localization.language_changed.connect(_apply_hint)
	_play_music()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.2).from(0.0)
	var zoom := create_tween().set_loops()
	zoom.tween_property(_bg, "scale", Vector2(1.08, 1.08), 7.0).from(Vector2(1.0, 1.0))
	get_tree().create_timer(HOLD_SECONDS).timeout.connect(_advance)
	AudioManager.attach_button_sounds(self)

func _apply_style() -> void:
	for bg_path in [
		"res://assets/sprites/map/territories/map_background.jpg",
		"res://assets/sprites/map/map_background.png",
	]:
		if ResourceLoader.exists(bg_path):
			_bg.texture = load(bg_path)
			break
	_title.add_theme_font_override("font", FontLoader.get_font("title"))
	_title.add_theme_font_size_override("font_size", 92)
	_title.add_theme_color_override("font_color", Color(0.87, 0.74, 0.46))
	_subtitle.add_theme_font_override("font", FontLoader.get_font("caption"))
	_subtitle.add_theme_font_size_override("font_size", 34)
	_subtitle.add_theme_color_override("font_color", Color(0.78, 0.70, 0.55))
	_hint.add_theme_font_override("font", FontLoader.get_font("body"))
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(0.65, 0.62, 0.55))
	_apply_hint()

func _apply_hint() -> void:
	_title.text = Localization.t("game.title")
	_subtitle.text = "1861 — 1865"
	_hint.text = Localization.t("splash.skip")

func _play_music() -> void:
	MusicPlayer.set_volume(0.45)
	MusicPlayer.play_slot("menu")

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		_advance()

func _advance() -> void:
	if _advanced:
		return
	_advanced = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
