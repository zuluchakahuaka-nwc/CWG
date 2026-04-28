extends Control

var _player = null
var _PhonographPlayerScript = load("res://scripts/ui/phonograph_player.gd")

@onready var _title: Label = $Panel/VBox/TitleLabel
@onready var _mode_label: Label = $Panel/VBox/ModeLabel
@onready var _now_playing: Label = $Panel/VBox/NowPlayingLabel
@onready var _track_label: Label = $Panel/VBox/TrackLabel
@onready var _progress: ProgressBar = $Panel/VBox/ProgressBar
@onready var _track_list: ItemList = $Panel/VBox/TrackList
@onready var _volume_slider: HSlider = $Panel/VBox/VolumeSlider
@onready var _close_btn: Button = $Panel/VBox/CloseButton
@onready var _play_btn: Button = $Panel/VBox/Controls/PlayBtn
@onready var _stop_btn: Button = $Panel/VBox/Controls/StopBtn
@onready var _prev_btn: Button = $Panel/VBox/Controls/PrevBtn
@onready var _next_btn: Button = $Panel/VBox/Controls/NextBtn
@onready var _shuffle_btn: Button = $Panel/VBox/Controls/ShuffleBtn
@onready var _repeat_btn: Button = $Panel/VBox/Controls/RepeatBtn
@onready var _union_btn: Button = $Panel/VBox/SideTabs/UnionBtn
@onready var _confed_btn: Button = $Panel/VBox/SideTabs/ConfedBtn

var _current_side: String = "union"

func _ready() -> void:
	_player = _PhonographPlayerScript.new()
	add_child(_player)
	_localize()
	_close_btn.pressed.connect(_on_close)
	_play_btn.pressed.connect(_on_play)
	_stop_btn.pressed.connect(_on_stop)
	_prev_btn.pressed.connect(_on_prev)
	_next_btn.pressed.connect(_on_next)
	_shuffle_btn.pressed.connect(_on_shuffle)
	_repeat_btn.pressed.connect(_on_repeat)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_track_list.item_selected.connect(_on_track_selected)
	_union_btn.pressed.connect(_on_side_tab.bind("union"))
	_confed_btn.pressed.connect(_on_side_tab.bind("confederate"))
	_player.track_changed.connect(_on_track_changed)
	_player.side_changed.connect(_on_player_side_changed)
	Localization.language_changed.connect(_localize)
	_on_side_tab("union")

func _localize() -> void:
	_title.text = Localization.t("phonograph.title")
	_now_playing.text = Localization.t("phonograph.now_playing")
	_close_btn.text = Localization.t("phonograph.close")
	_union_btn.text = Localization.t("ui.side_union_blue")
	_confed_btn.text = Localization.t("ui.side_confed_red")
	_play_btn.text = Localization.t("phonograph.play")
	_stop_btn.text = Localization.t("phonograph.stop")
	_prev_btn.text = Localization.t("phonograph.prev")
	_next_btn.text = Localization.t("phonograph.next")
	_shuffle_btn.text = Localization.t("phonograph.shuffle")
	_repeat_btn.text = Localization.t("phonograph.repeat")
	if has_node("Panel/VBox/VolumeLabel"):
		$Panel/VBox/VolumeLabel.text = Localization.t("phonograph.volume")

func _update_side_highlight() -> void:
	if _current_side == "union":
		_union_btn.modulate = Color(0.4, 0.6, 1.0)
		_confed_btn.modulate = Color.WHITE
		if has_node("Panel/VBox/DiscPlaceholder"):
			$Panel/VBox/DiscPlaceholder.color = Color(0.15, 0.18, 0.25, 1)
	else:
		_confed_btn.modulate = Color(1.0, 0.35, 0.35)
		_union_btn.modulate = Color.WHITE
		if has_node("Panel/VBox/DiscPlaceholder"):
			$Panel/VBox/DiscPlaceholder.color = Color(0.25, 0.15, 0.1, 1)

func _update_mode_label() -> void:
	if _player.is_phonograph_mode():
		_mode_label.text = Localization.t("phonograph.mode_phonograph") + "\n" + Localization.t("phonograph.desc_phonograph")
	else:
		_mode_label.text = Localization.t("phonograph.mode_orchestra") + "\n" + Localization.t("phonograph.desc_orchestra")

func _load_side_tracks(side: String) -> void:
	_current_side = side
	_track_list.clear()
	_player.stop()
	_player.set_side(side)
	var tracks: Array = _player.get_playlist()
	for track in tracks:
		var title: String = track.get("title_" + Localization.get_language(), track.get("title_en", "???"))
		_track_list.add_item(title)
	_update_side_highlight()
	_update_mode_label()
	if not tracks.is_empty():
		_player.play_track(tracks[0])
		_update_now_playing()
		_play_btn.text = Localization.t("phonograph.pause")

func _on_side_tab(side: String) -> void:
	_load_side_tracks(side)

func _on_player_side_changed(_side: String) -> void:
	_load_side_tracks(_current_side)

func _on_track_selected(index: int) -> void:
	var tracks: Array = _player.get_playlist()
	if index >= 0 and index < tracks.size():
		_player.play_track(tracks[index])
		_update_now_playing()

func _on_track_changed(_track: Dictionary) -> void:
	_update_now_playing()

func _on_play() -> void:
	if _player.is_playing():
		_player.pause()
		_play_btn.text = Localization.t("phonograph.play")
	else:
		if _player.get_current_track().is_empty():
			var tracks: Array = _player.get_playlist()
			if not tracks.is_empty():
				_player.play_track(tracks[0])
		else:
			_player.resume()
		_play_btn.text = Localization.t("phonograph.pause")
	_update_now_playing()

func _on_stop() -> void:
	_player.stop()
	_play_btn.text = Localization.t("phonograph.play")
	_track_label.text = Localization.t("phonograph.no_track")
	_progress.value = 0.0

func _on_prev() -> void:
	_player.previous_track()
	_update_now_playing()

func _on_next() -> void:
	_player.next_track()
	_update_now_playing()

func _on_shuffle() -> void:
	var is_on: bool = _player.toggle_shuffle()
	_shuffle_btn.modulate = Color(1, 1, 0.5) if is_on else Color.WHITE

func _on_repeat() -> void:
	var is_on: bool = _player.toggle_repeat()
	_repeat_btn.modulate = Color(1, 1, 0.5) if is_on else Color.WHITE

func _on_volume_changed(value: float) -> void:
	_player.set_volume(value / 100.0)

func _update_now_playing() -> void:
	var track: Dictionary = _player.get_current_track()
	if track.is_empty():
		_track_label.text = Localization.t("phonograph.no_track")
		return
	_track_label.text = track.get("title_" + Localization.get_language(), track.get("title_en", "???"))

func _on_close() -> void:
	if _player and _player.is_playing():
		var track: Dictionary = _player.get_current_track()
		if not track.is_empty():
			GameManager._last_phonograph_track = track
			GameManager._last_phonograph_side = _current_side
	get_tree().change_scene_to_file("res://scenes/game_map.tscn")

func _process(_delta: float) -> void:
	if _player.is_playing() and _player.get_current_track().has("duration_seconds"):
		var pos: float = _player.get_playback_position()
		var dur: float = _player.get_current_track().get("duration_seconds", 1.0)
		_progress.value = (pos / dur) * 100.0
