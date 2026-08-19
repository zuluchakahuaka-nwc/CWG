extends Node
class_name PhonographPlayer

var _audio_player: AudioStreamPlayer
var _current_track: Dictionary = {}
var _is_playing: bool = false
var _is_paused: bool = false
var _is_shuffled: bool = false
var _is_repeating: bool = false
var _volume: float = 0.75
var _playlist: Array = []
var _playlist_index: int = 0
var _category: String = ""
var _active_side: String = "union"
var _needle_player: AudioStreamPlayer = null
var _track_finished_checked: bool = false

signal track_changed(track: Dictionary)
signal playback_state_changed(is_playing: bool)
signal side_changed(side: String)

func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	_audio_player.volume_db = _linear_to_db(_volume)
	_audio_player.finished.connect(_on_track_finished)
	_needle_player = AudioStreamPlayer.new()
	add_child(_needle_player)
	_needle_player.volume_db = _linear_to_db(_volume * 0.3)

func _process(_delta: float) -> void:
	if _is_playing and not _is_paused and not _audio_player.playing and not _audio_player.stream_paused:
		if not _track_finished_checked:
			_track_finished_checked = true
			_on_track_finished()
	elif _audio_player.playing:
		_track_finished_checked = false

func play_track(track_data: Dictionary) -> void:
	_current_track = track_data
	var file_path: String = track_data.get("file", "")
	if file_path == "":
		Logger.warn("PhonographPlayer", "No file path for track: " + str(track_data.get("id", "?")))
		return
	var stream: AudioStream = _load_audio(file_path)
	if stream == null:
		Logger.warn("PhonographPlayer", "Cannot load audio: " + file_path)
		return
	_play_needle_sound()
	_audio_player.stream = stream
	_audio_player.play()
	_is_playing = true
	_is_paused = false
	_track_finished_checked = false
	playback_state_changed.emit(true)
	track_changed.emit(track_data)
	Logger.info("PhonographPlayer", "Now playing: %s (playlist pos %d/%d)" % [track_data.get("id", "?"), _playlist_index, _playlist.size()])

func _load_audio(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			if res is AudioStreamMP3:
				res.loop = false
			return res
	var abs_path: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var data: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	var mp3: AudioStreamMP3 = AudioStreamMP3.new()
	mp3.data = data
	mp3.loop = false
	return mp3

func stop() -> void:
	_audio_player.stop()
	_is_playing = false
	_is_paused = false
	_track_finished_checked = false
	playback_state_changed.emit(false)

func pause() -> void:
	_audio_player.stream_paused = true
	_is_playing = false
	_is_paused = true
	playback_state_changed.emit(false)

func resume() -> void:
	_audio_player.stream_paused = false
	_is_playing = true
	_is_paused = false
	_track_finished_checked = false
	playback_state_changed.emit(true)

func set_volume(value: float) -> void:
	_volume = clampf(value, 0.0, 1.0)
	_audio_player.volume_db = _linear_to_db(_volume)
	if _needle_player:
		_needle_player.volume_db = _linear_to_db(_volume * 0.3)

func get_volume() -> float:
	return _volume

func is_playing() -> bool:
	return _is_playing

func set_side(side: String) -> void:
	_active_side = side
	var style: String = GameManager.get_music_style(side)
	set_category(style)
	side_changed.emit(side)

func get_active_side() -> String:
	return _active_side

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

func play_for_side(side: String) -> void:
	set_side(side)
	if not _playlist.is_empty():
		play_track(_playlist[0])

func next_track() -> void:
	if _playlist.is_empty():
		Logger.warn("PhonographPlayer", "next_track: playlist empty")
		return
	_playlist_index += 1
	if _playlist_index >= _playlist.size():
		if _is_repeating:
			_playlist_index = 0
		else:
			Logger.info("PhonographPlayer", "Reached end of playlist, stopping")
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

func is_phonograph_mode() -> bool:
	return _category == "valces"

func is_orchestra_mode() -> bool:
	return _category == "folk"

func get_mode_description_en() -> String:
	if is_phonograph_mode():
		return "Phonograph Records — soldiers gather around the gramophone in camp"
	else:
		return "Orchestra — the grand band plays for the troops"

func get_mode_description_ru() -> String:
	if is_phonograph_mode():
		return "Пластинки патефона — солдаты собираются у граммофона в лагере"
	else:
		return "Оркестр — духовой оркестр играет для войск"

func _on_track_finished() -> void:
	Logger.info("PhonographPlayer", "Track finished. repeat=%s playlist=%d index=%d" % [_is_repeating, _playlist.size(), _playlist_index])
	if _is_repeating:
		_audio_player.play()
	else:
		next_track()

func _play_needle_sound() -> void:
	if _category == "valces":
		var path: String = "res://assets/audio/sfx/phonograph_needle.wav"
		if not FileAccess.file_exists(path):
			return
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			return
		var buf: PackedByteArray = f.get_buffer(f.get_length())
		f.close()
		var stream: AudioStreamWAV = AudioStreamWAV.new()
		stream.data = buf
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 44100
		stream.stereo = false
		if _needle_player:
			_needle_player.stream = stream
			_needle_player.play()

func _linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return log(value) * 8.685889638065037
