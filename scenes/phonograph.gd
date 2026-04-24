extends Control

var _player: PhonographPlayer = null

@onready var _title: Label = $Panel/VBox/TitleLabel
@onready var _now_playing: Label = $Panel/VBox/NowPlayingLabel
@onready var _track_label: Label = $Panel/VBox/TrackLabel
@onready var _progress: ProgressBar = $Panel/VBox/Progressbar
@onready var _track_list: ItemList = $Panel/VBox/TrackList
@onready var _volume_slider: HSlider = $Panel/VBox/VolumeSlider
@onready var _close_btn: Button = $Panel/VBox/CloseButton
@onready var _play_btn: Button = $Panel/VBox/Controls/PlayBtn
@onready var _prev_btn: Button = $Panel/VBox/Controls/PrevBtn
@onready var _next_btn: Button = $Panel/VBox/Controls/NextBtn
@onready var _shuffle_btn: Button = $Panel/VBox/Controls/ShuffleBtn
@onready var _repeat_btn: Button = $Panel/VBox/Controls/RepeatBtn

func _ready() -> void:
	_player = PhonographPlayer.new()
	add_child(_player)
	_localize()
	_close_btn.pressed.connect(_on_close)
	_play_btn.pressed.connect(_on_play)
	_prev_btn.pressed.connect(_on_prev)
	_next_btn.pressed.connect(_on_next)
	_shuffle_btn.pressed.connect(_on_shuffle)
	_repeat_btn.pressed.connect(_on_repeat)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_track_list.item_selected.connect(_on_track_selected)
	var cat_btns: Array = [
		$Panel/VBox/CategoryTabs/MarchesBtn,
		$Panel/VBox/CategoryTabs/BalladsBtn,
		$Panel/VBox/CategoryTabs/HymnsBtn,
		$Panel/VBox/CategoryTabs/FifeBtn,
		$Panel/VBox/CategoryTabs/OrchestralBtn
	]
	var categories: Array = ["marches", "ballads", "hymns", "fife_and_drum", "orchestral"]
	for i in range(cat_btns.size()):
		cat_btns[i].pressed.connect(_on_category.bind(categories[i]))
	_load_category("marches")

func _localize() -> void:
	_title.text = Localization.t("phonograph.title")
	_now_playing.text = Localization.t("phonograph.now_playing")
	_close_btn.text = Localization.t("phonograph.close")
	$Panel/VBox/CategoryTabs/MarchesBtn.text = Localization.t("phonograph.category.marches")
	$Panel/VBox/CategoryTabs/BalladsBtn.text = Localization.t("phonograph.category.ballads")
	$Panel/VBox/CategoryTabs/HymnsBtn.text = Localization.t("phonograph.category.hymns")
	$Panel/VBox/CategoryTabs/FifeBtn.text = Localization.t("phonograph.category.fife_and_drum")
	$Panel/VBox/CategoryTabs/OrchestralBtn.text = Localization.t("phonograph.category.orchestral")

func _load_category(category: String) -> void:
	_track_list.clear()
	var tracks: Array = CardDatabase.get_music_tracks(category)
	for track in tracks:
		var title: String = track.get("title_" + Localization.get_language(), track.get("title_en", "???"))
		_track_list.add_item(title)
	_player.set_category(category)

func _on_category(cat: String) -> void:
	_load_category(cat)

func _on_track_selected(index: int) -> void:
	var tracks: Array = _player.get_playlist()
	if index >= 0 and index < tracks.size():
		_player.play_track(tracks[index])
		_update_now_playing()

func _on_play() -> void:
	if _player._is_playing:
		_player.pause()
		_play_btn.text = "Play"
	else:
		if _player.get_current_track().is_empty():
			var tracks: Array = _player.get_playlist()
			if not tracks.is_empty():
				_player.play_track(tracks[0])
		else:
			_player.resume()
		_play_btn.text = "Pause"
	_update_now_playing()

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
		_track_label.text = "---"
		return
	_track_label.text = track.get("title_" + Localization.get_language(), track.get("title_en", "???"))

func _on_close() -> void:
	get_tree().change_scene_to_file("res://scenes/game_map.tscn")

func _process(_delta: float) -> void:
	if _player._is_playing and _player.get_current_track().has("duration_seconds"):
		var pos: float = _player.get_playback_position()
		var dur: float = _player.get_current_track().get("duration_seconds", 1.0)
		_progress.value = (pos / dur) * 100.0
