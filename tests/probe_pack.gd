extends SceneTree
## Export PCK probe: mounts an exported pack and verifies that audio,
## script and texture resources survive the export remap.
##
## Run from a scratch empty project:
##   godot --headless --path <scratch> --script res://probe_pack.gd -- <pck> <report.json>
## Writes a JSON report (no stdout dependency - GUI-subsystem binaries).

const CHECK_PATHS: PackedStringArray = [
	"res://assets/audio/sfx/button_click.wav",
	"res://assets/audio/sfx/card_draw.wav",
	"res://assets/audio/sfx/card_play.wav",
	"res://assets/audio/sfx/battle_start.wav",
	"res://assets/audio/sfx/battle_hit.wav",
	"res://assets/audio/sfx/battle_destroy.wav",
	"res://assets/audio/sfx/march.wav",
	"res://assets/audio/sfx/morale_up.wav",
	"res://assets/audio/sfx/morale_down.wav",
	"res://assets/audio/sfx/victory.wav",
	"res://assets/audio/sfx/defeat.wav",
	"res://assets/audio/sfx/phonograph_needle.wav",
	"res://scenes/game_map.gd",
	"res://scripts/core/audio_manager.gd",
	"res://data/music/tracks.json",
]

func _initialize() -> void:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if user_args.size() < 2:
		_write_report("res://probe_report.json", {"error": "usage: -- <pck> <report>"})
		quit(1)
		return
	var pck_path: String = user_args[0]
	var report_path: String = user_args[1]
	var report: Dictionary = {"pck": pck_path}
	if not FileAccess.file_exists(pck_path):
		report["error"] = "pck file not found"
		_write_report(report_path, report)
		quit(1)
		return
	var ok: bool = ProjectSettings.load_resource_pack(pck_path, false)
	report["mounted"] = ok
	var results: Array = []
	var failures: int = 0
	for path in CHECK_PATHS:
		var entry: Dictionary = {"path": path}
		entry["exists"] = ResourceLoader.exists(path)
		if entry["exists"]:
			var res = load(path)
			entry["loaded"] = res != null
			entry["type"] = typeof(res) if res == null else res.get_class()
			if res == null:
				failures += 1
		else:
			entry["loaded"] = false
			failures += 1
		results.append(entry)
	report["checks"] = results
	report["failures"] = failures
	_write_report(report_path, report)
	quit(1 if failures > 0 else 0)

func _write_report(path: String, data: Dictionary) -> void:
	var abs: String = path if path.is_absolute_path() else ProjectSettings.globalize_path(path)
	var f: FileAccess = FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
