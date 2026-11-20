extends Node
## Suite: one-language-per-screen law (hub AGENTS.md).
## 1) Scene files must not carry placeholder texts that survive runtime:
##    every text node is either empty, or runtime-localized (whitelisted
##    with a justification), otherwise FAIL.
## 2) Scripts must not assign literal strings to .text (Localization.t
##    wrappers are fine); whitelisted exceptions documented below.

var _pass_count: int = 0
var _fail_count: int = 0
var _test_results: Array = []

## Node paths whose .tscn placeholders are provably overwritten by
## _localize/_update_ui/_show_* before the first visible frame.
const SCENE_WHITELIST: Dictionary = {
	"res://scenes/game_map.tscn": [
		"TopBar/HBox/TurnInfo", "TopBar/HBox/PhaseLabel", "TopBar/HBox/SideLabel",
		"TopBar/HBox/EditMapButton", "TopBar/HBox/SaveMapButton",
		"TopBar/HBox/SettingsButton", "TopBar/HBox/PhonographButton",
		"TopBar/HBox/MenuButton", "StatusBar/ManpowerLabel", "StatusBar/MoneyLabel",
		"StatusBar/SupplyLabel", "StatusBar/MoraleLabel", "StatusBar/MoraleStatus",
		"StatusBar/EndTurnButton", "StatusBar/AutoTurnButton",
		"CardDetailPopup/DetailVBox/DetailName", "CardDetailPopup/DetailVBox/DetailStats",
		"CardDetailPopup/DetailVBox/DetailClose", "TerritoryInfoPanel/TVBox/TName",
		"TerritoryInfoPanel/TVBox/TOwner", "TerritoryInfoPanel/TVBox/TTerrain",
		"TerritoryInfoPanel/TVBox/TUnitsLabel", "TerritoryInfoPanel/TVBox/TClose",
	],
	"res://scenes/main_menu.tscn": [
		"VBoxContainer/TitleLabel", "VBoxContainer/SubtitleLabel",
		"VBoxContainer/NewGameButton", "VBoxContainer/ContinueButton",
		"VBoxContainer/SettingsButton", "VBoxContainer/LanguageButton",
		"VBoxContainer/QuitButton", "VersionLabel",
	],
	"res://scenes/phonograph.tscn": [
		"Panel/VBox/TitleLabel", "Panel/VBox/ModeLabel", "Panel/VBox/NowPlayingLabel",
		"Panel/VBox/Controls/PrevBtn", "Panel/VBox/Controls/PlayBtn",
		"Panel/VBox/Controls/StopBtn", "Panel/VBox/Controls/NextBtn",
		"Panel/VBox/Controls/ShuffleBtn", "Panel/VBox/Controls/RepeatBtn",
		"Panel/VBox/VolumeLabel", "Panel/VBox/CloseButton",
		"Panel/VBox/SideTabs/UnionBtn", "Panel/VBox/SideTabs/ConfedBtn",
	],
	"res://scenes/scenario_select.tscn": [
		"TitleLabel", "SideLabel", "SideHBox/UnionButton", "SideHBox/ConfederateButton",
		"BackButton", "ScrollContainer/VBoxContainer/Scenario1861",
		"ScrollContainer/VBoxContainer/Scenario1862",
		"ScrollContainer/VBoxContainer/Scenario1863",
		"ScrollContainer/VBoxContainer/Scenario1864",
		"ScrollContainer/VBoxContainer/Scenario1865",
		"ScrollContainer/VBoxContainer/ScenarioFull",
	],
	"res://scenes/settings.tscn": [
		"MarginContainer/VBox/TitleLabel", "MarginContainer/VBox/LangSection/LangLabel",
		"MarginContainer/VBox/AudioSection/AudioLabel",
		"MarginContainer/VBox/AudioSection/VolumeRow/VolumeLabel",
		"MarginContainer/VBox/MusicSection/MusicLabel",
		"MarginContainer/VBox/MusicSection/UnionMusicRow/UnionMusicLabel",
		"MarginContainer/VBox/MusicSection/ConfedMusicRow/ConfedMusicLabel",
		"MarginContainer/VBox/DisplaySection/FullscreenCheck",
		"MarginContainer/VBox/ButtonRow/BackButton",
	],
	# Dead skeleton scene (audit P2 rewrite queue) - not reachable in game.
	"res://scenes/battle_screen.tscn": ["*"],
}

## Literal snippets allowed in script .text assignments.
## - battle_screen "Resolve": dead skeleton scene (P2).
## - "HAND: 0 cards": initializer, overwritten by _update_ui same frame.
## - "HP:%d/%d  A:%d D:%d": universal stat abbreviations (same convention
##   as ui.card_stats which keeps ATK/DEF/HP in every locale).
const SCRIPT_WHITELIST: Dictionary = {
	"res://scenes/battle_screen.gd": ["Resolve"],
	"res://scenes/game_map.gd": ["HAND: 0 cards", "HP:%d/%d"],
}

const LAW_KEYS: PackedStringArray = [
	"game.settings", "phonograph.title", "ui.menu", "ui.edit_map",
	"ui.save_map", "ui.done", "ui.close", "ui.card_stats",
	"ui.info.battle_line", "ui.info.battle_captured", "scenario.select.title",
]

