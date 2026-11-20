extends Node
## Autoload: one-shot SFX by id with silent degradation.
##
## - The table below is the single place to swap a sound file: replacing a
##   wav is a one-line edit, no call sites change.
## - All loads go through ResourceLoader: imported resources survive the
##   export remap, raw FileAccess on source files dies in exported builds.
## - A missing or broken sfx degrades to silence, never a crash: failed
##   loads are remembered so they do not retry on every call.
## - Rapid repeats of one id are throttled: combat resolves many duels in
##   a single frame and the UI can spam clicks - one audible shot instead
##   of a wall of noise.

const MIN_REPEAT_INTERVAL_SEC: float = 0.06

var _sfx_table: Dictionary = {
	"button_click": "res://assets/audio/sfx/button_click.wav",
	"card_draw": "res://assets/audio/sfx/card_draw.wav",
	"card_play": "res://assets/audio/sfx/card_play.wav",
	"battle_start": "res://assets/audio/sfx/battle_start.wav",
	"battle_hit": "res://assets/audio/sfx/battle_hit.wav",
	"battle_destroy": "res://assets/audio/sfx/battle_destroy.wav",
	"march": "res://assets/audio/sfx/march.wav",
	"morale_up": "res://assets/audio/sfx/morale_up.wav",
	"morale_down": "res://assets/audio/sfx/morale_down.wav",
	"victory": "res://assets/audio/sfx/victory.wav",
	"defeat": "res://assets/audio/sfx/defeat.wav",
	"phonograph_needle": "res://assets/audio/sfx/phonograph_needle.wav",
}

var _streams: Dictionary = {}
var _last_played_at: Dictionary = {}
var _master_db: float = 0.0

func play(id: String, volume_db: float = 0.0) -> bool:
	if not _sfx_table.has(id):
		Logger.warn("AudioManager", "Unknown sfx id: %s" % id)
		return false
	var now_sec: float = Time.get_ticks_msec() / 1000.0
	if _last_played_at.has(id) and now_sec - float(_last_played_at[id]) < MIN_REPEAT_INTERVAL_SEC:
		return false
	var stream: AudioStream = _get_stream(id)
	if stream == null:
		return false
	# Only audible plays consume the throttle window: a failed play makes
	# no sound and must not suppress the next real attempt.
	_last_played_at[id] = now_sec
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = clampf(volume_db + _master_db, -80.0, 6.0)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
	return true

func has_sfx(id: String) -> bool:
	return _sfx_table.has(id)

func get_sfx_ids() -> Array:
	return _sfx_table.keys()

func get_sfx_path(id: String) -> String:
	return _sfx_table.get(id, "")

func set_master_volume_db(value: float) -> void:
	_master_db = value

func get_master_volume_db() -> float:
	return _master_db

## Connect every BaseButton under `root` (recursively) to the click sound.
## Call once per screen after the buttons exist; safe to call again - the
## connection is checked before adding.
func attach_button_sounds(root: Node) -> void:
	if root == null:
		return
	if root is BaseButton and not root.pressed.is_connected(_on_button_pressed):
		root.pressed.connect(_on_button_pressed)
	for child in root.get_children():
		attach_button_sounds(child)

## Test hook: remap an id to exercise the failure path with a bogus path.
func override_sfx_path_for_tests(id: String, path: String) -> void:
	_sfx_table[id] = path
	_streams.erase(id)

## Test hook: other suites may legitimately play the same sfx in the same
## frame - drop the throttle history so this suite is independent.
func reset_throttle_for_tests() -> void:
	_last_played_at.clear()

func _get_stream(id: String) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	var path: String = _sfx_table[id]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			stream = res
	if stream == null:
		Logger.warn("AudioManager", "SFX unavailable, degrading to silence: %s" % path)
	# Remember failures too - do not hammer the loader on every call.
	_streams[id] = stream
	return stream

func _on_button_pressed() -> void:
	play("button_click")
