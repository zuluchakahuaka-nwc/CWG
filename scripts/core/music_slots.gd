extends Node
## Music slot manifest - the single source of truth for what plays where
## (hub law "music slots"). Code addresses slots by id only; swapping a
## melody is a one-line edit in data/music/music_slots.json. A missing
## manifest, slot or audio file degrades to silence, never a crash.
##
## Track files themselves are declared by the catalog (data/music/
## tracks.json); slots bind roles to catalog categories. Status/license
## fields feed MUSIC-LICENSES.md and the CI artifact policy.

const MANIFEST_PATH: String = "res://data/music/music_slots.json"

var _slots: Dictionary = {}
var _audio_probe_cache: Dictionary = {}

func _ready() -> void:
	_load_manifest()

func has_slot(id: String) -> bool:
	return _slots.has(id)

func get_slot(id: String) -> Dictionary:
	return _slots.get(id, {})

func slot_ids() -> Array:
	return _slots.keys()

func side_slot(side: String) -> String:
	return "game_confederate" if side == "confederate" else "game_union"

func slot_side(slot_id: String) -> String:
	match slot_id:
		"game_union": return "union"
		"game_confederate": return "confederate"
		_: return ""

## The category a slot resolves to right now. Per-side slots honor the
## player's style override from the Settings screen (persisted by
## GameManager) over the manifest binding.
func effective_category(slot_id: String) -> String:
	var side: String = slot_side(slot_id)
	if side != "":
		return GameManager.get_music_style(side)
	return str(get_slot(slot_id).get("category", ""))

func playlist_for(slot_id: String) -> Array:
	var category: String = effective_category(slot_id)
	if category == "":
		return []
	return CardDatabase.get_music_tracks(category)

## True when at least one track of the slot actually loads. Uses a real
## load attempt, not ResourceLoader.exists(): exists() lies for committed
## sidecars whose sources never made it into the build (music is excluded
## from CI artifacts by the licensing law).
func has_audio(slot_id: String) -> bool:
	if _audio_probe_cache.has(slot_id):
		return bool(_audio_probe_cache[slot_id])
	var verdict: bool = false
	for track in playlist_for(slot_id):
		var path: String = str(track.get("file", ""))
		if path == "":
			continue
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream is AudioStream:
				verdict = true
				break
	_audio_probe_cache[slot_id] = verdict
	return verdict

func clear_audio_probe_cache() -> void:
	_audio_probe_cache.clear()

func _load_manifest() -> void:
	_slots.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		Logger.warn("MusicSlots", "No music manifest at %s - all slots silent" % MANIFEST_PATH)
		return
	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		Logger.warn("MusicSlots", "Cannot open music manifest - all slots silent")
		return
	var json: JSON = JSON.new()
	var parsed: int = json.parse(file.get_as_text())
	file.close()
	if parsed != OK or not (json.get_data() is Dictionary):
		Logger.warn("MusicSlots", "Broken music manifest - all slots silent")
		return
	for slot in json.get_data().get("slots", []):
		var id: String = str(slot.get("id", ""))
		if id != "":
			_slots[id] = slot
	Logger.info("MusicSlots", "Loaded %d music slots" % _slots.size())