func _ready() -> void:
	print("\n=== TEST: OneLanguagePerScreen law ===")
	test_scene_texts_covered()
	test_script_text_literals_covered()
	test_law_keys_exist_in_ru_and_en()
	test_all_code_keys_resolve()
	_print_summary()

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		_test_results.append("  PASS: " + test_name)
	else:
		_fail_count += 1
		_test_results.append("  FAIL: " + test_name)

func test_scene_texts_covered() -> void:
	var node_re := RegEx.new()
	node_re.compile("^\\[node name=\"([^\"]+)\"(?:[^\\]]*parent=\"([^\"]+)\")?")
	var text_re := RegEx.new()
	text_re.compile("^text = \"(.*)\"$")
	var violations: Array = []
	for scene_path in SCENE_WHITELIST.keys():
		if not FileAccess.file_exists(scene_path):
			_assert(false, "whitelisted scene exists: %s" % scene_path)
			continue
		var allowed: Array = SCENE_WHITELIST[scene_path]
		if allowed.has("*"):
			continue
		var f := FileAccess.open(scene_path, FileAccess.READ)
		var current := ""
		while not f.eof_reached():
			var line := f.get_line()
			var nm := node_re.search(line)
			if nm:
				var parent := nm.get_string(2)
				current = parent + "/" + nm.get_string(1) if parent != "" and parent != "." else nm.get_string(1)
				continue
			var tm := text_re.search(line)
			if tm and tm.get_string(1) != "" and _has_letters(tm.get_string(1)):
				if not allowed.has(current):
					violations.append("%s :: %s :: %s" % [scene_path, current, tm.get_string(1)])
		f.close()
	_assert(violations.is_empty(), "every scene text node is empty or runtime-covered %s" % str(violations).left(300))

func test_script_text_literals_covered() -> void:
	var assign_re := RegEx.new()
	assign_re.compile("\\.text\\s*=\\s*\"([^\"]*)\"")
	var violations: Array = []
	for path in _collect_gd_files("res://scenes") + _collect_gd_files("res://scripts"):
		var allowed: Array = SCRIPT_WHITELIST.get(path, [])
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		while not f.eof_reached():
			var line := f.get_line()
			if line.contains("Localization.t("):
				continue
			var m := assign_re.search(line)
			if m and _has_letters(m.get_string(1)):
				var snippet := m.get_string(1)
				var ok := false
				for wl in allowed:
					if snippet.contains(wl) or wl.contains(snippet):
						ok = true
						break
				if not ok:
					violations.append("%s :: %s" % [path, snippet])
		f.close()
	_assert(violations.is_empty(), "no literal .text assignments outside whitelist %s" % str(violations).left(300))

func test_law_keys_exist_in_ru_and_en() -> void:
	var saved := Localization.get_language()
	Localization.set_language("ru")
	for key in LAW_KEYS:
		var ru_val: String = Localization.t(key)
		_assert(ru_val != key, "key '%s' resolves in ru" % key)
	Localization.set_language("en")
	for key in LAW_KEYS:
		var en_val: String = Localization.t(key)
		_assert(en_val != key, "key '%s' resolves in en" % key)
	Localization.set_language(saved)

func test_all_code_keys_resolve() -> void:
	# A raw key leaking into the UI (e.g. "month.april") is a language-mix
	# bug: every Localization.t("<literal>") used in code must exist in the
	# CSV. Dynamic keys (concatenation) are checked by their base presence
	# in LAW_KEYS-style tests or caught by the E2E vision pass.
	var key_re := RegEx.new()
	key_re.compile("Localization\\.t\\(\"([^\"]+)\"\\)")
	var missing: Array = []
	var saved := Localization.get_language()
	Localization.set_language("en")
	for path in _collect_gd_files("res://scenes") + _collect_gd_files("res://scripts"):
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var source := f.get_as_text()
		f.close()
		for m in key_re.search_all(source):
			var key := m.get_string(1)
			if not Localization.has_key(key):
				missing.append("%s :: %s" % [path, key])
	Localization.set_language(saved)
	_assert(missing.is_empty(), "every literal key used in code resolves %s" % str(missing).left(300))

func _has_letters(s: String) -> bool:
	# printf-style specifiers (%d %s %0.2f) are format, not language
	var spec := RegEx.new()
	spec.compile("%[-+ #0-9.]*[a-zA-Z]")
	var stripped := spec.sub(s, "", true)
	for c in stripped.to_lower():
		if (c >= "a" and c <= "z") or (c >= "а" and c <= "я") or c == "ё":
			return true
	return false

func _collect_gd_files(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir() and not name.begins_with("."):
			out += _collect_gd_files(dir_path + "/" + name)
		elif name.ends_with(".gd"):
			out.append(dir_path + "/" + name)
		name = dir.get_next()
	dir.list_dir_end()
	return out

func _print_summary() -> void:
	for r in _test_results:
		print(r)
	var total: int = _pass_count + _fail_count
	print("\n  TOTAL: %d/%d passed, %d failed" % [_pass_count, total, _fail_count])
	if _fail_count == 0:
		print("  ALL TESTS PASSED!")
	else:
		print("  SOME TESTS FAILED!")
	print("===========================\n")
