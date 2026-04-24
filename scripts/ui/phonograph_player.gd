extends Node

var _audio_player: AudioStreamPlayer
var _current_track: Dictionary = {}
var _is_playing: bool = false
var _is_shuffled: bool = false
var _is_repeating: bool = false
var _volume: float = 0.75
var _playlist: Array = []
var _playlist_index: int = 0
var _category: String = "marches"

signal track_changed(track: Dictionary)
signal playback_state_changed(is_playing: bool)

func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	_audio_player.volume_db = _linear_to_db(_volume)
	_audio_player.finished.connect(_on_track_finished)

func play_track(track_data: Dictionary) -> void:
	_current_track = track_data
	var file_path: String = track_data.get("file", "")
	if file_path == "" or not ResourceLoader.exists(file_path):
		push_warning("PhonographPlayer: file not found: " + file_path)
		return
	var stream: AudioStream = load(file_path)
	if stream == null:
		return
	_audio_player.stream = stream
	_audio_player.play()
	_is_playing = true
	playback_state_changed.emit(true)
	track_changed.emit(track_data)

func stop() -> void:
	_audio_player.stop()
	_is_playing = false
	playback_state_changed.emit(false)

func pause() -> void:
	_audio_player.stream_paused = true
	_is_playing = false
	playback_state_changed.emit(false)

func resume() -> void:
	_audio_player.stream_paused = false
	_is_playing = true
	playback_state_changed.emit(true)

func set_volume(value: float) -> void:
	_volume = clampf(value, 0.0, 1.0)
	_audio_player.volume_db = _linear_to_db(_volume)

func get_volume() -> float:
	return _volume

func set_category(cat: String) -> void:
	_category = cat
	_playlist = CardDatabase.get_music_tracks(cat)
	_playlist_index = 0
	if _is_shuffled:
		_playlist.shuffle()

func play_category(cat: String) -> void:
	set_category(cat)
	if not _playlist.is_empty():
		play_track(_playlist[0])

func next_track() -> void:
	if _playlist.is_empty():
		return
	_playlist_index += 1
	if _playlist_index >= _playlist.size():
		if _is_repeating:
			_playlist_index = 0
		else:
			stop()
			return
	play_track(_playlist[_playlist_index])

func previous_track() -> void:
	if _playlist.is_empty():
		return
	_playlist_index = maxi(_playlist_index - 1, 0)
	play_track(_playlist[_playlist_index])

func toggle_shuffle() -> bool:
	_is_shuffled = not _is_shuffled
	if _is_shuffled:
		_playlist.shuffle()
	return _is_shuffled

func toggle_repeat() -> bool:
	_is_repeating = not _is_repeating
	return _is_repeating

func get_current_track() -> Dictionary:
	return _current_track

func get_current_category() -> String:
	return _category

func get_playlist() -> Array:
	return _playlist

func get_playback_position() -> float:
	if _audio_player and _audio_player.playing:
		return _audio_player.get_playback_position()
	return 0.0

func _on_track_finished() -> void:
	if _is_repeating:
		_audio_player.play()
	else:
		next_track()

func _linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return log(value) * 8.685889638065037
