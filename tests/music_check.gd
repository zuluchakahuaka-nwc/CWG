extends SceneTree
## Standalone music manifest validator for CI (no autoload dependencies).
## Exit 0 = manifest and catalog are consistent; exit 1 = violations.
## Placeholder tracks may be absent on disk (builds ship without music by
## the licensing law) - those are warnings, not failures. Tracks under a
## final-status slot MUST exist and carry source+license.

func _initialize() -> void:
	var errors: int = 0
	var warnings: int = 0

	var manifest: Dictionary = _read_json("res://data/music/music_slots.json")
	if manifest.is_empty():
		print("MUSIC-CHECK FAIL: cannot read data/music/music_slots.json")
		quit(1)
		return

	var catalog: Array = _read_json_array("res://data/music/tracks.json")
	if catalog.is_empty():
		print("MUSIC-CHECK FAIL: cannot read data/music/tracks.json")
		quit(1)
		return

	var categories: Dictionary = {}
	for track in catalog:
		categories[str(track.get("category", ""))] = true

	var slots: Array = manifest.get("slots", [])
	if slots.is_empty():
		print("MUSIC-CHECK FAIL: manifest has no slots")
		quit(1)
		return

	for slot in slots:
		var id: String = str(slot.get("id", ""))
		var role: String = str(slot.get("role", ""))
		var category: String = str(slot.get("category", ""))
		var status: String = str(slot.get("status", ""))
		if id == "" or role == "" or category == "":
			print("MUSIC-CHECK FAIL: slot missing id/role/category: %s" % str(slot))
			errors += 1
			continue
		if not categories.has(category):
			print("MUSIC-CHECK FAIL: slot '%s' binds unknown category '%s'" % [id, category])
			errors += 1
		if not ["placeholder", "final"].has(status):
			print("MUSIC-CHECK FAIL: slot '%s' has invalid status '%s'" % [id, status])
			errors += 1
		if status == "final":
			if str(slot.get("source", "")) == "" or str(slot.get("license", "")) == "":
				print("MUSIC-CHECK FAIL: final slot '%s' lacks source/license" % id)
				errors += 1
			for track in catalog:
				if str(track.get("category", "")) != category:
					continue
				var file: String = str(track.get("file", ""))
				if file == "" or not FileAccess.file_exists(file):
					print("MUSIC-CHECK FAIL: final slot '%s' track '%s' file missing: %s" % [id, str(track.get("id", "?")), file])
					errors += 1

	if warnings == 0 and errors == 0:
		print("MUSIC-CHECK PASS: %d slots, %d catalog tracks, all consistent" % [slots.size(), catalog.size()])
	quit(1 if errors > 0 else 0)

func _read_json(path: String) -> Dictionary:
	var arr: Array = _read_json_array(path)
	return arr[0] if arr.size() == 1 and arr[0] is Dictionary else {}

func _read_json_array(path: String) -> Array:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var json: JSON = JSON.new()
	var parsed: int = json.parse(file.get_as_text())
	file.close()
	if parsed != OK:
		return []
	var data: Variant = json.get_data()
	if data is Array:
		return data
	if data is Dictionary:
		return [data]
	return []
